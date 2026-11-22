import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'

/** media.json: for each item slug, which demo files exist in the media bucket (the files themselves are not in git).
 *  An entry may carry a version tag, "demo.mp4?h=1a2b3c4d": the site adds it to the URL, so a replaced file is never served from an old cache. */
export type Manifest = Record<string, string[]>
export const bare = (f: string) => f.split('?')[0]
export const VERSION_RE = /^[a-z0-9]{1,16}$/
/** The file names of an entry without their version tags. */
export const names = (files: string[]) => files.map(bare)
export const MEDIA_FILES = ['demo.mp4', 'demo.webm', 'poster.jpg'] as const

export function readManifest(root: string): Manifest {
  const p = join(root, 'media.json')
  return existsSync(p) ? (JSON.parse(readFileSync(p, 'utf8')) as Manifest) : {}
}

/** Problems with the manifest itself: unknown slugs or files, a video without a poster, a poster without a video. */
export function checkManifest(m: Manifest, slugs: string[]): string[] {
  const errs: string[] = []
  for (const [slug, files] of Object.entries(m)) {
    if (!slugs.includes(slug)) errs.push(`media.json: "${slug}" is not an item`)
    if (!Array.isArray(files)) { errs.push(`media.json: "${slug}" must be a list of files`); continue }
    for (const f of files) {
      const [name, tag, ...more] = f.split('?h=')
      if (!(MEDIA_FILES as readonly string[]).includes(name)) errs.push(`media.json: ${slug}/${name} is not one of ${MEDIA_FILES.join(', ')}`)
      else if (more.length || (tag !== undefined && !VERSION_RE.test(tag))) errs.push(`media.json: ${slug}/${f} has a bad version tag (use "${name}?h=<letters and digits>")`)
    }
    const list = names(files)
    if (new Set(list).size !== list.length) errs.push(`media.json: "${slug}" lists a file twice`)
    const video = list.includes('demo.mp4') || list.includes('demo.webm')
    if (video && !list.includes('poster.jpg')) errs.push(`media.json: ${slug} has a video but no poster.jpg`)
    if (!video && list.includes('poster.jpg')) errs.push(`media.json: ${slug} has a poster.jpg but no video`)
  }
  return errs
}
