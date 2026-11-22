<p align="center">
  <a href="https://media.repgem.com/sticky-range-slider-android/demo.mp4"><img src="https://media.repgem.com/sticky-range-slider-android/poster.jpg" width="240" alt="StickyRangeSlider Android demo (click to play)" /></a>
</p>

<h1 align="center">StickyRangeSlider</h1>

A sticky, gooey range slider for Jetpack Compose: value pills that spring after your finger, fuse into one pill when they meet, and pull apart again.

* * *

## ✨ Features

- 🫧 **Gooey merge**: two handles that meet fuse into one pill (`$185 – 240`) and split again with a stretchy neck
- 🧲 **Sticky handles**: the value pill springs after your finger and sticks to the track ends
- 👆 **Tap to move**: tap the track and the nearest handle glides there
- 🔢 **Rolling digits**: values roll up and down as you drag
- 1️⃣ **One handle or two**: `StickyRangeSlider(value, ...)` or `StickyRangeSlider(lower, upper, ...)`
- 🎨 **Your colors**: dark and light presets, or `StickySliderStyle.accent(color)` for any color
- ⏱️ **Tunable motion**: follow, glide, merge and digit timing as parameters
- 📳 **Haptics**: a tick on every step and a tap when the pills fuse
- ♿ **Accessible**: TalkBack slider or increase / decrease actions, instant moves when animations are off
- 🔋 **Free when idle**: the frame loop stops as soon as everything is at rest
- 📱 **Works on Android 7.0+**: the gooey fuse runs on Android 12+, older versions draw plain pills that overlap

* * *

## Installation

