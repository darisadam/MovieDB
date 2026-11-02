#!/usr/bin/env bash
# Blocks commits that would leak a token. Used by the pre-commit hook and CI.
# Pass --all to scan the whole working tree instead of the staged changes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0

# The real secrets file must never be tracked.
if git ls-files --error-unmatch Configs/Secrets.xcconfig >/dev/null 2>&1; then
  echo "error: Configs/Secrets.xcconfig is tracked by git. Run: git rm --cached Configs/Secrets.xcconfig"
  fail=1
fi

if [ "${1:-}" = "--all" ]; then
  files=$(git ls-files)
else
  files=$(git diff --cached --name-only --diff-filter=ACM)
fi

# TMDB v3 keys are 32 hex chars, v4 tokens are JWTs that start with eyJ.
patterns='(api_key=[0-9a-f]{32})|(["'"'"'][0-9a-f]{32}["'"'"'])|(eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.)|(TMDB_ACCESS_TOKEN *= *[^ ]{20,})'

for f in $files; do
  [ -f "$f" ] || continue
  case "$f" in
    *.png|*.jpg|*.jpeg|*.pdf|*.ttf|*.otf) continue ;;
  esac
  if grep -nEI "$patterns" "$f" >/dev/null 2>&1; then
    echo "error: possible secret in $f"
    grep -nEI "$patterns" "$f" | sed -E 's/(eyJ[A-Za-z0-9_-]{6})[A-Za-z0-9._-]+/\1<redacted>/g; s/([0-9a-f]{6})[0-9a-f]{26}/\1<redacted>/g'
    fail=1
  fi
done

if command -v gitleaks >/dev/null 2>&1; then
  if [ "${1:-}" = "--all" ]; then
    gitleaks detect --no-banner --redact --config .gitleaks.toml || fail=1
  else
    gitleaks protect --staged --no-banner --redact --config .gitleaks.toml || fail=1
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo "Secret check failed. Move tokens to Configs/Secrets.xcconfig."
  exit 1
fi
echo "Secret check passed."
