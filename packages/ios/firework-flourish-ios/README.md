<p align="center">
  <a href="https://media.repgem.com/firework-flourish-ios/demo.mp4"><img src="https://media.repgem.com/firework-flourish-ios/poster.jpg" width="240" alt="FireworkFlourish iOS demo (click to play)" /></a>
</p>

<h1 align="center">FireworkFlourish</h1>

Fireworks for any SwiftUI view - Continuous or one-shot, with built-in styles and palettes.

[![version](https://img.shields.io/badge/version-1.0.0-blue.svg)](#)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![platform](https://img.shields.io/badge/platform-iOS%2017%2B%20%7C%20macOS%2014%2B%20%7C%20visionOS-lightgrey.svg)](#installation)

* * *

## ✨ Features

- 🧩 **Wrap anything**: cards, banners, buttons, calendar cells or a whole screen
- 🎆 **Continuous or one-shot**: `FireworkFlourish(...)` runs while it is on screen, `.fireworkFlourish(trigger:)` plays once per trigger
- 🎨 **13 presets and 9 palettes**: card, subtle, milestone, grand, tap, romance, neon, embers, sparkle, pastel, new year, like, frost
- 🔧 **Every knob is a parameter**: interval, particle count, spread, gravity, fade time, where bursts happen
- 🪶 **Stateless**: no stored particles. Each rocket and particle is computed from its index, so nothing is allocated between frames
- 🎯 **State-driven**: drive `active` from anything, idle layers pause their timeline and cost nothing
- 🌓 **Dark and light surfaces**
- ♿ **Reduce Motion aware**: the one-shot plays a brief still fade instead, the continuous layer draws nothing

* * *

## Installation

**Swift Package Manager**: Xcode → *File → Add Package Dependencies…* and enter
`https://github.com/ismnoiet/firework-flourish-ios`, or in `Package.swift`:

```swift
.package(url: "https://github.com/ismnoiet/firework-flourish-ios", from: "1.0.0")
```

then add the `FireworkFlourish` product to your target and `import FireworkFlourish`.

**CocoaPods** (experimental)

```ruby
pod 'FireworkFlourish', '~> 1.0'
```

### Requirements

| Platform | Minimum |
|---|---|
| iOS | 17.0 |
| macOS | 14.0 |
| visionOS | 1.0 |
| Swift / Xcode | 5.9 / 15 |

Also available for Jetpack Compose: [firework-flourish-android](https://github.com/ismnoiet/firework-flourish-android), with the same names, parameter order and defaults.

* * *

## Quick start

Continuous fireworks inside a card (clip the layer to the shape that should hold it):

```swift
import FireworkFlourish

struct BirthdayCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Birthday · Found in Contacts").font(.caption)
            Text("Today, Mar 13").font(.largeTitle.bold())
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .overlay { FireworkFlourish(.card) }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
```

One-shot celebration each time a value changes:

```swift
card
    .fireworkFlourish(trigger: levelUps, duration: 2, style: .milestone)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
```

Continuous while a condition holds:

```swift
row.fireworkFlourish(active: isBirthdayToday, style: .subtle)
```

Fireworks add light, so put them on a dark surface.

* * *

### Light surfaces

The default look adds light, so it suits dark surfaces. On a light surface, switch to the light look: normal blending, deeper colors, no white glow.

```swift
card
    .overlay { FireworkFlourish(.card) }
    .fireworkLightBackground()
```

## Props

`FireworkFlourish(_:active:)` (layer), `.fireworkFlourish(active:style:)` (continuous modifier) and `.fireworkFlourish(trigger:duration:style:)` (one-shot modifier):

| Prop | Type | Default | Description |
|---|---|---|---|
| `style` | `FireworkStyle` | `.card` | Preset or your own, see below |
| `active` | `Bool` | `true` | Fades the layer in/out, then pauses the timeline so an idle layer costs nothing |
| `trigger` | `Equatable` | n/a | One-shot only. Fireworks play each time it changes |
| `duration` | `TimeInterval` | `2.0` | One-shot only. How long rockets keep launching; particles then fade out on their own |

* * *

## Styles

A `FireworkStyle` is a plain struct. Use a preset, or build one:

```swift
FireworkStyle(interval: 0.2, particles: 90, maxRadius: 60, palettes: FireworkPalette.gold)
```

| Field | Default | Description |
|---|---|---|
| `interval` | `0.30` | Seconds between rockets |
| `rocketTime` | `0.34` | Rise duration of the rocket trail |
| `flashTime` | `0.30` | Glow ball before the burst |
| `burstLife` | `2.8` | Seconds the particles take to fade out |
| `particles` | `64` | Particles per burst |
| `maxRadius` | `24` | Burst spread in points |
| `gravity` | `5` | Downward drift in pt/s². Negative makes particles rise |
| `showRockets` | `true` | Draw the thin rocket trail |
| `yRange` / `xRange` | `0.08...0.78` / `0.04...0.96` | Where bursts happen, as a fraction of height / width |
| `palettes` | `FireworkPalette.rainbow` | Color pairs; every burst picks one pair |

### Presets

| Preset | Look |
|---|---|
| `.card` | Small bursts inside a card. The default |
| `.subtle` | Quiet and sparse, for banners and list rows |
| `.milestone` | Gold sparkle |
| `.grand` | Full-screen celebration |
| `.tap` | Tight burst for button taps |
| `.romance` | Pink bursts for anniversaries |
| `.neonPop` | Fast, saturated, for scoreboards and games |
| `.embers` | Embers rising instead of falling, no rockets |
| `.sparkle` | Tiny twinkles, great as a "today" marker |
| `.pastelBloom` | Wide, slow, pastel |
| `.newYear` | Big finale for countdowns |
| `.like` | Tiny burst centred on a button (use inside a ~150pt square) |
| `.frost` | Cold and calm |

`FireworkStyle.all` lists every preset with its name.

### Palettes

`FireworkPalette.rainbow`, `.gold`, `.success`, `.pink`, `.neon`, `.ice`, `.fire`, `.pastel`, `.mono`, or your own `[(Color, Color)]`:

```swift
FireworkStyle(palettes: [(.cyan, .mint), (.white, .blue)])
```

`FireworkPalette.all` lists every palette with its name.

* * *

## Accessibility

When Reduce Motion is on, nothing moves. The one-shot modifier plays a brief still fade (a frozen frame of bursts, about half a second) so the moment is still acknowledged; pass `reduceMotion: .none` to draw nothing. The continuous `FireworkFlourish(...)` layer draws nothing. Haptics are up to your app, so pair the celebration with feedback and text:

```swift
.fireworkFlourish(trigger: taps, style: .tap)            // reduceMotion: .fade by default
.sensoryFeedback(.success, trigger: taps)
```

* * *

## Example app

Open `Package.swift` in Xcode, choose the `FireworkFlourishDemo` scheme and use the preview, or show `FireworkFlourishExamples()` from an app (`FireworkFlourishExamplesLight()` for the light theme).

| Demo | Shows |
|---|---|
| Anniversary card | Continuous, romance palette |
| Scoreboard goal | Neon one-shot per goal |
| Achievement toast | Celebrates inside a capsule while it is on screen |
| New Year countdown | 3 → 0 then a full-stage finale |
| Calendar today sparkle | Quiet `.sparkle` in a cell |
| Style lab | Every preset and palette with live sliders |

Source: [`Sources/FireworkFlourishDemo/Examples.swift`](./Sources/FireworkFlourishDemo/Examples.swift)

* * *

## How it works

Everything is drawn with one SwiftUI `Canvas` driven by a `TimelineView`. Each rocket's position, color and every particle's angle, reach and twinkle come from a hash of its index, so no particle state is stored and the loop never repeats a fixed clip. A rocket is a thin trail, then a white glow ball, then particles that fly out fast, drift with gravity, twinkle and fade. Glows and dots use additive blending, which is why fireworks look best on dark surfaces. A one-shot modifier starts a fresh seed each time, so two celebrations never look the same.

### Performance

Drawing is CPU-side `Canvas` work: roughly 500 to 800 dots per frame for the card-sized presets, several thousand for `.grand` and `.newYear`. That is fine for cards, banners, buttons and calendar cells; for a full-screen finale on older devices, lower `particles` or raise `interval`.

* * *

## ⭐ Support

If you find this useful, give this catalog a star.

## Contributing

Issues and PRs are welcome.

## License

MIT © [ismnoiet](https://github.com/ismnoiet)
