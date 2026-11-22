#!/usr/bin/env bash
# Runs the unit tests, optionally only the ones matching a pattern.
#   ./scripts/test.sh                       everything
#   ./scripts/test.sh DragMathTests         one class
#   ./scripts/test.sh slot                  by name pattern
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -gt 0 ]]; then
  swift test --filter "$1"
else
  swift test
fi
