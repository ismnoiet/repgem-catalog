<p align="center">
  <a href="https://media.repgem.com/dust-dissolve-android/demo.mp4"><img src="https://media.repgem.com/dust-dissolve-android/poster.jpg" width="240" alt="DustDissolve demo (click to play)" /></a>
</p>

<h1 align="center">DustDissolve</h1>

Turn any composable into dust, for Jetpack Compose. An AGSL shader eats the view away in any direction, and a cloud of pastel dots is born exactly where it disappears, then flows to a target, drifts off, falls or bursts. Built for a coupon flowing into a total, but it works for dismissing cards, deleting rows, avatars and whole grids. The view never leaves the layout, so nothing around it moves.

Sibling of [dust-dissolve-ios](https://github.com/ismnoiet/repgem-catalog/tree/main/packages/ios/dust-dissolve-ios).

* * *

## ✨ Features

- 🎫 **Any composable can dissolve**: one modifier, `Modifier.dustSource(dust)`
- ✨ **Shimmer, then dust**: an optional light line crosses the view, then a dithered dissolve that keeps the view's own colors (Android 13+)
- 🧭 **Five directions**: left → right, right → left, top → bottom, bottom → top, centre out
- 💨 **Four motions**: flow to a target, drift one way, fall, burst outward (no target needed)
- 🔲 **Rectangle or ellipse**: no dots in the empty corners of a round view
- 🧩 **Many at once**: one scope, one controller per view (grids, lists)
- 🌫️ **Dust born from the view**: the particles come from the same erosion field as the shader, so nothing is drawn over intact pixels
- 🎯 **Flows to any element**: `Modifier.dustTarget()` marks where it lands (the total, a cart badge…)
- 🧭 **No manual frame math**: positions are compared in window space, only their difference is used
- ⏱️ **One clock**: host UI (price, banner…) reads `dust.time` and stays in step with the effect
- 💤 **Free when idle**: no frame loop and no canvas work outside a run
- 📱 **Works below Android 13**: a straight-edged reveal plus the same dust (no shimmer, no dithered edge)
- 🌓 **Respects "remove animations"**: the view just disappears, the dust is skipped

* * *

## Installation

**JitPack**

```kotlin
// settings.gradle.kts
dependencyResolutionManagement {
    repositories { maven("https://jitpack.io") }
}

// app/build.gradle.kts
dependencies {
    implementation("com.github.ismnoiet.dust-dissolve-android:dustdissolve:1.0.0")
}
```

**Local module**: copy the `dustdissolve` folder into your project and add `include(":dustdissolve")` to `settings.gradle.kts`, then `implementation(project(":dustdissolve"))`.

### Requirements

| | Minimum |
|---|---|
| Android | 7.0 (API 24). The AGSL shader runs on 13+ (API 33); older versions use the straight-edged fallback |
| Compose | BOM 2024.02 (UI 1.6) |
| Kotlin / AGP / JDK | 1.9.22 / 8.1 / 17 |

* * *

## Quick start

```kotlin
import com.repgem.dustdissolve.*

@Composable
fun Checkout() {
    val dust = remember { DustDissolveController() }

    DustDissolveScope(dust) {                               // draws the dust over its content
        Column {
            CouponTicket(
                Modifier
                    .dustSource(dust)               // the coupon
                    .clickable { dust.fire() }
            )

            Spacer(Modifier.weight(1f))

            TotalRow(Modifier.dustTarget())         // where it lands
        }
    }
}
```

Keep the rest of the screen in step with the effect by reading the same clock:

```kotlin
val t = dust.time                                         // seconds since fire(), -1 while idle
Text(if (t >= 2.45) "$40.20" else "$134.00")
```

* * *

## API

| Type | Description |
|---|---|
| `DustDissolveController(config)` | `fire()` runs the effect, `reset()` puts the view back, `time` is the clock, `isActive`, `finished()` |
| `DustDissolveScope(controller \| controllers, modifier, content)` | Container that draws the dust over its content and runs the frame clock. Wrap the screen (or the area the dust flies across) |
| `Modifier.dustSource(controller)` | The view that dissolves. The dust is born here. It keeps its place in the layout |
| `Modifier.dustTarget(controller?)` | Where `FlowToTarget` dust lands (centre of the bounds). With a controller it is that one's own target; without, the shared one |
| `DustDissolveConfiguration` | Direction, motion, shape, timing, particle count, dot size, palette, sparkles |

### Props

```kotlin
val dust = remember {
    DustDissolveController(
        DustDissolveConfiguration(
            particleCount = 2400,
            palette = listOf(Color.Cyan, Color.White),
            dissolveEnd = 1.4,
        )
    )
}
```

| Prop | Type | Default | Description |
|---|---|---|---|
| `shimmer` | `Boolean` | `true` | A light line crosses the view before it dissolves |
| `shimmerStart` / `shimmerEnd` | `Double` | 0.28 / 0.62 | The shimmer line crossing the view |
| `direction` | `DustDissolveDirection` | `LeftToRight` | `LeftToRight`, `RightToLeft`, `TopToBottom`, `BottomToTop`, `CenterOut` |
| `motion` | `DustDissolveMotion` | `FlowToTarget` | `FlowToTarget`, `Drift(angleDegrees, distance)`, `Burst(distance)` |
| `shape` | `DustDissolveShape` | `Rectangle` | `Ellipse` for round views |
| `dissolveStart` / `dissolveEnd` | `Double` | 0.55 / 1.10 | The view eaten away |
| `flightStart` | `Double` | 0.95 | When the cloud starts moving |
| `flightStagger` | `Double` | 0.15 | Random extra delay per dot |
| `flightDurationMin` / `Max` | `Double` | 0.8 / 0.95 | Flight time per dot |
| `total` | `Double` | 3.0 | Length of the whole sequence |
| `particleCount` | `Int` | 1100 | Number of dots |
| `dotSizeMin` / `Max` | `Float` | 1.8 / 3.2 | Dot diameter, in dp |
| `sparkleEvery` | `Int` | 60 | Every n-th dot flares into a sparkle (`0` = off) |
| `palette` | `List<Color>` | pastel | Dot colors |
| `seed` | `Long` | 7 | Random seed (give each view its own for variety) |
| `arrival` | `Double` | read-only | When the first dots reach the target |

### Presets

| Preset | Look |
|---|---|
| `DustDissolveConfiguration.Coupon` | The original: shimmer, left → right, flows to a target |
| `.Snap` | No shimmer, left → right, the dust blows up and to the right |
| `.Dismiss` | Left → right, carried off to the right |
| `.Fall` | Top → bottom, the dust falls |
| `.Burst` | From the centre, round, the dust bursts outward |

Tweak one with `.copy(...)`, e.g. `DustDissolveConfiguration.Fall.copy(particleCount = 700, seed = 3)`.

### Many views at once

```kotlin
val dusts = remember { List(9) { DustDissolveController(DustDissolveConfiguration.Snap.copy(seed = it.toLong())) } }

DustDissolveScope(dusts) {
    LazyTiles { i -> Tile(Modifier.dustSource(dusts[i])) }   // each tile has its own controller
}
```

* * *

## Example app

Open the project in Android Studio and use the Compose preview, or call `DustDissolveExamples()` / `DustDissolveExamplesLight()` from an activity.

| Demo | Shows |
|---|---|
| Coupons | Tap one: it shimmers, then the dust flows into the "Applied" pill |
| Hide balance | The amount turns to dust, dots take its place |
| Hide password | The visible text turns to dust, dots take its place |
| Disappearing messages | Bubbles blow away toward the side they sit on |

Nothing in the layout moves: a dissolving view keeps its place.

Source: [`dustdissolve-demo/src/main/java/com/repgem/dustdissolve/demo/Examples.kt`](./dustdissolve-demo/src/main/java/com/repgem/dustdissolve/demo/Examples.kt)

* * *

## How it works

- **The shader** is a `RenderEffect` (AGSL) on the coupon's layer: an optional slanted shimmer band, then a dissolve driven by a smooth erosion field (oriented by `direction`). The edge is dithered: each pixel is fully there or fully gone, so it breaks into dots in the view's own colors.
- **The dust** is a Compose `Canvas` over the scope's content. Each dot is born at the moment the shader removes the pixel under it (same field, same threshold), drifts a little while the cloud hangs, then flows along a Bézier arc to the target, drifts, or bursts, depending on `motion`.
- **The clock** is the frame clock (`withFrameNanos`). It only runs while a sequence is active. Because `time` is Compose state read in draw and layer lambdas, only drawing is invalidated.

> If you change the erosion field, change it in both the AGSL string (`DustDissolveShader.kt`) and `DustDissolveParticles.kt`.

* * *

## ⭐ Support

If you find this useful, give this catalog a star.

## Contributing

Issues and PRs are welcome.

## License

MIT © [ismnoiet](https://github.com/ismnoiet)
