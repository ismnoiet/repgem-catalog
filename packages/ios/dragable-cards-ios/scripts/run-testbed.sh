#!/usr/bin/env bash
# Builds ios-testbed (which includes the DragableCards demos) for a simulator, installs and opens it.
# Expects ios-testbed next to this folder (ai/modules/ios-testbed) and `xcodegen` installed.
#   ./scripts/run-testbed.sh                  uses "iPhone 15"
#   ./scripts/run-testbed.sh "iPhone 15 Pro"
set -euo pipefail
TESTBED="$(cd "$(dirname "$0")/../../ios-testbed" && pwd)"
DEVICE="${1:-iPhone 15}"

command -v xcodegen >/dev/null || { echo "xcodegen not found. brew install xcodegen"; exit 1; }

cd "$TESTBED"
xcodegen generate
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcodebuild -project Testbed.xcodeproj -scheme Testbed \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath build build
APP="$(find build/Build/Products -name 'Testbed.app' -maxdepth 3 | head -1)"
xcrun simctl install "$DEVICE" "$APP"
xcrun simctl launch "$DEVICE" com.repgem.testbed
open -a Simulator
