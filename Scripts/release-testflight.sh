#!/usr/bin/env bash
# Archives a Release build and uploads it to App Store Connect for TestFlight.
# Signing and the upload use the Apple ID signed in to Xcode (Settings > Accounts).
#
#   ./Scripts/release-testflight.sh          bump the build number, archive, upload
#   ./Scripts/release-testflight.sh --no-upload   archive and export only
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! grep -Eq '^TMDB_ACCESS_TOKEN *= *[^ ]{20,}' Configs/Secrets.xcconfig 2>/dev/null; then
  echo "TMDB_ACCESS_TOKEN is empty in Configs/Secrets.xcconfig. A TestFlight build without it only shows the setup screen."
  exit 1
fi

# Every upload needs a new build number. Bump it in project.yml so it stays in git.
current=$(sed -nE 's/^ *CURRENT_PROJECT_VERSION: "?([0-9]+)"?/\1/p' project.yml | head -1)
next=$((current + 1))
sed -i '' -E "s/^( *CURRENT_PROJECT_VERSION: )\"?[0-9]+\"?/\1\"$next\"/" project.yml
echo "Build number $current -> $next"

xcodegen generate --quiet
pod install --silent

ARCHIVE="build/Archives/MovieDB-$next.xcarchive"
EXPORT="build/Export-$next"

xcodebuild archive \
  -workspace MovieDB.xcworkspace \
  -scheme MovieDB \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  | if command -v xcbeautify >/dev/null 2>&1; then xcbeautify --quieter; else cat; fi

OPTIONS="Scripts/ExportOptions.plist"
if [ "${1:-}" = "--no-upload" ]; then
  OPTIONS="build/ExportOptions-local.plist"
  sed 's#<string>upload</string>#<string>export</string>#' Scripts/ExportOptions.plist > "$OPTIONS"
fi

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$OPTIONS" \
  -exportPath "$EXPORT" \
  -allowProvisioningUpdates \
  | if command -v xcbeautify >/dev/null 2>&1; then xcbeautify --quieter; else cat; fi

echo ""
echo "Done. Build $next is archived at $ARCHIVE."
if [ "${1:-}" != "--no-upload" ]; then
  echo "It is uploading to App Store Connect. Processing takes a few minutes before it shows up in TestFlight."
fi
