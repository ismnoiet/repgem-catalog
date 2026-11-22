// Checks across the whole catalog: unique ids and slugs, links resolve, every item has its own test.
import { describe, expect, test } from 'bun:test'
import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { ROOT, entries, hasMeta, readMeta } from '../scripts/lib/catalog'
import schema from '../schema/catalog.json'
import { DOMAINS } from '../scripts/lib/catalog'
import { stale } from '../scripts/sync-item-tests'
import { checkManifest, names, readManifest } from '../scripts/lib/media'

const all = entries()
const withMeta = all.filter(hasMeta)
const metas = withMeta.map((e) => ({ e, m: readMeta(e) }))

describe('catalog', () => {
  test('every item folder has an item.json', () => {
    expect(all.filter((e) => !hasMeta(e)).map((e) => e.rel)).toEqual([])
  })

  test('ids.json nextId is above every id in use, so numbers are never reused', () => {
    const next = Number(JSON.parse(readFileSync(join(ROOT, 'ids.json'), 'utf8')).nextId)
    const top = Math.max(0, ...metas.map(({ m }) => parseInt(m.id, 10) || 0))
    expect(next).toBeGreaterThan(top)
  })

  test('package build files take the version from item.json instead of hard-coding it', () => {
    const bad: string[] = []
    const walk = (d: string): string[] => readdirSync(d, { withFileTypes: true }).flatMap((x) => (x.isDirectory() ? (['build', '.build', '.gradle', 'node_modules'].includes(x.name) ? [] : walk(join(d, x.name))) : [join(d, x.name)]))
    for (const { e } of metas.filter(({ e }) => e.domain === 'packages')) {
      for (const f of walk(e.dir)) {
        const t = readFileSync(f, 'utf8')
        if (f.endsWith('.podspec') && /s\.version\s*=\s*"/.test(t)) bad.push(`${f}: hard-coded s.version`)
        if (f.endsWith('build.gradle.kts') && /\bversion\s*=\s*"\d+\.\d+\.\d+"/.test(t)) bad.push(`${f}: hard-coded version`)
      }
    }
    expect(bad).toEqual([])
  })

  test('ids are unique', () => {
    const seen = new Map<string, string>()
    const dupes: string[] = []
    for (const { e, m } of metas) {
      if (seen.has(m.id)) dupes.push(`${m.id}: ${seen.get(m.id)} and ${e.rel}`)
      seen.set(m.id, e.rel)
    }
    expect(dupes).toEqual([])
  })

  test('a family has two or more platform versions, one per platform', () => {
    const fam = new Map<string, string[]>()
    for (const { e, m } of metas) if (m.family) fam.set(m.family, [...(fam.get(m.family) ?? []), e.platform])
    const bad: string[] = []
    for (const [name, platforms] of fam) {
      if (platforms.length < 2) bad.push(`${name}: needs a second platform version`)
      if (new Set(platforms).size !== platforms.length) bad.push(`${name}: two versions on the same platform`)
    }
    expect(bad).toEqual([])
  })

  test('slugs are unique', () => {
    const slugs = metas.map(({ m }) => m.slug)
    expect(slugs.filter((s, i) => slugs.indexOf(s) !== i)).toEqual([])
  })

  test('package "contains" points at interactions that exist', () => {
    const interactions = new Set(metas.filter(({ e }) => e.domain === 'interactions').map(({ m }) => m.slug))
    const bad: string[] = []
    for (const { e, m } of metas) for (const c of m.contains ?? []) if (!interactions.has(c)) bad.push(`${e.rel} -> ${c}`)
    expect(bad).toEqual([])
  })

  test('tags are spelled one way everywhere', () => {
    const byKey = new Map<string, Set<string>>()
    for (const { m } of metas)
      for (const v of Object.values(m.tags ?? {}).flat()) {
        const k = v.toLowerCase().replace(/[\s-]+/g, ' ')
        byKey.set(k, (byKey.get(k) ?? new Set()).add(v))
      }
    const clashes = [...byKey.values()].filter((s) => s.size > 1).map((s) => [...s].join(' / '))
    expect(clashes, 'same tag with different spelling').toEqual([])
  })

  test('every item carries an up-to-date, self-contained item.test.ts', () => {
    expect(stale().map((e) => e.rel), 'run: bun run sync-tests').toEqual([])
  })

  test('folder, slug, platform and kind agree with the catalog schema', () => {
    const bad: string[] = []
    for (const { e, m } of metas) {
      if (m.slug !== e.slug) bad.push(`${e.rel}: slug "${m.slug}" != folder`)
      if (!(DOMAINS[e.domain] as readonly string[]).includes(e.platform)) bad.push(`${e.rel}: unknown platform ${e.platform}`)
      if (!schema.kinds.includes(m.kind)) bad.push(`${e.rel}: unknown kind "${m.kind}" (see schema/catalog.json)`)
    }
    expect(bad).toEqual([])
  })

  test('a video (from media.json or "video") always has a poster', () => {
    const man = readManifest(ROOT)
    const bad: string[] = []
    for (const { e, m } of metas) {
      const f = names(man[m.slug] ?? [])
      const video = f.includes('demo.mp4') || f.includes('demo.webm') || Boolean(m.video)
      if (video && !(f.includes('poster.jpg') || m.poster)) bad.push(`${e.rel}: video without poster`)
    }
    expect(bad).toEqual([])
  })

  test('media.json lists only real items, known files, and a poster with every video', () => {
    expect(checkManifest(readManifest(ROOT), metas.map(({ m }) => m.slug))).toEqual([])
  })
})
