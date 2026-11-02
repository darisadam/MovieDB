#!/usr/bin/env bash
# Builds and tests on the first available iPhone simulator. Used by CI, works locally too.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEVICE_ID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for runtime, items in sorted(devices.items(), reverse=True):
    if "iOS" not in runtime:
        continue
    for device in items:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
')

if [ -z "$DEVICE_ID" ]; then
    echo "No iPhone simulator found."
    exit 1
fi

echo "Testing on simulator $DEVICE_ID"
set -o pipefail
xcodebuild test \
    -workspace MovieDB.xcworkspace \
    -scheme MovieDB \
    -destination "id=$DEVICE_ID" \
    -derivedDataPath build/DerivedData \
    | if command -v xcbeautify >/dev/null 2>&1; then xcbeautify; else cat; fi
