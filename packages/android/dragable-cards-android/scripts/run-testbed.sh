#!/usr/bin/env bash
# Installs android-testbed (which includes the DragableCards demos) on a connected device or emulator
# and opens it. Expects android-testbed next to this folder (ai/modules/android-testbed).
set -euo pipefail
TESTBED="$(cd "$(dirname "$0")/../../android-testbed" && pwd)"

command -v adb >/dev/null || { echo "adb not found. Install Android platform-tools."; exit 1; }
adb get-state >/dev/null 2>&1 || { echo "No device or emulator connected."; exit 1; }

cd "$TESTBED"
./gradlew :app:installDebug
adb shell am start -n com.repgem.testbed/.MainActivity
