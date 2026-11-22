<p align="center">
  <a href="https://media.repgem.com/dust-dissolve-ios/demo.mp4"><img src="https://media.repgem.com/dust-dissolve-ios/poster.jpg" width="240" alt="DustDissolve demo (click to play)" /></a>
</p>

<h1 align="center">DustDissolve</h1>

Turn any SwiftUI view into dust. A Metal shader eats the view away in any direction, and a cloud of pastel dots is born exactly where it disappears, then flows to a target, drifts off, falls or bursts. Built for a coupon flowing into a total, but it works for dismissing cards, deleting rows, avatars and whole grids. The view never leaves the layout, so nothing around it moves.

Sibling of [dust-dissolve-android](https://github.com/ismnoiet/repgem-catalog/tree/main/packages/android/dust-dissolve-android).

* * *

## ✨ Features

- 🎫 **Any view can dissolve**: one modifier, `.dustSource(_:)`
- ✨ **Shimmer, then dust**: an optional light line crosses the view, then a dithered dissolve that keeps the view's own colors
- 🧭 **Five directions**: `.leftToRight`, `.rightToLeft`, `.topToBottom`, `.bottomToTop`, `.centerOut`
- 💨 **Four motions**: flow to a target, drift one way, fall, burst outward (no target needed)
- 🔲 **Rectangle or ellipse**: no dots in the empty corners of a round view
- 🧩 **Many at once**: one scope, one controller per view (grids, lists)
- 🌫️ **Dust born from the view**: the particles come from the same erosion field as the shader, so nothing is drawn over intact pixels
- 🎯 **Flows to any view**: `.dustTarget()` marks where it lands (the total, a cart badge…)
- 📐 **No frame math**: positions travel as SwiftUI anchors, resolved in the scope's own coordinate space
- ⏱️ **One clock**: host UI (price, banner…) reads `elapsed(at:)` and stays in step with the effect
- 💤 **Free when idle**: no timeline, no canvas work outside a run
- 🦾 **Respects Reduce Motion**: the view just disappears, the dust is skipped

* * *

## Installation

**Swift Package Manager**: Xcode → *File → Add Package Dependencies…* and enter
`https://github.com/ismnoiet/dust-dissolve-ios`, or in `Package.swift`:

```swift
.package(url: "https://github.com/ismnoiet/dust-dissolve-ios", from: "1.0.0")
```

then add the `DustDissolve` product to your target and `import DustDissolve`.

**CocoaPods** (experimental)

```ruby
pod 'DustDissolve', '~> 1.0'
```

### Requirements

| Platform | Minimum |
|---|---|
| iOS | 17.0 |
| macOS | 14.0 |
| visionOS | 1.0 |
| Swift / Xcode | 5.9 / 15 |

* * *

## Quick start

```swift
import DustDissolve

struct Checkout: View {
    @StateObject private var dust = DustDissolveController()

    var body: some View {
        DustDissolveScope(dust) {                       // draws the dust over its content
            VStack {
                CouponTicket()
                    .dustSource(dust)           // the coupon
                    .onTapGesture { dust.fire() }

                Spacer()

                TotalRow()
                    .background { Color.clear.frame(width: 58, height: 19).dustTarget() }   // where it lands
            }
        }
    }
}
```

Keep the rest of the screen in step with the effect by reading the same clock:

```swift
TimelineView(.animation(paused: !dust.isActive)) { tl in
    let t = dust.elapsed(at: tl.date) ?? -1          // seconds since fire(), -1 while idle
    Text(t >= 2.45 ? "$40.20" : "$134.00")
}
```

* * *

## API

| Type | Description |
|---|---|
| `DustDissolveController(config)` | `fire()` runs the effect, `reset()` puts the view back, `elapsed(at:)` is the clock, `isActive`, `finished()` |
| `DustDissolveScope(_:content:)` | Takes one controller or an array. Container that draws the dust over its content. Wrap the screen (or the area the dust flies across) |
| `.dustSource(_:)` | The view that dissolves. The dust is born here. It keeps its place in the layout |
| `.dustTarget(for:)` | Where `.flowToTarget` dust lands (centre of the frame). With a controller it is that one's own target; without, the shared one |
| `DustDissolveConfiguration` | Direction, motion, shape, timing, particle count, dot size, palette, sparkles |

### Props

```swift
var config = DustDissolveConfiguration()
config.particleCount = 2400
config.palette = [.mint, .cyan, .white]
config.dissolveEnd = 1.4
let dust = DustDissolveController(config)
```

| Prop | Type | Default | Description |
|---|---|---|---|
| `shimmer` | `Bool` | `true` | A light line crosses the view before it dissolves |
| `shimmerStart` / `shimmerEnd` | `Double` | 0.28 / 0.62 | The shimmer line crossing the view |
| `direction` | `DustDissolveDirection` | `.leftToRight` | `.leftToRight`, `.rightToLeft`, `.topToBottom`, `.bottomToTop`, `.centerOut` |
| `motion` | `DustDissolveMotion` | `.flowToTarget` | `.flowToTarget`, `.drift(angle:distance:)`, `.burst(distance:)` |
| `shape` | `DustDissolveShape` | `.rectangle` | `.ellipse` for round views |
| `dissolveStart` / `dissolveEnd` | `Double` | 0.55 / 1.10 | The view eaten away |
| `flightStart` | `Double` | 0.95 | When the cloud starts moving |
| `flightStagger` | `Double` | 0.15 | Random extra delay per dot |
| `flightDuration` | `ClosedRange<Double>` | 0.8…0.95 | Flight time per dot |
| `total` | `Double` | 3.0 | Length of the whole sequence |
| `particleCount` | `Int` | 1100 | Number of dots |
| `dotSize` | `ClosedRange<Double>` | 1.8…3.2 | Dot diameter, in points |
| `sparkleEvery` | `Int` | 60 | Every n-th dot flares into a sparkle (`0` = off) |
| `palette` | `[Color]` | pastel | Dot colors |
| `seed` | `UInt64` | 7 | Random seed (give each view its own for variety) |
| `arrival` | `Double` | read-only | When the first dots reach the target |

### Presets

| Preset | Look |
|---|---|
| `.coupon` | The original: shimmer, left → right, flows to a target |
| `.snap` | No shimmer, left → right, the dust blows up and to the right |
| `.dismiss` | Left → right, carried off to the right |
| `.fall` | Top → bottom, the dust falls |
| `.burst` | From the centre, round, the dust bursts outward |

```swift
var c = DustDissolveConfiguration.fall
c.particleCount = 700
let dust = DustDissolveController(c)
```

### Many views at once

```swift
let dusts = (0..<9).map { _ in DustDissolveController(.snap) }

DustDissolveScope(dusts) {
    LazyVGrid(columns: columns) {
        ForEach(Array(dusts.enumerated()), id: \.element.id) { i, dust in
            Tile(i).dustSource(dust)         // each tile has its own controller
        }
    }
}
```

* * *

## Example app

Open `Package.swift` in Xcode, choose the `DustDissolveDemo` scheme and use the preview, or show `DustDissolveExamples()` from an app. Build through Xcode so the shader compiles.

| Demo | Shows |
|---|---|
| Coupons | Tap one: it shimmers, then the dust flows into the "Applied" pill |
| Hide balance | The amount turns to dust, dots take its place |
| Hide password | The visible text turns to dust, dots take its place |
| Disappearing messages | Bubbles blow away toward the side they sit on |

Nothing in the layout moves: a dissolving view keeps its place.

Source: [`Sources/DustDissolveDemo/Examples.swift`](./Sources/DustDissolveDemo/Examples.swift)

* * *

## How it works

- **The shader** (`DustDissolve.metal`) is a `colorEffect`: an optional slanted shimmer band, then a dissolve driven by a smooth erosion field (oriented by `direction`). The edge is dithered: each pixel is fully there or fully gone, so it breaks into dots in the view's own colors.
- **The dust** is a `Canvas`. Each dot is born at the moment the shader removes the pixel under it (same field, same threshold), drifts a little while the cloud hangs, then flows along a Bézier arc to the target, drifts, or bursts, depending on `motion`.
- **The coordinates** come from `anchorPreference`, resolved with a `GeometryProxy` in the scope's own space, so it keeps working with safe areas, sheets and scrolling.

> If you change the erosion field, change it in both `DustDissolve.metal` and `DustDissolveParticles.swift`.

* * *

## ⭐ Support

If you find this useful, give this catalog a star.

## Contributing

Issues and PRs are welcome.

## License

MIT © [ismnoiet](https://github.com/ismnoiet)
