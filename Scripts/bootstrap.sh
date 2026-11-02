#!/usr/bin/env bash
# Sets up a fresh clone: tools, secrets file, Xcode project, pods and git hooks.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

need() {
    if ! command -v "$1" >/dev/null 2>&1; then
        if ! command -v brew >/dev/null 2>&1; then
            echo "Homebrew is required to install $1. See https://brew.sh"
            exit 1
        fi
        echo "Installing $1"
        brew install "$2"
    fi
}

need xcodegen xcodegen
need pod cocoapods
need gitleaks gitleaks

if [ ! -f Configs/Secrets.xcconfig ]; then
    cp Configs/Secrets.example.xcconfig Configs/Secrets.xcconfig
    echo "Created Configs/Secrets.xcconfig. Paste your TMDB API Read Access Token into it."
fi

xcodegen generate --quiet
pod install

"$ROOT/Scripts/install-hooks.sh"

if ! grep -Eq '^TMDB_ACCESS_TOKEN *= *[^ ]+' Configs/Secrets.xcconfig; then
    echo ""
    echo "Heads up: TMDB_ACCESS_TOKEN is still empty. The app will build but show a setup screen."
fi

echo ""
echo "Done. Open MovieDB.xcworkspace (not the .xcodeproj)."
