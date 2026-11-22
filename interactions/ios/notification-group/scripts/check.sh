#!/usr/bin/env bash
# Interactions are snippets: the check is the folder's metadata test (needs Bun).
set -euo pipefail
cd "$(dirname "$0")/.."
bun test