**JitPack**: add the repository, then the dependency (check the build page on
[jitpack.io](https://jitpack.io/#ismnoiet/sticky-range-slider-android) for the exact coordinates of each tag):

```kotlin
// settings.gradle.kts
dependencyResolutionManagement { repositories { maven("https://jitpack.io") } }

// app/build.gradle.kts
dependencies { implementation("com.github.ismnoiet.sticky-range-slider-android:stickyrangeslider:1.0.0") }
```

**Local Maven**: `./gradlew :stickyrangeslider:publishToMavenLocal`, add `mavenLocal()`, then
`implementation("com.github.ismnoiet:sticky-range-slider-android:1.0.0")`.

**As a module**: copy `stickyrangeslider/` into your project and `include(":stickyrangeslider")`.

### Requirements

| Platform | Minimum |
|---|---|
| Android | 7.0 (API 24) |
| Gooey fuse (RenderEffect) | 12 (API 31), older versions draw plain overlapping pills |
| Kotlin / Compose compiler | 1.9.22 / 1.5.10 |
| Jetpack Compose | BOM 2024.02.00 |

* * *

## Quick start

```kotlin
import com.repgem.stickyrangeslider.*

@Composable
fun PriceFilter() {
    var lower by remember { mutableIntStateOf(85) }
    var upper by remember { mutableIntStateOf(240) }

    StickyRangeSlider(
        lower = lower,
        upper = upper,
        onRangeChange = { lo, hi -> lower = lo; upper = hi },
        bounds = 20..400,
        step = 5,
    )
}
```

One handle, other units:

```kotlin
StickyRangeSlider(value, { value = it }, bounds = 1..50, step = 1, prefix = "", suffix = " km")
StickyRangeSlider(lower, upper, onChange, bounds = 40..200, prefix = "$", suffix = "k")   // $85k – 140k
```

On a dark surface, or in your own color:

```kotlin
StickyRangeSlider(lower, upper, onChange, style = StickySliderStyle.paper)
StickyRangeSlider(lower, upper, onChange, style = StickySliderStyle.accent(Color.Blue))
```

React to dragging:

```kotlin
StickyRangeSlider(lower, upper, onChange, onEditingChanged = { editing ->
    if (!editing) search(lower..upper)
})
```

### Coming from iOS?

The names, parameter order and defaults match [sticky-range-slider-ios](https://github.com/ismnoiet/repgem-catalog/tree/main/packages/ios/sticky-range-slider-ios). Compose's value + callback replaces SwiftUI's bindings; everything else lines up:

```swift
// iOS
StickyRangeSlider(lower: $lower, upper: $upper, bounds: 20...400, step: 5, style: .paper)
```

```kotlin
// Android
StickyRangeSlider(lower, upper, { lo, hi -> lower = lo; upper = hi }, bounds = 20..400, step = 5, style = StickySliderStyle.paper)
```

* * *

## Props

Both overloads share these (the two-handle one takes `lower`, `upper`, `onRangeChange` instead of `value`, `onValueChange`):

| Prop | Type | Default | Description |
|---|---|---|---|
| `value` / `lower`, `upper` | `Int` | n/a | The selected value(s) |
| `onValueChange` / `onRangeChange` | `(Int) -> Unit` / `(Int, Int) -> Unit` | n/a | Called as the value changes |
| `modifier` | `Modifier` | `Modifier` | Standard Compose `Modifier` |
| `bounds` | `IntRange` | `20..400` | Smallest and largest value |
| `step` | `Int` | `5` | Values snap to multiples of this |
| `prefix` | `String` | `"$"` | Text before a value |
| `suffix` | `String` | `""` | Text after a value |
| `style` | `StickySliderStyle` | `StickySliderStyle.ink` | Colors, see below |
| `timing` | `StickyTiming` | `StickyTiming()` | Spring and digit timing |
| `haptics` | `Boolean` | `true` | Step tick and fuse tap |
| `accessibilityName` | `String` | `"Value"` / `"Range"` | TalkBack label |
| `onEditingChanged` | `(Boolean) -> Unit` | no-op | Called with `true` when a drag starts and `false` when it ends |

> The slider fills the width you give it and is 72 dp tall. The track is inset by 30 dp on each side so the end pills never clip. All lengths are in dp, so it looks the same on every density.

* * *

## Styles

| Style | Look |
|---|---|
| `StickySliderStyle.ink` | Near-black pills and track, for light surfaces (default) |
| `StickySliderStyle.paper` | Near-white pills and track, for dark surfaces |
| `StickySliderStyle.accent(color)` | A colored pill with white text, track in the same color |

Or build your own:

```kotlin
val brand = StickySliderStyle(
    pill = Color(0xFF4F46E5), label = Color.White,
    track = Color(0x334F46E5), trackFill = Color(0xFF4F46E5),
    shadow = Color(0x664F46E5),
)
```

* * *

## Timing

```kotlin
StickyRangeSlider(value, onChange, timing = StickyTiming(follow = 0.45, glide = 0.6))   // heavy, lazy handles
```

| `StickyTiming` field | Default | Description |
|---|---|---|
| `follow` | `0.22` | Seconds for a pill to catch up with your finger |
| `glide` | `0.37` | Seconds for a pill to slide to a tapped spot |
| `merge` | `0.26` | Seconds for two pills to fuse or split |
| `digitRoll` | `0.28` | Seconds for the digits to roll |

All springs are slightly under-damped, so pills settle with a tiny give instead of stopping dead.

* * *

## How it behaves

- **Fusing.** When the two pills are within about 48 dp of each other they merge into one. They separate again once they are about 58 dp apart; the gap between the two numbers stops the pair flickering while you hover around the threshold.
- **Grabbing a fused pill.** Touch its left half to move the lower value, its right half to move the upper one.
- **Tap the track.** The nearest handle glides there. Keep your finger down and drag to carry on from that spot.
- **Handles can't cross.** They stop one `step` apart.

> Inside a scrolling column, a vertical swipe that starts on the slider is taken by the slider. Leave some space around it.

* * *

## Example app

The `stickyrangeslider-demo` module holds the examples. Open the project in Android Studio and use the Compose previews, or show `StickyRangeSliderExamples()` / `StickyRangeSliderExamplesLight()` from an activity.

| Demo | Shows |
|---|---|
| Price per night | Two handles, a histogram that follows them, live result count |
| One handle | `value` with a `km` suffix |
| Salary, Age | Other units and steps |
| Your colors | `StickySliderStyle.accent` in blue, green and orange |
| Lazy follow | Slower `StickyTiming` |

Source: [`DemoSupport.kt`](./stickyrangeslider-demo/src/main/java/com/repgem/stickyrangeslider/demo/DemoSupport.kt), [`Examples.kt`](./stickyrangeslider-demo/src/main/java/com/repgem/stickyrangeslider/demo/Examples.kt), [`ExamplesLight.kt`](./stickyrangeslider-demo/src/main/java/com/repgem/stickyrangeslider/demo/ExamplesLight.kt)

* * *

## How it works

Each handle is a rounded rectangle drawn on a Compose `Canvas` layer with a `RenderEffect`: a blur followed by an alpha threshold, the classic "goo" trick. Shapes that are close blur into each other and the threshold turns the overlap back into one crisp outline. A thin bridge between the two pills makes the stretchy neck. The labels are separate composables on top, so digits can roll like an odometer.

Positions come from a small spring simulation, one spring per handle plus one for the fuse amount, stepped by a frame loop. Following your finger, gliding to a tap and merging are the same simulation with different stiffness. The result is read in the draw and layout phases, so nothing recomposes while it moves, and the loop stops once everything is at rest.

On Android below 12, where `RenderEffect` is not available, the pills are drawn plain: the same geometry and springs, but the overlap is a simple union without the stretchy neck or the drop shadow.

* * *

## ⭐ Support

If you find this useful, give this catalog a star.

## Contributing

Issues and PRs are welcome.

## License

MIT © [ismnoiet](https://github.com/ismnoiet)
