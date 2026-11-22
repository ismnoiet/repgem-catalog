// bun run sync-common [--check]
// Copies the shared demo frame in common/ into every item that shows a demo, so each item folder stays
// self-contained (and can be mirrored to its own repo). Android copies get their `package` line rewritten
// to the item's demo package. --check only reports copies that are out of date.
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { ROOT, entries } from './lib/catalog'

const IOS = readFileSync(join(ROOT, 'common', 'ios', 'DemoScreen.swift'), 'utf8')
const ANDROID = readFileSync(join(ROOT, 'common', 'android', 'DemoScreen.kt'), 'utf8')

export interface Target { file: string; content: string }

/** Folders under dir (any depth) that hold an Examples.kt, i.e. the Android demo source folders. */
function androidDemoDirs(dir: string): string[] {
  const out: string[] = []
  const walk = (d: string) => {
    for (const n of readdirSync(d, { withFileTypes: true })) {
      if (n.name.startsWith('.') || n.name === 'build') continue
      if (n.isDirectory()) walk(join(d, n.name))
      else if (n.name === 'Examples.kt') out.push(d)
    }
  }
  walk(dir)
  return out
}

export function targets(): Target[] {
  const out: Target[] = []
  for (const e of entries()) {
    if (e.platform === 'ios' && e.domain === 'packages') {
      const src = join(e.dir, 'Sources')
      if (existsSync(src))
        for (const n of readdirSync(src)) if (n.endsWith('Demo') && existsSync(join(src, n, 'Examples.swift'))) out.push({ file: join(src, n, 'DemoScreen.swift'), content: IOS })
    } else if (e.platform === 'android' && e.domain === 'packages') {
      for (const d of androidDemoDirs(e.dir)) {
        const pkg = /^package\s+([\w.]+)/m.exec(readFileSync(join(d, 'Examples.kt'), 'utf8'))?.[1]
        if (pkg) out.push({ file: join(d, 'DemoScreen.kt'), content: ANDROID.replace(/^package\s+[\w.]+/m, `package ${pkg}`) })
      }
    } else if (e.platform === 'ios' && e.domain === 'interactions') {
      out.push({ file: join(e.dir, 'DemoScreen.swift'), content: IOS })
    } else if (e.platform === 'android' && e.domain === 'interactions' && existsSync(join(e.dir, 'Demo.kt'))) {
      const pkg = /^package\s+([\w.]+)/m.exec(readFileSync(join(e.dir, 'Demo.kt'), 'utf8'))?.[1]
      if (pkg) out.push({ file: join(e.dir, 'DemoScreen.kt'), content: ANDROID.replace(/^package\s+[\w.]+/m, `package ${pkg}`) })
    }
  }
  return out
}

export const stale = () => targets().filter((t) => !existsSync(t.file) || readFileSync(t.file, 'utf8') !== t.content)

if (import.meta.main) {
  const rel = (f: string) => f.slice(ROOT.length + 1)
  const out = stale()
  if (process.argv.includes('--check')) {
    if (out.length) { console.error('out of date:\n' + out.map((t) => '  ' + rel(t.file)).join('\n') + '\nrun: bun run sync-common'); process.exit(1) }
    console.log('demo frames are up to date')
  } else {
    for (const t of out) writeFileSync(t.file, t.content)
    console.log(out.length ? `updated ${out.length} demo frame${out.length > 1 ? 's' : ''}` : 'demo frames are up to date')
  }
}
