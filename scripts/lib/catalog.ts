// Walks the repo and returns every item folder. Shared by validate, new, test and the contract tests.
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { join } from 'node:path'
import type { ItemMeta } from './types'
import schema from '../../schema/catalog.json'

export const ROOT = join(import.meta.dir, '..', '..')

/** Allowed platform folders for each domain (schema/catalog.json). */
export const DOMAINS = schema.domains as { interactions: readonly string[]; packages: readonly string[] }
export type DomainDir = keyof typeof DOMAINS

export interface Entry {
  domain: DomainDir
  platform: string
  slug: string
  /** Absolute path of the item folder. */
  dir: string
  /** Path relative to the repo root, e.g. interactions/ios/trip-splash */
  rel: string
}

const dirs = (p: string) =>
  existsSync(p) ? readdirSync(p).filter((n) => !n.startsWith('.') && statSync(join(p, n)).isDirectory()) : []

/** Every <domain>/<platform>/<slug> folder, whether or not it has an item.json yet. */
export function entries(): Entry[] {
  const out: Entry[] = []
  for (const domain of Object.keys(DOMAINS) as DomainDir[])
    for (const platform of dirs(join(ROOT, domain)))
      for (const slug of dirs(join(ROOT, domain, platform)))
        out.push({ domain, platform, slug, dir: join(ROOT, domain, platform, slug), rel: `${domain}/${platform}/${slug}` })
  return out
}

export const hasMeta = (e: Entry) => existsSync(join(e.dir, 'item.json'))
export const readMeta = (e: Entry): ItemMeta => JSON.parse(readFileSync(join(e.dir, 'item.json'), 'utf8'))
export const entryFor = (dir: string) => entries().find((e) => e.dir === dir)

/**
 * Lenient delimiter check for Swift and Kotlin: skips comments, strings and char literals,
 * then makes sure ( [ { are closed in order. Returns a message, or null when balanced.
 */
export function unbalanced(src: string): string | null {
  const open = '([{', close: Record<string, string> = { ')': '(', ']': '[', '}': '{' }
  const stack: string[] = []
  let i = 0
  const line = (at: number) => src.slice(0, at).split('\n').length
  while (i < src.length) {
    const c = src[i]
    if (c === '/' && src[i + 1] === '/') { while (i < src.length && src[i] !== '\n') i++; continue }
    if (c === '/' && src[i + 1] === '*') {
      const e = src.indexOf('*/', i + 2)
      if (e < 0) return `unterminated block comment at line ${line(i)}`
      i = e + 2; continue
    }
    if (c === '"') {
      if (src.startsWith('"""', i)) {
        const e = src.indexOf('"""', i + 3)
        if (e < 0) return `unterminated string at line ${line(i)}`
        i = e + 3; continue
      }
      i++
      while (i < src.length && src[i] !== '"' && src[i] !== '\n') { if (src[i] === '\\') i++; i++ }
      i++; continue
    }
    if (c === "'" && (src[i + 2] === "'" || (src[i + 1] === '\\' && src[i + 3] === "'"))) { i += src[i + 1] === '\\' ? 4 : 3; continue }
    if (open.includes(c)) stack.push(c)
    else if (c in close) {
      if (stack.pop() !== close[c]) return `unexpected "${c}" at line ${line(i)}`
    }
    i++
  }
  return stack.length ? `unclosed "${stack[stack.length - 1]}"` : null
}
