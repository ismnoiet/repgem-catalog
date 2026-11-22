<p align="center">
  <a href="https://media.repgem.com/sticky-range-slider-ios/demo.mp4"><img src="https://media.repgem.com/sticky-range-slider-ios/poster.jpg" width="240" alt="StickyRangeSlider demo (click to play)" /></a>
</p>

<h1 align="center">StickyRangeSlider</h1>

A sticky, gooey range slider for SwiftUI: value pills that spring after your finger, fuse into one pill when they meet, and pull apart again.

* * *

## ✨ Features

- 🫧 **Gooey merge**: two handles that meet fuse into one pill (`$185 – 240`) and split again with a stretchy neck
- 🧲 **Sticky handles**: the value pill springs after your finger and sticks to the track ends
- 👆 **Tap to move**: tap the track and the nearest handle glides there
- 🔢 **Rolling digits**: values count up and down as you drag
- 1️⃣ **One handle or two**: `StickyRangeSlider(value:)` or `StickyRangeSlider(lower:upper:)`
- 🎨 **Your colors**: dark and light presets, or `.accent(_:)` for any color
- ⏱️ **Tunable motion**: follow, glide, merge and digit timing as parameters
- 📳 **Haptics**: a tick on every step and a soft tap when the pills fuse
- ♿ **Accessible**: VoiceOver sliders for each handle, Reduce Motion shows instant moves
- 🔋 **Free when idle**: the frame loop pauses as soon as everything is at rest

* * *

## Installation

**Swift Package Manager**: Xcode → *File → Add Package Dependencies…* and enter
`https://github.com/ismnoiet/sticky-range-slider-ios`, or in `Package.swift`:

```swift
.package(url: "https://github.com/ismnoiet/sticky-range-slider-ios", from: "1.0.0")
```

then add the `StickyRangeSlider` product to your target and `import StickyRangeSlider`.

**CocoaPods** (experimental)

```ruby
pod 'StickyRangeSlider', '~> 1.0'
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
import StickyRangeSlider

struct PriceFilter: View {
    @State private var lower = 85
    @State private var upper = 240

    var body: some View {
        StickyRangeSlider(lower: $lower, upper: $upper, bounds: 20...400, step: 5)
    }
}
```

One handle, other units:

```swift
StickyRangeSlider(value: $distance, bounds: 1...50, step: 1, prefix: "", suffix: " km")
StickyRangeSlider(lower: $min, upper: $max, bounds: 40...200, prefix: "$", suffix: "k")   // $85k – 140k
```

On a dark surface, or in your own color:

```swift
StickyRangeSlider(lower: $min, upper: $max, style: .paper)
StickyRangeSlider(lower: $min, upper: $max, style: .accent(.blue))
```

React to dragging:

```swift
StickyRangeSlider(lower: $min, upper: $max) { isEditing in
    if !isEditing { search(min...max) }
}
```

* * *

## Props

Both initializers share these (the two-handle one takes `lower:` and `upper:` instead of `value:`):

| Prop | Type | Default | Description |
|---|---|---|---|
| `value` / `lower`, `upper` | `Binding<Int>` | n/a | The selected value(s) |
| `bounds` | `ClosedRange<Int>` | `20...400` | Smallest and largest value |
| `step` | `Int` | `5` | Values snap to multiples of this |
| `prefix` | `String` | `"$"` | Text before a value |
| `suffix` | `String` | `""` | Text after a value |
| `style` | `StickySliderStyle` | `.ink` | Colors, see below |
| `timing` | `StickyTiming` | `.default` | Spring and digit timing |
| `haptics` | `Bool` | `true` | Selection tick and fuse tap |
| `accessibilityName` | `String` | `"Value"` / `"Range"` | VoiceOver label |
| `onEditingChanged` | `(Bool) -> Void` | no-op | Called with `true` when a drag starts and `false` when it ends |

> The slider fills the width you give it and is 72 pt tall. The track is inset by 30 pt on each side so the end pills never clip.

* * *

## Styles

| Style | Look |
|---|---|
| `.ink` | Near-black pills and track, for light surfaces (default) |
| `.paper` | Near-white pills and track, for dark surfaces |
| `.accent(_:)` | A colored pill with white text, track in the same color |

Or build your own:

```swift
let brand = StickySliderStyle(
    pill: .indigo, label: .white,
    track: .indigo.opacity(0.2), trackFill: .indigo,
    shadow: .indigo.opacity(0.4)
)
```

* * *

## Timing

```swift
StickyRangeSlider(value: $v, timing: StickyTiming(follow: 0.45, glide: 0.6))   // heavy, lazy handles
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

- **Fusing.** When the two pills are within about 48 pt of each other they merge into one. They separate again once they are about 58 pt apart; the gap between the two numbers stops the pair flickering while you hover around the threshold.
- **Grabbing a fused pill.** Touch its left half to move the lower value, its right half to move the upper one.
- **Tap the track.** The nearest handle glides there. Keep your finger down and drag to carry on from that spot.
- **Handles can't cross.** They stop one `step` apart.

> Inside a `ScrollView`, a vertical swipe that starts on the slider is taken by the slider. Leave some space around it.

* * *

## Example app

Open `Package.swift` in Xcode, choose the `StickyRangeSliderDemo` scheme and use the preview, or show `StickyRangeSliderExamples()` (dark) or `StickyRangeSliderExamplesLight()` from an app.

| Demo | Shows |
|---|---|
| Price per night | Two handles, a histogram that follows them, live result count |
| One handle | `value:` with a `km` suffix |
| Salary, Age | Other units and steps |
| Your colors | `.accent(_:)` in blue, green and orange |
| Lazy follow | Slower `StickyTiming` |

Source: [`DemoSupport.swift`](./Sources/StickyRangeSliderDemo/DemoSupport.swift), [`Examples.swift`](./Sources/StickyRangeSliderDemo/Examples.swift), [`ExamplesLight.swift`](./Sources/StickyRangeSliderDemo/ExamplesLight.swift)

* * *

## How it works

Each handle is a rounded rectangle drawn on a `Canvas` with a blur followed by an alpha threshold, the classic "goo" trick: shapes that are close blur into each other and the threshold turns the overlap back into one crisp outline. A thin bridge between the two pills makes the stretchy neck. The labels are ordinary `Text` views on top, so digits can roll with `contentTransition(.numericText)`.

Positions come from a small spring simulation stepped by a `TimelineView`, one spring per handle plus one for the fuse amount. Following your finger, gliding to a tap and merging are the same simulation with different stiffness. The timeline pauses once everything is at rest, and Reduce Motion skips the springs.

* * *

## ⭐ Support

If you find this useful, give this catalog a star.

## Contributing

Issues and PRs are welcome.

## License

MIT © [ismnoiet](https://github.com/ismnoiet)
