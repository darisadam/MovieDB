#!/usr/bin/env bash
# Formats every Objective-C file with .clang-format (2 space indent).
# Pass --check to only report files that need formatting, which is what CI does.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v clang-format >/dev/null 2>&1; then
  echo "clang-format is missing. Install it with: brew install clang-format"
  exit 1
fi

files=$(git ls-files 'MovieDB/*.h' 'MovieDB/*.m' 'MovieDBTests/*.h' 'MovieDBTests/*.m')

if [ "${1:-}" = "--check" ]; then
  # shellcheck disable=SC2086
  clang-format --dry-run --Werror $files
  echo "Formatting looks good."
else
  # shellcheck disable=SC2086
  clang-format -i $files
  echo "Formatted $(echo "$files" | wc -l | tr -d ' ') files."
fi
