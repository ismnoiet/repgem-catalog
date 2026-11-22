// What a contributor writes in <folder>/item.json (the site reads the same shape).
export type Domain = 'interaction' | 'package'
export type Platform = 'ios' | 'android' | 'macos' | 'react-native' | 'cross-platform'

/** What a contributor writes in <folder>/item.json. */
export interface ItemMeta {
  id: string
  slug: string
  title: string
  /** Picks the preview drawn on the cards (see previews/markup.ts). */
  kind: string
  desc: string
  long?: string
  /** true: kept in the repo but not shown anywhere in the web app (home, search, detail page, counts). The dashboard still lists it. */
  hidden?: boolean
  /** When the item was created (ISO date-time). Set by `bun run new` and the dashboard; older items fall back to the date git first saw them. */
  added?: string
  repo?: string
  /** Android packages: Maven artifact name used in the Gradle snippet. */
  artifact?: string
  /** Extra rows for the "Details" grid, after Platforms and Type. */
  stats?: [string, string][]
  /** Motion spec rows (interactions). */
  spec?: [string, string][]
  /** Parameter docs (packages). */
  params?: [string, string][]
  /** Install steps (packages). Second value null = a note without a code block. */
  steps?: [string, string | null][]
  /** Sidebar facts (packages). */
  meta?: [string, string][]
  /** Optional. What this drew from: strings, or { title, url?, note? }. Shown on the detail page above the facts grid. */
  inspiration?: (string | { title: string; url?: string; note?: string })[]
  /** Slugs of interactions this package contains. */
  contains?: string[]
  /** Four tag axes: how it is triggered, where it is used, how it moves, and what it is. */
  tags?: { gesture?: string[]; pattern?: string[]; effect?: string[]; element?: string[] }
  /** Items that share a family are the same interaction on different platforms (e.g. "border-beam" on iOS and Android). One card is shown; the detail page toggles between them. */
  family?: string
  /** Optional hosted video and poster. Overrides demo.mp4 / poster.jpg in the item folder. */
  video?: string
  /** the demo already includes the device bezel (rounded black corners are masked) */
  framed?: boolean
  /** the demo is a full-bleed background: it covers the whole card and stage (no phone-shaped box) */
  fill?: boolean
  poster?: string
  /** Second of demo.mp4 that `bun run posters` turns into poster.jpg (default 1). */
  posterAt?: number
  /** Code tabs. `file` is relative to the item folder. */
  sources?: { tab: string; file: string }[]
}
