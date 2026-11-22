import { describe, expect, test } from 'bun:test'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { ROOT } from '../scripts/lib/catalog'
import { stale, targets } from '../scripts/sync-common'

describe('shared demo frame', () => {
  test('every copy matches common/ (run: bun run sync-common)', () => {
    expect(stale().map((t) => t.file.slice(ROOT.length + 1))).toEqual([])
  })
  test('there are copies to keep in sync', () => {
    expect(targets().length).toBeGreaterThan(0)
  })
  test('the label is plain and both platforms share the spacing', () => {
    const ios = readFileSync(join(ROOT, 'common/ios/DemoScreen.swift'), 'utf8')
    const kt = readFileSync(join(ROOT, 'common/android/DemoScreen.kt'), 'utf8')
    for (const src of [ios, kt]) expect(src).toContain('"@repgem"')
    for (const [name, v] of [['side', 20], ['top', 12], ['bottom', 16], ['gap', 12]] as const) {
      expect(ios).toMatch(new RegExp(`${name}: CGFloat = ${v}\\b`))
      expect(kt).toMatch(new RegExp(`val ${name} = ${v}\\.dp`))
    }
  })
})
