// Turns command-line targets into item folders. Used by `bun run test` and `bun run list`.
//   package:<slug> interaction:<slug>   (globs allowed)   platform:<name>   tag:<value>   kind:<kind>
//   gesture: pattern: effect: element:  one tag axis
// Shortcuts: a bare slug, interactions, packages, a bare platform name, interactions/ios.
import { DOMAINS, entries, hasMeta, readMeta, type Entry } from './catalog'

export const items = entries().filter(hasMeta)
export const metaOf = new Map(items.map((e) => [e.rel, readMeta(e)]))

export const PLATFORMS = new Set<string>(Object.values(DOMAINS).flat())
export const AXES = ['gesture', 'pattern', 'effect', 'element'] as const
export const KEYS = ['package', 'interaction', 'platform', 'tag', 'kind', ...AXES]

export const die = (msg: string): never => {
  console.error(msg)
  process.exit(2)
}
export const names = (es: Entry[]) => es.map((e) => e.slug).sort().join(', ') || '(none)'
const glob = (pattern: string) =>
  new RegExp('^' + pattern.split('*').map((s) => s.replace(/[.+?^${}()|[\]\\]/g, '\\$&')).join('.*') + '$', 'i')
const norm = (s: string) => s.toLowerCase().replace(/[\s-]+/g, ' ')

function byKey(key: string, value: string): Entry[] {
  switch (key) {
    case 'package':
    case 'interaction': {
      const domain = key === 'package' ? 'packages' : 'interactions'
      const re = glob(value)
      const pool = items.filter((e) => e.domain === domain)
      const hit = pool.filter((e) => re.test(e.slug))
      if (!hit.length) {
        const other = items.find((e) => e.domain !== domain && e.slug === value)
        if (other) die(`"${value}" is ${other.domain === 'packages' ? 'a package' : 'an interaction'}; use ${other.domain === 'packages' ? 'package' : 'interaction'}:${value}`)
        die(`no ${key} matches "${value}".\n${key}s: ${names(pool)}`)
      }
      return hit
    }
    case 'platform': {
      if (!PLATFORMS.has(value)) die(`unknown platform "${value}". platforms: ${[...PLATFORMS].join(', ')}`)
      return items.filter((e) => e.platform === value)
    }
    case 'kind': {
      const hit = items.filter((e) => metaOf.get(e.rel)!.kind === value)
      if (!hit.length) die(`no item has kind "${value}". kinds: ${[...new Set(items.map((e) => metaOf.get(e.rel)!.kind))].sort().join(', ')}`)
      return hit
    }
    default: {
      const axes = key === 'tag' ? AXES : [key as (typeof AXES)[number]]
      const want = norm(value)
      const hit = items.filter((e) => axes.some((a) => (metaOf.get(e.rel)!.tags?.[a] ?? []).some((t) => norm(t) === want)))
      if (!hit.length) {
        const known = new Set<string>()
        for (const e of items) for (const a of axes) for (const t of metaOf.get(e.rel)!.tags?.[a] ?? []) known.add(t)
        die(`no item is tagged "${value}"${key === 'tag' ? '' : ' on the ' + key + ' axis'}.\ntags: ${[...known].sort().join(', ')}`)
      }
      return hit
    }
  }
}

/** Resolves one target to item folders, or returns null when it is not an item target. */
export function selectOne(t: string): Entry[] | null {
  if (t === 'all') return items
  const colon = t.indexOf(':')
  if (colon > 0) {
    const key = t.slice(0, colon), value = t.slice(colon + 1)
    if (!KEYS.includes(key)) die(`unknown selector "${key}:". selectors: ${KEYS.map((k) => k + ':').join(' ')}`)
    if (!value) die(`"${t}" needs a value, e.g. ${key}:<name>`)
    return byKey(key, value)
  }
  if (t in DOMAINS) return items.filter((e) => e.domain === t)
  if (PLATFORMS.has(t)) return items.filter((e) => e.platform === t)
  const [d, p, ...more] = t.split('/')
  if (d in DOMAINS && p && !more.length && (DOMAINS[d as keyof typeof DOMAINS] as readonly string[]).includes(p))
    return items.filter((e) => e.domain === d && e.platform === p)
  const hit = items.filter((e) => e.slug === t || e.rel === t)
  return hit.length ? hit : null
}

export const unknownTarget = (t: string) =>
  die(
    `unknown target "${t}".\n` +
      `use ${KEYS.map((k) => k + ':<value>').join(' | ')}\n` +
      `packages: ${names(items.filter((e) => e.domain === 'packages'))}\n` +
      `interactions: ${names(items.filter((e) => e.domain === 'interactions'))}`,
  )
