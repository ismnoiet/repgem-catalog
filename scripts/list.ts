// bun run list [target ...] [--tags] [--json]
//   bun run list                  everything, grouped into interactions and packages
//   bun run list packages         only packages (or: interactions)
//   bun run list platform:ios     the same selectors as `bun run test`: package:, interaction:, platform:, tag:, kind:, gesture:, ...
//   bun run list --tags           add the four tag axes
//   bun run list --json           machine-readable output
import { items, metaOf, selectOne, unknownTarget } from './lib/select'
import type { Entry } from './lib/catalog'

const args = process.argv.slice(2)
const showTags = args.includes('--tags')
const asJson = args.includes('--json')
const targets = args.filter((a) => !a.startsWith('-'))

let picked: Entry[] = items
if (targets.length) {
  const seen = new Set<string>()
  picked = []
  for (const t of targets) {
    const hit = selectOne(t) ?? unknownTarget(t)
    for (const e of hit) if (!seen.has(e.rel)) { seen.add(e.rel); picked.push(e) }
  }
}
picked = [...picked].sort((a, b) => metaOf.get(a.rel)!.id.localeCompare(metaOf.get(b.rel)!.id))

const row = (e: Entry) => {
  const m = metaOf.get(e.rel)!
  return { id: m.id, slug: m.slug, title: m.title, platform: e.platform, domain: e.domain === 'packages' ? 'package' : 'interaction', kind: m.kind, path: e.rel, tags: m.tags ?? {} }
}
const rows = picked.map(row)

if (asJson) {
  console.log(JSON.stringify(rows, null, 2))
  process.exit(0)
}
if (!rows.length) { console.log('no items'); process.exit(0) }

const pad = (s: string, n: number) => s + ' '.repeat(Math.max(0, n - s.length))
for (const domain of ['interaction', 'package'] as const) {
  const group = rows.filter((r) => r.domain === domain)
  if (!group.length) continue
  console.log(`\n${domain === 'package' ? 'Packages' : 'Interactions'} (${group.length})`)
  const w = { slug: Math.max(...group.map((r) => r.slug.length)), plat: Math.max(...group.map((r) => r.platform.length)), title: Math.max(...group.map((r) => r.title.length)) }
  for (const r of group) {
    const tags = showTags ? '  ' + (['gesture', 'pattern', 'effect', 'element'] as const).map((a) => (r.tags[a] ?? []).join('/') || '-').join(' · ') : ''
    console.log(`  ${r.id}  ${pad(r.slug, w.slug)}  ${pad(r.platform, w.plat)}  ${pad(r.title, w.title)}${tags}`)
  }
}
console.log(`\n${rows.length} item${rows.length === 1 ? '' : 's'}`)
