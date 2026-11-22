<p align="center">
  <a href="https://media.repgem.com/dragable-cards-ios/demo.mp4"><img src="https://media.repgem.com/dragable-cards-ios/poster.jpg" width="240" alt="DragableCards iOS demo (click to play)" /></a>
</p>

<h1 align="center">DragableCards</h1>

A Trello-style board for SwiftUI. Long-press a card, drag it between columns, and watch the others slide out of the way as it snaps into place.

* * *

## ✨ Features

- 🧩 **Bring your own card**: any SwiftUI view, the board only adds the motion
- ✋ **Lift, hover, drop**: long-press lifts the card with a tilt and shadow, an empty slot opens where it will land, and a near critically damped spring snaps it into place
- 🧭 **Forgiving targeting**: the nearest column to your finger wins, so there are no dead zones between columns
- ↔️ **Auto-scroll**: entering a column that is partly off screen scrolls it fully into view, and holding near an edge brings in the next column
- ⚡ **Smooth by design**: the finger-follow position lives in its own tiny observable, so dragging never re-renders the board
- 🎛 **Tunable**: long-press delay, three springs, lift scale/tilt/shadow and the column look
- 📳 **Haptics** on lift, on every slot change and on drop
- 🌓 **Dark and light surfaces**

* * *

## Installation

**Swift Package Manager**: Xcode → *File → Add Package Dependencies…* and enter
`https://github.com/ismnoiet/dragable-cards-ios`, or in `Package.swift`:

```swift
.package(url: "https://github.com/ismnoiet/dragable-cards-ios", from: "1.0.0")
```

then add the `DragableCards` product to your target and `import DragableCards`.

**CocoaPods** (experimental)

```ruby
pod 'DragableCards', '~> 1.0'
```

### Requirements

| Platform | Minimum |
|---|---|
| iOS | 17.0 |
| macOS | 14.0 (no haptics) |
| visionOS | 1.0 (no haptics) |
| Swift / Xcode | 5.9 / 15 |

* * *

## Quick start

```swift
import DragableCards

struct Task: Identifiable {
    let id: Int
    let title: String
}

struct BoardView: View {
    @StateObject private var state = DragBoardState([
        [Task(id: 1, title: "Design"), Task(id: 2, title: "Build")],   // To do
        [Task(id: 3, title: "Ship")],                                  // Doing
        [],                                                            // Done
    ])
    private let titles = ["To do", "Doing", "Done"]

    var body: some View {
        DragBoard(state: state) { index, tasks in
            Text("\(titles[index]) (\(tasks.count))")
        } card: { task in
            Text(task.title)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
        }
        .onCardMove { task, from, to, index in /* persist the move */ }
        .frame(height: 430)
    }
}
```

The same `card` view draws the floating copy while you drag, so what you see lifting is exactly the card.

Read the current lists any time with `state.columns`, and replace them with `state.updateColumns(...)`. Items only need to be `Identifiable`.

* * *

## Props

### `DragBoard`

| Prop | Type | Default | Description |
|---|---|---|---|
| `state` | `DragBoardState<Item>` | n/a | The cards of every column. Create it with `@StateObject` |
| `columnWidth` | `CGFloat` | `280` | Width of each column |
| `columnSpacing` | `CGFloat` | `12` | Gap between columns |
| `cardSpacing` | `CGFloat` | `8` | Gap between cards |
| `contentPadding` | `CGFloat` | `16` | Padding around the columns, inside the horizontal scroll |
| `columnStyle` | `ColumnStyle` | `ColumnStyle()` | The container around each column |
| `appearance` | `DragAppearance` | `DragAppearance()` | The lifted card and the empty slot |
| `timing` | `DragTiming` | `DragTiming()` | Long-press delay and springs |
| `header` | `(Int, [Item]) -> View` | none | Drawn at the top of each column with its index and items |
| `card` | `(Item) -> View` | n/a | Draws one card |

Give the board a bounded height (for example `.frame(height: 430)`).

### `.onCardMove(_:)`

Call it directly on the `DragBoard`, before other modifiers. It runs after a card lands with the item, its old column, its new column and its index there.

### `DragTiming`

