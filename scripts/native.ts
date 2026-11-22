// bun run test:native [slug | glob ...]   (no argument: every item that has native tests)
// Runs a package's own tests, whichever kind it has. They live inside the item folder, so a mirrored repo runs the same command:
//   scripts/test.sh          used when present
//   Package.swift + Tests/   swift test
//   gradlew + src/test       ./gradlew testDebugUnitTest
import { existsSync, readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'
import { entries } from './lib/catalog'
import { selectOne } from './lib/select'

type Runner = { label: string; cmd: string[] }

function hasDir(root: string, match: (p: string) => boolean, depth = 4): boolean {
  if (depth < 0 || !existsSync(root)) return false
  for (const n of readdirSync(root)) {
    if (n.startsWith('.') || n === 'build' || n === 'node_modules') continue
    const p = join(root, n)
    if (!statSync(p).isDirectory()) continue
    if (match(p) || hasDir(p, match, depth - 1)) return true
  }
  return false
}

export function runnerFor(dir: string): Runner | null {
  if (existsSync(join(dir, 'scripts/test.sh'))) return { label: 'scripts/test.sh', cmd: ['bash', 'scripts/test.sh'] }
  if (existsSync(join(dir, 'Package.swift')) && existsSync(join(dir, 'Tests'))) return { label: 'swift test', cmd: ['swift', 'test'] }
  if (existsSync(join(dir, 'gradlew')) && hasDir(dir, (p) => p.endsWith('src/test'))) return { label: './gradlew testDebugUnitTest', cmd: ['./gradlew', 'testDebugUnitTest'] }
  return null
}

if (import.meta.main) {
  const targets = process.argv.slice(2).filter((a) => !a.startsWith('-'))
  const picked = targets.length ? targets.flatMap((t) => selectOne(t) ?? []) : entries()
  const withTests = picked.map((e) => ({ e, r: runnerFor(e.dir) })).filter((x): x is { e: (typeof picked)[number]; r: Runner } => x.r !== null)
  if (!withTests.length) { console.log('no native tests found'); process.exit(0) }
  let failed = 0
  for (const { e, r } of withTests) {
    console.log(`\n== ${e.rel}: ${r.label}`)
    const code = await Bun.spawn(r.cmd, { cwd: e.dir, stdio: ['inherit', 'inherit', 'inherit'] }).exited
    if (code !== 0) { failed++; console.error(`FAILED: ${e.rel}`) }
  }
  process.exit(failed ? 1 : 0)
}
