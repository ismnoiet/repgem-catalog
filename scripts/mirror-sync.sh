#!/usr/bin/env bash
# Mirrors item folders into their own GitHub repos (one-way snapshot sync).
# Usage: scripts/mirror-sync.sh <item-dir>...      e.g. scripts/mirror-sync.sh packages/ios/border-beam-ios
# Env:   MIRROR_OWNER   owner of the mirror repos (default: owner of the current repo)
#        MIRROR_TOKEN   token with Contents (and Workflows) write on the mirrors; without it nothing is pushed
#        MIRROR_AUTHOR_NAME / MIRROR_AUTHOR_EMAIL   commit author on the mirrors (default ismnoiet / ismnoiet@users.noreply.github.com)
#        MIRROR_BASE    git URL base, default https://x-access-token:$MIRROR_TOKEN@github.com (override to test with local repos)
# The mirror is <MIRROR_OWNER>/<slug>, or item.json "mirror" ("name" or "owner/name"). A mirror that does not exist yet is skipped:
# create it first (admin app: row menu, Mirror repo). Keep the naming in step with apps/admin/server/mirror.ts in the site repo.
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"
owner="${MIRROR_OWNER:-${GITHUB_REPOSITORY_OWNER:-}}"
base="${MIRROR_BASE:-https://x-access-token:${MIRROR_TOKEN:-}@github.com}"
if [[ -z "${MIRROR_BASE:-}" && -z "${MIRROR_TOKEN:-}" ]]; then echo "MIRROR_TOKEN is not set: nothing to do"; exit 0; fi
[[ -n "$owner" ]] || { echo "MIRROR_OWNER is not set" >&2; exit 1; }
sha="$(git rev-parse --short HEAD)"
catalog="${GITHUB_REPOSITORY:-$owner/repgem-catalog}"
rc=0

for dir in "$@"; do
  dir="${dir%/}"
  [[ -d "$dir" ]] || { echo "skip $dir (no such folder)"; continue; }
  slug="${dir##*/}"
  if grep -Eq '"hidden"[[:space:]]*:[[:space:]]*true' "$dir/item.json" 2>/dev/null; then echo "skip $dir (hidden: not mirrored)"; continue; fi
  custom="$( { grep -o '"mirror"[[:space:]]*:[[:space:]]*"[^"]*"' "$dir/item.json" 2>/dev/null || true; } | head -1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/')"
  name="${custom:-$slug}"
  if [[ "$name" == */* ]]; then full="$name"; else full="$owner/$name"; fi
  subject="$(git log -1 --no-merges --format=%s -- "$dir")"

  tmp="$(mktemp -d)"
  if ! git clone -q "$base/$full.git" "$tmp/repo" 2>/dev/null; then
    echo "::notice::mirror $full does not exist (or the token cannot read it): skipped $dir"
    rm -rf "$tmp"; continue
  fi
  (
    cd "$tmp/repo"
    if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
      git fetch -q origin main || exit 1
      git checkout -q -B main FETCH_HEAD || exit 1
    else
      git checkout -q -B main || exit 1
    fi
    find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
    tar -C "$root/$dir" --exclude=.build --exclude=build --exclude=.gradle --exclude=DerivedData --exclude=node_modules --exclude=.DS_Store -cf - . | tar -xf -
    # Banner on top of the README, re-added on every sync (the catalog README never carries it).
    if [[ -f README.md ]]; then
      { printf '> **Read-only mirror.** This repository is synced from the catalog on [%s](https://github.com/%s)/`%s`. Please open issues and check the code there; changes made here are overwritten on the next sync.\n>\n> This mirror exists only so the package can be installed directly from this repository.\n\n' "$catalog" "$catalog" "$dir"; cat README.md; } > README.md.new && mv README.md.new README.md
    fi
    [[ -f LICENSE ]] || { [[ -f "$root/LICENSE" ]] && cp "$root/LICENSE" LICENSE || true; }
    git add -A || exit 1
    changed=0
    if ! git diff --cached --quiet; then
      changed=1
      git -c user.name="${MIRROR_AUTHOR_NAME:-ismnoiet}" -c user.email="${MIRROR_AUTHOR_EMAIL:-ismnoiet@users.noreply.github.com}" commit -q -m "Mirror from $catalog@$sha: $subject" -m "Source: $dir. This repository is a read-only mirror; open issues and pull requests on the catalog." || exit 1
      git push -q origin HEAD:main || exit 1
    fi

    # Releases: item.json "version" (semver) -> tag v<version> on the mirror plus a GitHub release, once. SwiftPM and JitPack install by that tag.
    version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)".*/\1/p' "$root/$dir/item.json" | head -1)"
    tag=""
    if [[ -n "$version" ]]; then
      if git rev-parse -q --verify "refs/tags/$version" >/dev/null; then
        if [[ "$changed" == 1 ]]; then echo "::warning::$full: content changed but $version is already released; bump \"version\" in $dir/item.json to publish it"; fi
      else
        git -c user.name="${MIRROR_AUTHOR_NAME:-ismnoiet}" -c user.email="${MIRROR_AUTHOR_EMAIL:-ismnoiet@users.noreply.github.com}" tag -a "$version" -m "$slug $version" || exit 1
        git push -q origin "$version" || exit 1
        tag="$version"
        # Release notes: the "## <version>" section of CHANGELOG.md in the item when there is one, else a one-line default.
        notes="$(awk -v v="$version" '/^## /{p=($2==v||$2=="v" v||$2=="[" v "]")?1:0; next} p' "$root/$dir/CHANGELOG.md" 2>/dev/null || true)"
        [[ -n "${notes//[[:space:]]/}" ]] || notes="Release $version of $slug. Source: https://github.com/$catalog/tree/main/$dir"
        if [[ -n "${MIRROR_TOKEN:-}" ]] && command -v jq >/dev/null; then
          jq -n --arg t "$version" --arg n "$slug $version" --arg b "$notes" '{tag_name:$t,name:$n,body:$b}' \
            | curl -fsS -X POST -H "Authorization: Bearer $MIRROR_TOKEN" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$full/releases" -d @- >/dev/null \
            || echo "::warning::$full: tag $version pushed, but the GitHub release could not be created (token needs Contents write)"
        fi
      fi
    fi

    if [[ "$changed" == 0 && -z "$tag" ]]; then echo "$full: already up to date"; exit 0; fi
    echo "$full: synced${tag:+, tagged $tag}"
  ) || { echo "::error::could not sync $dir to $full"; rc=1; }
  rm -rf "$tmp"
done
exit $rc
