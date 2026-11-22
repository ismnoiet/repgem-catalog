// Before a new item is added: bring the catalog checkout up to date with the remote, then work on a branch of its own.
//   1. refuses to start if the working tree has uncommitted changes to tracked files
//   2. git fetch, switch to the base branch (main) and fast-forward it to origin/main (refuses if it has diverged)
//   3. creates and switches to item/<name>, so the item can be reviewed and merged on its own
// Adding the other platform of the same item reuses the branch (item/pulse-ring holds pulse-ring-ios and pulse-ring-android).
// A folder that is not a git checkout (a temporary copy, a test) is left alone. Override with CATALOG_REMOTE / CATALOG_BASE.
import { execFileSync } from 'node:child_process'
import { existsSync } from 'node:fs'
import { join } from 'node:path'

export const itemBranch = (name: string) => `item/${name.replace(/-(ios|android|macos)$/, '')}`

export function prepareItemBranch(root: string, name: string): string | null {
  if (!existsSync(join(root, '.git'))) return null
  const remote = process.env.CATALOG_REMOTE ?? 'origin'
  const base = process.env.CATALOG_BASE ?? 'main'
  const branch = itemBranch(name)
  const git = (...args: string[]) => execFileSync('git', args, { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim()
  const fail = (what: string, e: unknown) => {
    throw new Error(`${what}\n${((e as { stderr?: string }).stderr ?? (e as Error).message ?? '').toString().trim()}`.trim())
  }

  // Already on this item's branch (the second platform of the same item): nothing to sync.
  if (git('rev-parse', '--abbrev-ref', 'HEAD') === branch) return branch

  if (git('status', '--porcelain', '--untracked-files=no'))
    throw new Error(`${root} has uncommitted changes. Commit or stash them first, so the new item starts from a clean, up-to-date ${base}.`)
  try { git('fetch', remote) } catch (e) { fail(`could not fetch ${remote}; check the connection (set CATALOG_REMOTE if the remote has another name)`, e) }
  try { git('checkout', base) } catch (e) { fail(`could not switch to ${base}`, e) }
  try { git('merge', '--ff-only', `${remote}/${base}`) } catch (e) { fail(`local ${base} has diverged from ${remote}/${base}; sort that out first (rebase or reset), then add the item`, e) }
  const ahead = Number(git('rev-list', '--count', `${remote}/${base}..${base}`))
  if (ahead > 0) console.warn(`note: local ${base} has ${ahead} commit(s) that are not on ${remote}/${base} yet; the new branch includes them`)
  if (git('branch', '--list', branch)) throw new Error(`branch ${branch} already exists; switch to it (git switch ${branch}) and run again, or finish or delete it first`)
  try { git('switch', '-c', branch) } catch (e) { fail(`could not create ${branch}`, e) }
  return branch
}
