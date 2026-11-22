#!/usr/bin/env bash
# Prints a JSON array describing the items (packages/interactions) that changed since a base commit and have a scripts/check.sh.
# Usage: scripts/changed-items.sh [base-sha]   (no base, an unknown base or "all" lists every item)
# Used by .github/workflows/native.yml so an edit to one item only re-runs that item's check; also handy locally.
set -euo pipefail
base="${1:-all}"
head="${2:-HEAD}"

all() { ls -d packages/*/*/ interactions/*/*/ 2>/dev/null || true; }

if [[ "$base" == "all" || "$base" =~ ^0+$ ]] || ! git cat-file -e "$base^{commit}" 2>/dev/null; then
  dirs="$(all)"
else
  files="$(git diff --name-only "$base" "$head")"
  if grep -qx '.github/workflows/native.yml' <<<"$files"; then
    dirs="$(all)"   # the workflow itself changed: verify everything
  else
    dirs="$(grep -E '^(packages|interactions)/[^/]+/[^/]+/' <<<"$files" | cut -d/ -f1-3 | sort -u || true)"
  fi
fi

out=()
while IFS= read -r d; do
  d="${d%/}"
  [[ -n "$d" && -f "$d/scripts/check.sh" ]] || continue   # deleted items and folders without a check are skipped
  top="${d%%/*}"; kind="${top%s}"; platform="$(cut -d/ -f2 <<<"$d")"; slug="${d##*/}"
  case "$platform" in ios|macos) os="macos-latest" ;; *) os="ubuntu-latest" ;; esac
  out+=("$(printf '{"dir":"%s","kind":"%s","platform":"%s","slug":"%s","os":"%s"}' "$d" "$kind" "$platform" "$slug" "$os")")
done <<<"$dirs"

if ((${#out[@]})); then (IFS=,; echo "[${out[*]}]"); else echo "[]"; fi
