#!/usr/bin/env bash
# Runs everything CI runs, tests first, then the builds. Works on its own, no need for the rest of the repo.
#   ./scripts/check.sh            tests, then library and demo builds for iOS
#   ./scripts/check.sh --fast     unit tests only (swift test, macOS)
set -euo pipefail
cd "$(dirname "$0")/.."

swift test
[[ "${1:-}" == "--fast" ]] && exit 0

xcodebuild -scheme DustDissolve -destination 'generic/platform=iOS' build
echo "OK: tests pass, build succeeds."
