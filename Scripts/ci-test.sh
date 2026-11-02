#!/usr/bin/env bash
# Builds and tests on iPhone simulators. Used by CI, works locally too.
#   ./Scripts/ci-test.sh         newest iOS runtime only
#   ./Scripts/ci-test.sh --all   one iPhone for every installed iOS runtime
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODE="${1:-newest}"

DEVICES=$(xcrun simctl list devices available -j | MODE="$MODE" python3 -c '
import json, os, sys
devices = json.load(sys.stdin)["devices"]
picked = []
for runtime, items in sorted(devices.items(), reverse=True):
  if ".iOS-" not in runtime:
    continue
  for device in items:
    if device["name"].startswith("iPhone"):
      picked.append(device["udid"] + " " + runtime.split(".")[-1])
      break
if os.environ["MODE"] != "--all":
  picked = picked[:1]
print("\n".join(picked))
')

if [ -z "$DEVICES" ]; then
  echo "No iPhone simulator found."
  exit 1
fi

while read -r DEVICE_ID RUNTIME; do
  echo "Testing on $RUNTIME ($DEVICE_ID)"
  xcodebuild test \
    -workspace MovieDB.xcworkspace \
    -scheme MovieDB \
    -destination "id=$DEVICE_ID" \
    -derivedDataPath build/DerivedData \
    -enableCodeCoverage YES \
    | if command -v xcbeautify >/dev/null 2>&1; then xcbeautify --quieter; else cat; fi
done <<< "$DEVICES"
