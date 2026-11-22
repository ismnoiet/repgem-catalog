// bun run readme [--check]
// Rewrites the generated parts of README.md (the badge count and the item tables) from every item.json.
// Everything outside the <!-- items:start --> ... <!-- items:end --> and <!-- count --> markers is hand-written.
// --check only reports when README.md is out of date (use it in CI).
import { readFileSync, readdirSync, statSync, writeFileSync, existsSync } from 'node:fs'
import { join } from 'node:path'

const ROOT = join(import.meta.dir, '..')
const README = join(ROOT, 'README.md')
const PLATFORMS: Record<string, string> = { ios: '🍎 iOS · SwiftUI', android: '🤖 Android · Compose', macos: '🖥️ macOS', 'react-native': '⚛️ React Native', 'cross-platform': '🔀 Cross-platform' }
const ORDER = Object.keys(PLATFORMS)
const SITE = 'https://repgem.com'

interface Row { domain: string; platform: string; slug: string; title: string; desc: string; family: string; tags: string[] }
const dirs = (p: string) => (existsSync(p) ? readdirSync(p).filter((n) => !n.startsWith('.') && statSync(join(p, n)).isDirectory()) : [])

export function load(root = ROOT): Row[] {
  const out: Row[] = []
  for (const domain of ['packages', 'interactions'])
    for (const platform of dirs(join(root, domain)))
      for (const slug of dirs(join(root, domain, platform))) {
        const f = join(root, domain, platform, slug, 'item.json')
        if (!existsSync(f)) continue
        const m = JSON.parse(readFileSync(f, 'utf8'))
        if (m.hidden) continue
        out.push({ domain, platform, slug, title: m.title, desc: m.desc, family: m.family ?? slug.replace(/-(ios|android|macos|react-native|compose)$/, ''), tags: [...(m.tags?.effect ?? []), ...(m.tags?.element ?? [])].slice(0, 3) })
      }
  return out
}

const rank = (p: string) => (ORDER.indexOf(p) < 0 ? 99 : ORDER.indexOf(p))
const esc = (s: string) => s.replace(/\|/g, '\\|')

const BADGE: Record<string, { label: string; color: string; logo: string }> = {
  ios: { label: 'iOS', color: '3A3F47', logo: 'apple' },
  android: { label: 'Android', color: '3DDC84', logo: 'android' },
  macos: { label: 'macOS', color: '3A3F47', logo: 'apple' },
  'react-native': { label: 'React%20Native', color: '20232A', logo: 'react' },
  'cross-platform': { label: 'Cross--platform', color: '6B7280', logo: '' },
}
const badge = (r: Row) => {
  const b = BADGE[r.platform] ?? { label: r.platform, color: '6B7280', logo: '' }
  const text = b.color === '3DDC84' ? '000000' : 'FFFFFF'
  const logo = b.logo ? `&logo=${b.logo}&logoColor=${text}` : ''
  return `[![${b.label.replace(/%20/g, ' ')}](https://img.shields.io/badge/${b.label}-${b.color}?style=flat-square${logo}&labelColor=${b.color})](${r.domain}/${r.platform}/${r.slug})`
}

/** One row per family (the same idea on several platforms); each platform version links to its own folder. */
function groups(rows: Row[]): Row[][] {
  const by = new Map<string, Row[]>()
  for (const r of rows) by.set(`${r.domain}/${r.family}`, [...(by.get(`${r.domain}/${r.family}`) ?? []), r])
  return [...by.values()]
    .map((g) => g.sort((a, b) => rank(a.platform) - rank(b.platform)))
    .sort((a, b) => a[0].title.localeCompare(b[0].title))
}

/** The first version's description without framework wording ("for SwiftUI", ", drawn by a Metal shader"), since the row covers every platform. */
const neutral = (d: string) => {
  const t = d.replace(/\s+for (SwiftUI|Jetpack Compose|Compose|AppKit|React Native)\b/gi, '').replace(/,\s*(drawn|built|rendered) (by|with) an? [\w ]+?(shader|Canvas|Metal|AGSL)\b/gi, '').replace(/:\s*:/g, ':').trim()
  return /[.!?]$/.test(t) ? t : t + '.'
}

function table(rows: Row[]): string {
  const lines = ['| Item | What it is | Open |', '|:--|:--|:--|']
  for (const g of groups(rows)) lines.push(`| **${esc(g[0].title)}** | ${esc(neutral(g[0].desc))} | ${g.map(badge).join(' ')} |`)
  return lines.join('\n')
}

export function render(rows: Row[]): { items: string; count: number; versions: number } {
  const pk = rows.filter((r) => r.domain === 'packages'), ix = rows.filter((r) => r.domain === 'interactions')
  const parts: string[] = []
  parts.push(`### 📦 Packages\n\nDrop-in libraries. Click a platform to open that version: what it does, how to install it, and the source.\n\n${pk.length ? table(pk) : '_Coming soon._'}`)
  parts.push(`### ✨ Interactions\n\nRecipes with full source. Click a platform to open it.\n\n${ix.length ? table(ix) : '_Coming soon._'}`)
  return { items: parts.join('\n\n'), count: groups(rows).length, versions: rows.length }
}

export function apply(md: string, rows = load()): string {
  const { items, count, versions } = render(rows)
  return md
    .replace(/<!-- items:start -->[\s\S]*<!-- items:end -->/, `<!-- items:start -->\n${items}\n<!-- items:end -->`)
    .replace(/(<!-- count -->)[^<\n]*(<!-- \/count -->)/g, `$1${count}$2`)
    .replace(/(<!-- versions -->)[^<\n]*(<!-- \/versions -->)/g, `$1${versions}$2`)
    .replace(/(items-)\d+(-)/, `$1${count}$2`)
}

if (import.meta.main) {
  const cur = readFileSync(README, 'utf8'), next = apply(cur)
  if (process.argv.includes('--check')) {
    if (cur !== next) { console.error('README.md is out of date: run `bun run readme`'); process.exit(1) }
    console.log('README.md is up to date')
  } else if (cur !== next) { writeFileSync(README, next); console.log('README.md updated') } else console.log('README.md is up to date')
}
