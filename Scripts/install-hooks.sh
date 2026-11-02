#!/usr/bin/env bash
# Installs a pre-commit hook that runs the secret check.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/.git/hooks/pre-commit"

if [ ! -d "$ROOT/.git" ]; then
    echo "Not a git checkout, skipping hooks."
    exit 0
fi

cat > "$HOOK" <<'EOF'
#!/usr/bin/env bash
exec "$(git rev-parse --show-toplevel)/Scripts/check-secrets.sh"
EOF
chmod +x "$HOOK"
echo "Installed pre-commit secret check."
