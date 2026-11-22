// bun run sync-tests [--check]
// Copies tests/item.test.template.ts into every item folder as item.test.ts (so each folder carries its own,
// self-contained test and can be mirrored to its own repo). --check only reports folders that are out of date.
import { copyFileSync, existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { ROOT, entries } from './lib/catalog'

export const TEMPLATE = join(ROOT, 'tests', 'item.test.template.ts')
export const stale = () => entries().filter((e) => !existsSync(join(e.dir, 'item.test.ts')) || readFileSync(join(e.dir, 'item.test.ts'), 'utf8') !== readFileSync(TEMPLATE, 'utf8'))

if (import.meta.main) {
  const check = process.argv.includes('--check')
  const out = stale()
  if (check) {
    if (out.length) { console.error('out of date:\n' + out.map((e) => '  ' + e.rel).join('\n') + '\nrun: bun run sync-tests'); process.exit(1) }
    console.log('item tests are up to date')
  } else {
    for (const e of out) copyFileSync(TEMPLATE, join(e.dir, 'item.test.ts'))
    console.log(out.length ? `updated ${out.length} item test${out.length > 1 ? 's' : ''}` : 'item tests are up to date')
  }
}
