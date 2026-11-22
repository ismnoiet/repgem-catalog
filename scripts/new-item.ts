// bun run new <interaction|package> <platform> <slug> "Title" [--no-git]
// First fetches, fast-forwards main to origin/main and switches to a new branch item/<name> (--no-git skips that).
// Creates <interactions|packages>/<platform>/<slug>/ with item.json (next free id), README.md and item.test.ts.
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import schema from '../schema/catalog.json'
import { DOMAINS, ROOT, entries, hasMeta, readMeta } from './lib/catalog'
import { prepareItemBranch } from './lib/item-branch'
import type { ItemMeta } from './lib/types'

const argv = process.argv.slice(2)
const noGit = argv.includes('--no-git')
const [domain, platform, slug, ...rest] = argv.filter((a) => a !== '--no-git')
const title = rest.join(' ') || slug
const dirName = (domain + 's') as keyof typeof DOMAINS
const die = (m: string): never => { console.error(m); process.exit(1) }

if (!(domain === 'interaction' || domain === 'package') || !(DOMAINS[dirName] as readonly string[]).includes(platform) || !slug)
  die('usage: bun run new <interaction|package> <platform> <slug> "Title"\n' + (Object.keys(DOMAINS) as (keyof typeof DOMAINS)[]).map((d) => `  ${d.slice(0, -1)}: ${DOMAINS[d].join(' | ')}`).join('\n'))
if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) die('slug must be lowercase letters, numbers and dashes (e.g. my-item-ios)')

// Start from the latest remote main, on a branch of its own (item/<name>), before anything is read or written.
if (!noGit) {
  try {
    const branch = prepareItemBranch(ROOT, slug)
    if (branch) console.log(`up to date with the remote; working on branch ${branch}`)
  } catch (e) { die((e as Error).message) }
}

const all = entries().filter(hasMeta)
if (all.some((e) => e.slug === slug)) die(`slug "${slug}" is already used`)
// Numbers are never reused: ids.json remembers the next one, so deleting the newest item does not free its number.
const idsFile = join(ROOT, 'ids.json')
const counter = existsSync(idsFile) ? Number(JSON.parse(readFileSync(idsFile, 'utf8')).nextId) || 0 : 0
const nextNo = Math.max(counter, Math.max(0, ...all.map((e) => parseInt(readMeta(e).id, 10) || 0)) + 1)
const id = String(nextNo).padStart(3, '0')

const meta: ItemMeta = { id, slug, title, kind: schema.kinds.includes('toggle') ? 'toggle' : schema.kinds[0], desc: 'One sentence about the motion.', long: '', tags: { gesture: [], pattern: [], effect: [], element: [] }, sources: [], fill: true, added: new Date().toISOString() }
if (domain === 'package') Object.assign(meta, { contains: [], steps: [], meta: [['Version', '[version]'], ['License', '[license]']] })

const dir = join(ROOT, dirName, platform, slug)
if (existsSync(dir)) die(`${dir} already exists`)
mkdirSync(dir, { recursive: true })
writeFileSync(join(dir, 'item.json'), JSON.stringify(meta, null, 2) + '\n')
writeFileSync(join(dir, 'README.md'), `# ${title}\n\nWhat it does, how to use it, and the files in this folder.\n`)
copyFileSync(join(ROOT, 'tests', 'item.test.template.ts'), join(dir, 'item.test.ts'))
writeFileSync(idsFile, JSON.stringify({ ...(existsSync(idsFile) ? JSON.parse(readFileSync(idsFile, 'utf8')) : {}), nextId: nextNo + 1 }, null, 2) + '\n')
console.log(`created ${dirName}/${platform}/${slug} (№ ${id}) with README.md and item.test.ts`)
console.log('fill in item.json (kind, desc, tags, sources), then run: bun run test ' + slug)
