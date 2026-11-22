# Contributing

**For now the catalog only accepts feedback and suggestions.** It is curated by the Repgem team and holds only high-quality interactions, so we are not merging new items or pull requests yet.

## What you can do

- Report a bug or rough edge in an item: open an issue with the item name and your OS or device version.
- Suggest an interaction: open an issue with a screen recording or a link to an app that does it.
- Share feedback on an existing item.

## Maintainers

1. `bun install`.
2. `bun run new <interaction|package> <platform> <slug> "Title"` and fill in the folder (see [docs/item-format.md](docs/item-format.md)).
3. `bun run test <slug>` and `bun run validate` must pass. CI runs both on every pull request.
4. `bun run readme` refreshes the list in the README.

Source in the catalog must be ours to share under this repository's license. Credit what inspired it under `inspiration`.
