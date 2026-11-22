// bun run test [target ...] [bun test flags]
//
// Targets are key:value, and several can be combined (the union runs):
//   package:<slug>      one package, e.g. package:border-beam-ios     (globs allowed: package:*, package:snap-*)
//   interaction:<slug>  one interaction, e.g. interaction:trip-splash (globs allowed: interaction:*)
//   platform:<name>     ios | android | macos | react-native | cross-platform, interactions and packages
//   tag:<value>         items with that tag on any axis; or gesture: pattern: effect: element: for one axis
//   kind:<kind>         items with that preview kind, e.g. kind:toggle
//   catalog             catalog-wide checks (ids, slugs, links, media.json)
//   all                 everything (same as no target)
// Shortcuts that also work: a bare slug, interactions, packages, a bare platform name, interactions/ios.
// Anything starting with - goes to `bun test` (--watch, --bail, --coverage).
import { ROOT } from './lib/catalog'
import { selectOne, unknownTarget } from './lib/select'

const args = process.argv.slice(2)
const flags = args.filter((a) => a.startsWith('-'))
const targets = args.filter((a) => !a.startsWith('-'))

/** Returns the test paths for one target. */
function resolve(t: string): string[] {
  if (t === 'all') return []
  if (t === 'catalog') return ['tests/catalog.test.ts']
  const hit = selectOne(t)
  if (!hit) return unknownTarget(t)
  return hit.map((e) => e.rel)
}

const paths = [...new Set(targets.flatMap(resolve))]
// bun test treats each argument as a path filter, so prefix with ./ to keep them exact.
const filters = paths.map((p) => (p.startsWith('.') ? p : './' + p))
if (paths.length) console.log(`running: ${paths.join(', ')}`)
const proc = Bun.spawn(['bun', 'test', ...filters, ...flags], { cwd: ROOT, stdio: ['inherit', 'inherit', 'inherit'] })
process.exit(await proc.exited)
