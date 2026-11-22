# Item format

Every item is a folder: `interactions/<platform>/<slug>/` or `packages/<platform>/<slug>/`.

```
interactions/ios/detent-sheet/
  item.json        metadata the site reads (see schema/item.schema.json)
  README.md        what it is and how to use it
  item.test.ts     the item's own contract test (one line, see below)
  *.swift …        the source files listed under "sources"
```

## Adding an item

1. `bun run new <interaction|package> <platform> <slug> "Title"` creates the folder with `item.json` (next free id), `README.md` and `item.test.ts`.
2. Drop the source files in, list the ones to show under `sources`.
3. Fill in `kind`, `desc` and `tags`.
4. `bun run test <slug>`, then `bun run validate`.

Platforms: interactions `ios | android | macos | cross-platform`; packages `ios | android | macos | react-native`.
Allowed kinds, tag axes and source extensions live in `schema/catalog.json` (keep it in sync with the site).

## Tests live with the item

Each item folder carries its own `item.test.ts`. It is self-contained: it imports nothing from outside the folder, so the folder can be mirrored to its own repo and `bun test` still works there. It checks the item's metadata, tags, sources, README, optional fields and that no media files sit in the folder.

The file is generated from `tests/item.test.template.ts`. Do not edit the copies: change the template and run `bun run sync-tests` (CI fails if any copy is stale; `bun run sync-tests --check` reports it).
Native tests live in the package too and travel with it: `Tests/` (run with `swift test`), `src/test` (run with `./gradlew testDebugUnitTest`) and `scripts/test.sh` where a package has one.
Every package has one entry point, `scripts/check.sh`: tests first, then the builds (`--fast` = tests only). CI, the monorepo and anyone who clones just that package run the same script, so nothing outside the package folder is needed.
`bun run test:native` runs the tests that exist (or `bun run test:native <slug>`), and `.github/workflows/native.yml` runs them in CI (macOS for Swift, Ubuntu for Android).
Interactions are snippets, so they only have the metadata test.

`bun run test` runs everything; `bun run test <slug>` runs one item; `bun run test catalog` runs the catalog-wide checks (unique ids and slugs, families, kinds against `schema/catalog.json`, media.json, test copies up to date).

## Media

Demo videos and posters are not stored in git. They live in the media bucket (`https://media.repgem.com/<slug>/`) and are listed in `media.json`:

```json
{ "detent-sheet": ["demo.mp4", "poster.jpg"] }
```

The admin app keeps `media.json` up to date: every upload or delete commits it, and each file carries a version tag that changes when the file is replaced, e.g. `"demo.mp4?h=1a2b3c4d"`. The site adds the tag to the URL (`demo.mp4?h=1a2b3c4d`), so a replaced video is never served from an old cache. The tag is optional when you edit the file by hand.

A video needs a poster; a poster needs a video; only `demo.mp4`, `demo.webm` and `poster.jpg` are allowed names. Do not put media files in the item folder.
To use a video hosted elsewhere, set `"video"` (and `"poster"`) in `item.json` to https URLs.

## Same interaction on several platforms

Make one folder per platform and name the slugs `<name>-ios`, `<name>-android`, `-macos`, `-react-native`; they are paired automatically. For other slugs give both the same `"family"` in `item.json`.

## Inspiration (optional)

```json
"inspiration": ["Apple Maps place sheet", { "title": "Linear", "url": "https://linear.app", "note": "How the tab bar settles" }]
```

`url` must be https.

## Demo screens

Every demo (package demos and interaction previews) uses the same frame: the title on the left, a plain
`@repgem` label on the right, and your content below. The frame lives in `common/`:

- `common/ios/DemoScreen.swift` and `common/android/DemoScreen.kt` are the source of truth.
- `bun run sync-common` copies them into each item (Android copies get the item's package line), so every
  folder stays self-contained and can be mirrored to its own repo. Never edit the copies by hand;
  `bun test` fails when a copy is out of date.
- Use it as `DemoScreen(title:dark:background:) { ... }` (SwiftUI) or `DemoScreen(title, background, titleColor) { ... }` (Compose).
- Pass `onBack` (`onBack: { ... }`, `() -> Void` on iOS, `() -> Unit` on Android) to show a back chevron before the title. It is empty by default, so package previews look as before; an app that opens the demo passes it. The package demo entry points (`DustDissolveExamples(onBack:)`, `DragableCardsExamples(onBack:)`, `StickyRangeSliderExamples(onBack:)` and their `Light` versions) forward it.

## Versions and releases (packages)

A package's `item.json` has a `version` in semver (`"1.2.0"`). The `mirror` workflow uses it:

- **New version:** when the mirror repo has no tag `<version>`, the sync tags the new commit `1.2.0` and creates a GitHub release. Swift Package Manager (`from: "1.2.0"`) and JitPack (`com.github.<owner>:<slug>:1.2.0`) install by that tag.
- **Release notes:** the `## 1.2.0` section of an optional `CHANGELOG.md` in the item folder; otherwise a one-line default.
- **Same version, changed code:** the sync pushes the commit but never moves a tag, and prints a warning to bump `version`.
- **Bumping:** edit `version` in `item.json`, or use Release in the admin (patch, minor or major). Plain edits without a bump stay untagged.

## Item numbers

`id` (shown as "№ 028") is permanent: it never changes and is never reused, even after the item is deleted. `ids.json` holds `nextId`; `bun run new`, `bun run from-template` (in the site repo) and the admin use it (or the highest existing number + 1, whichever is larger) and raise it on every new item. Do not lower it by hand.

`version` in `item.json` is the only place the version is written. The `.podspec` files (iOS) and the `build.gradle.kts` publishing block (Android) read it from `item.json` when they are evaluated, and a catalog test fails if either hard-codes a version again. A release is therefore one edit to `item.json`.

## Adding an item: start from the latest main, on its own branch

`bun run new` (here) and `bun run from-template` (in the site repo) first make sure the checkout is current: they stop if tracked files have uncommitted changes, fetch `origin`, fast-forward `main` to `origin/main` (and stop if it has diverged), then switch to a new branch `item/<name>`. The iOS and Android versions of one item share the branch (`item/pulse-ring` holds `pulse-ring-ios` and `pulse-ring-android`). Open the pull request from that branch when the item is done. `--no-git` skips all of this; set `CATALOG_REMOTE` or `CATALOG_BASE` if your remote or default branch is not `origin` / `main`.
