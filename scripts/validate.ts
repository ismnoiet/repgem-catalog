// bun run validate: quick structural check of every item folder and media.json (the full checks live in `bun run test`).
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { DOMAINS, ROOT, entries, hasMeta, readMeta } from './lib/catalog'
import { checkManifest, readManifest } from './lib/media'

const errs: string[] = []
const ids = new Map<string, string>()
const slugs = new Set<string>()
const contains: [string, string][] = []

for (const e of entries()) {
  if (!(DOMAINS[e.domain] as readonly string[]).includes(e.platform)) { errs.push(`${e.rel}: unknown platform folder`); continue }
  if (!hasMeta(e)) { errs.push(`${e.rel}: missing item.json`); continue }
  let m
  try { m = readMeta(e) } catch { errs.push(`${e.rel}: invalid JSON`); continue }
  for (const k of ['id', 'slug', 'title', 'kind', 'desc'] as const) if (!m[k]) errs.push(`${e.rel}: missing "${k}"`)
  if (m.slug !== e.slug) errs.push(`${e.rel}: slug "${m.slug}" must equal folder name`)
  if (ids.has(m.id)) errs.push(`${e.rel}: id ${m.id} also used by ${ids.get(m.id)}`)
  else ids.set(m.id, e.rel)
  if (slugs.has(m.slug)) errs.push(`${e.rel}: duplicate slug`)
  slugs.add(m.slug)
  for (const s of m.sources ?? []) if (!existsSync(join(e.dir, s.file))) errs.push(`${e.rel}: source not found: ${s.file}`)
  for (const c of m.contains ?? []) contains.push([e.rel, c])
  if (m.contains && e.domain !== 'packages') errs.push(`${e.rel}: only packages can have "contains"`)
  if (!existsSync(join(e.dir, 'item.test.ts'))) errs.push(`${e.rel}: missing item.test.ts (run bun run new, or copy one from another item)`)
}
for (const [at, c] of contains) if (!slugs.has(c)) errs.push(`${at}: contains unknown slug "${c}"`)

const slugList = [...slugs]
errs.push(...checkManifest(readManifest(ROOT), slugList))

if (errs.length) { console.error(errs.join('\n')); process.exit(1) }
console.log(`ok: ${ids.size} items`)