| Field | Default | Description |
|---|---|---|
| `longPress` | `0.15` | Hold time before a card lifts, in seconds |
| `lift` | `.spring(response: 0.2, dampingFraction: 0.72)` | Scale, tilt and shadow ease in |
| `shuffle` | `.spring(response: 0.22, dampingFraction: 0.86)` | Neighbours sliding aside |
| `drop` | `.interpolatingSpring(stiffness: 600, damping: 49)` | The snap into the slot (no overshoot) |
| `dropDuration` | `0.25` | How long the drop runs before the lists update |
| `edgeScrollDelay` | `0.7` | Minimum gap between automatic scrolls |

### `DragAppearance`

| Field | Default | Description |
|---|---|---|
| `liftScale` | `1.04` | Scale of the lifted card |
| `liftTilt` | `4` | Tilt in degrees |
| `liftShadow` / `liftShadowOpacity` | `12` / `0.28` | Shadow of the lifted card |
| `cornerRadius` | `6` | Match your card's corner radius so the empty slot has the same shape |
| `placeholderFill` / `placeholderBorder` | soft gray | The empty slot |

### `ColumnStyle`

| Field | Default | Description |
|---|---|---|
| `background` | `#F6F8FA` | Column fill |
| `border` | `#D0D7DE` | Hairline border |
| `cornerRadius` | `10` | Column corner radius |
| `padding` | `12` | Space between the column edge and its content |

* * *

## Example app

The `DragableCardsDemo` target holds the examples. Open `Package.swift` in Xcode, pick the `DragableCardsDemo` scheme and use the canvas, or show `DragableCardsExamples()` / `DragableCardsExamplesLight()` from an app.

| Demo | Shows |
|---|---|
| Project board | Four status columns, live count and estimate pills, avatars, GitHub-style cards |
| Hiring pipeline | Rich cards, a live average per column and a toast driven by `onCardMove` |
| Music queue | A live equalizer that keeps moving while the card is lifted, totals that update as songs move |
| Weekly meals | Five narrow columns: the board scrolls sideways as you drag, daily kcal updates live |
| Trip planner | Cards that grow with their content, an Ideas column to pull from, and a day that turns amber when overbooked |

Both pages share the same layout, one dark and one light. It is the same set of demos as the [Android package](../dragable-cards-android).

Source: [`Examples.swift`](./Sources/DragableCardsDemo/Examples.swift), [`ExamplesLight.swift`](./Sources/DragableCardsDemo/ExamplesLight.swift), and the boards in [`Boards.swift`](./Sources/DragableCardsDemo/Boards.swift), [`BoardsPlanning.swift`](./Sources/DragableCardsDemo/BoardsPlanning.swift), [`BoardsMedia.swift`](./Sources/DragableCardsDemo/BoardsMedia.swift)

* * *

## How it works

Long-pressing a card starts the drag. The card stays in its column, collapsed to zero height so its gesture keeps running, while a copy follows your finger above everything else. A slot opens in the hovered column at the position the finger is over, and the cards below it slide down with a spring.

Targeting is judged against each card's laid-out frame rather than its in-flight animated position, so slots don't jitter while neighbours are still moving.

On release the card is drawn inside its slot, offset to exactly where the finger left it, and one spring brings its offset, tilt, scale and shadow to rest together. Because it lives in the layout while it lands, scrolling or neighbours settling can't throw it off. Only then is the list updated.

* * *

## Development

```bash
./scripts/check.sh             # what CI runs: build library and demo for iOS, run the tests
./scripts/check.sh --fast      # unit tests only
./scripts/test.sh DragMath     # only the tests matching a name
./scripts/run-testbed.sh       # build ios-testbed (with these demos) and run it in a simulator
```

The decisions of the interaction (which column, which slot, how a move changes the lists) are pure functions in `DragMath.swift`, covered by `DragMathTests`, including a regression test that moving up and moving down swap at the same distance. `DragBoardStateTests` covers the state.

* * *

## ⭐ Support

If you find this useful, give this catalog a star.

## Contributing

Issues and PRs are welcome.

## License

MIT © [ismnoiet](https://github.com/ismnoiet)
