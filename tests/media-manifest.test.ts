import { expect, test } from 'bun:test'
import { checkManifest, names } from '../scripts/lib/media'

test('version tags on media.json entries are allowed and ignored when matching files', () => {
  expect(names(['demo.mp4?h=1a2b3c4d', 'poster.jpg'])).toEqual(['demo.mp4', 'poster.jpg'])
  expect(checkManifest({ x: ['demo.mp4?h=1a2b3c4d', 'poster.jpg?h=ff00ee11'] }, ['x'])).toEqual([])
})
test('a bad tag, a missing poster and a duplicate file are still caught', () => {
  expect(checkManifest({ x: ['demo.mp4?h=', 'poster.jpg'] }, ['x'])[0]).toContain('bad version tag')
  expect(checkManifest({ x: ['demo.mp4?h=ok'] }, ['x'])[0]).toContain('no poster.jpg')
  expect(checkManifest({ x: ['demo.mp4?h=a', 'demo.mp4?h=b', 'poster.jpg'] }, ['x'])[0]).toContain('twice')
})
