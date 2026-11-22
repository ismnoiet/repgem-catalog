#!/usr/bin/env bash
# Runs the unit tests, optionally only the ones matching a pattern.
#   ./scripts/test.sh                       everything
#   ./scripts/test.sh DragMathTest          one class
#   ./scripts/test.sh '*slot*'              by name pattern
# The HTML report is at dragablecards/build/reports/tests/testDebugUnitTest/index.html
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -gt 0 ]]; then
  ./gradlew :dragablecards:testDebugUnitTest --tests "*$1*"
else
  ./gradlew :dragablecards:testDebugUnitTest
fi
