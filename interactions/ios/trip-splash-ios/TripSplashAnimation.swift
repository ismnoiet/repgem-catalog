import SwiftUI

// Trip.com splash: the logo's letters get swallowed by the orange dot, the dot stretches into a
// streak, and your screen is revealed by an expanding circle. Tap to replay.
//
// Usage:
//     TripSplashView { YourHomeScreen() }     // reveals your own screen
//     TripSplashView()                        // reveals a neutral placeholder

// MARK: - Palette

enum SplashPalette {
    static let splash = Color(red: 0.137, green: 0.196, blue: 0.953)
    static let blue = Color(red: 0.169, green: 0.302, blue: 0.953)
    static let orange = Color(red: 1.0, green: 0.70, blue: 0.0)
    static let tint = Color(red: 0.93, green: 0.95, blue: 1.0)
}

// MARK: - Keyframes
// Each table below sets the timing and position of one part of the animation.
// t is in seconds; x and size values are fractions of the screen width (674px = 1.0).

typealias SplashKey = (t: Double, v: Double)

enum SplashTrack {
    /// Piecewise-linear interpolation, clamped at both ends.
    static func value(_ t: Double, _ keys: [SplashKey]) -> Double {
        guard let first = keys.first, let last = keys.last else { return 0 }
        if t <= first.t { return first.v }
        if t >= last.t { return last.v }
        for i in 1..<keys.count {
            let a = keys[i - 1]
            let b = keys[i]
            if t <= b.t {
                let u = (t - a.t) / (b.t - a.t)
                return a.v + (b.v - a.v) * u
            }
        }
        return last.v
    }
}

enum SplashTime {
    static let logoStart: Double = 0.55   // letters start shrinking
    static let logoEnd: Double = 0.80     // logo fully collapsed into the dot
    static let total: Double = 1.4
}

enum SplashKeys {
    // Orange dot diameter
    static let dot: [SplashKey] = [
        (0, 0.0173), (0.5, 0.0173), (0.55, 0.0312), (0.6, 0.0341), (0.683, 0.0341), (0.7, 0.0312), (0.717, 0.0282), (0.733, 0.0134), (0.8, 0.0134)
    ]
    // Streak head (right end)
    static let head: [SplashKey] = [
        (0.8, 0.506), (0.819, 0.509), (0.829, 0.513), (0.847, 0.533), (0.856, 0.564), (0.875, 0.564), (0.884, 0.583), (0.894, 0.583), (0.903, 0.626), (0.912, 0.651), (0.931, 0.705), (0.95, 0.734), (0.969, 0.764), (0.979, 0.794), (0.997, 0.826), (1.015, 0.929), (1.032, 0.997), (1.07, 1.08), (1.13, 1.12), (1.2, 1.2), (1.26, 1.6)
    ]
    // Streak tail (left end, includes the faded part)
    static let tail: [SplashKey] = [
        (0.8, 0.493), (0.811, 0.43), (0.829, 0.329), (0.866, 0.28), (0.912, 0.27), (1.13, 0.27), (1.17, 0.35), (1.21, 0.6), (1.26, 1)
    ]
    static let streakOpacity: [SplashKey] = [
        (1.02, 1), (1.12, 0.9), (1.18, 0.55), (1.23, 0.15), (1.27, 0)
    ]
}

// MARK: - Reveal sweep
// One smooth curve (no keyframe kinks): it starts fast and eases out, like the original.
// `edge` is how far the circle's middle has travelled, in screen widths; the middle reaches
// the right edge (1.0) after ~0.175s and the corners are covered at 1.6.

enum SplashReveal {
    static let start: Double = 1.0
    static let duration: Double = 0.322
    static let end: Double = 1.6

    static func edge(_ t: Double) -> Double {
        let u = min(max((t - start) / duration, 0), 1)
        return end * (1 - pow(1 - u, 1.25))
    }
}

// MARK: - Per-letter tracks
// For each letter: (t, centre x in pixels of a 674px-wide frame, scale).
// Inner letters slide into the dot and are swallowed by it; T, r and m follow.

typealias SplashLetterKey = (t: Double, x: Double, s: Double)

enum SplashLetters {
    static let dotX: Double = 336.5
    static let refWidth: Double = 674
    static let TKeys: [SplashLetterKey] = [
        (0.5, 224.5, 1), (0.55, 222.5, 1), (0.6, 219, 0.97), (0.617, 217, 0.97), (0.65, 215, 0.97), (0.667, 215, 0.97), (0.683, 222, 0.93), (0.7, 237, 0.85), (0.717, 245, 0.78), (0.733, 298, 0.43), (0.75, 314, 0.38), (0.767, 322.5, 0.3), (0.783, 329.5, 0.22), (0.8, 336.5, 0)
    ]
    static let rKeys: [SplashLetterKey] = [
        (0.5, 252, 1), (0.55, 250.5, 1), (0.6, 250, 1), (0.617, 251.5, 1), (0.633, 255.5, 1), (0.65, 264.5, 0.95), (0.667, 264.5, 0.95), (0.683, 269, 0.89), (0.7, 278, 0.79), (0.717, 282.5, 0.74), (0.733, 314, 0.45), (0.75, 316, 0.38), (0.767, 322.5, 0.3), (0.783, 329.5, 0.22), (0.8, 336.5, 0)
    ]
    static let iKeys: [SplashLetterKey] = [
        (0.5, 272, 1), (0.55, 269.5, 1), (0.567, 268.5, 0.95), (0.583, 275.5, 0.9), (0.6, 279, 0.95), (0.617, 285.5, 0.9), (0.633, 289, 0.85), (0.65, 295.5, 0.73), (0.667, 295.5, 0.73), (0.683, 299, 0.64), (0.7, 305.5, 0.55), (0.717, 309.5, 0.55), (0.733, 336.5, 0)
    ]
    static let pKeys: [SplashLetterKey] = [
        (0.5, 303.5, 1), (0.55, 303, 1), (0.567, 306.5, 0.94), (0.583, 310.5, 0.83), (0.6, 315.5, 0.8), (0.617, 316, 0.69), (0.633, 317.5, 0.67), (0.65, 322.5, 0.61), (0.667, 322.5, 0.61), (0.683, 323.5, 0.56), (0.7, 329, 0.53), (0.717, 327, 0.25), (0.733, 336.5, 0)
    ]
    static let cKeys: [SplashLetterKey] = [
        (0.5, 359.5, 1), (0.55, 367.5, 1), (0.567, 364.5, 1), (0.583, 361, 0.89), (0.6, 359.5, 0.86), (0.617, 356.5, 0.79), (0.633, 355, 0.75), (0.65, 352, 0.61), (0.667, 352, 0.61), (0.683, 350.5, 0.57), (0.7, 348, 0.46), (0.717, 347, 0.39), (0.733, 336.5, 0)
    ]
    static let oKeys: [SplashLetterKey] = [
        (0.5, 394.5, 1), (0.55, 401.5, 1), (0.583, 402.5, 1), (0.6, 402.5, 1), (0.617, 398.5, 0.94), (0.633, 394.5, 0.89), (0.65, 386, 0.85), (0.667, 386, 0.85), (0.683, 382, 0.79), (0.7, 374, 0.68), (0.717, 369.5, 0.65), (0.733, 336.5, 0)
    ]
    static let mKeys: [SplashLetterKey] = [
        (0.5, 443, 1), (0.55, 450, 1), (0.6, 452, 1), (0.65, 453, 1), (0.667, 453, 1), (0.683, 446, 0.96), (0.7, 431.5, 0.86), (0.717, 424, 0.8), (0.733, 373, 0.45), (0.75, 358.5, 0.35), (0.767, 351, 0.29), (0.783, 345, 0.22), (0.8, 336.5, 0)
    ]

    /// glyph, height of the glyph's centre above the baseline (screen widths), track
    static let all: [(glyph: String, above: CGFloat, keys: [SplashLetterKey])] = [
        ("T", 0.0356, TKeys),
        ("r", 0.0356, rKeys),
        ("i", 0.0371, iKeys),
        ("p", 0.0141, pKeys),
        ("c", 0.0252, cKeys),
        ("o", 0.0252, oKeys),
        ("m", 0.0252, mKeys),
    ]

    /// How far a letter sits to the right of its measured track while it is full size (reference px).
    /// It fades out with the letter's scale, so the letters still end exactly on the dot.
    /// Matches the logo's resting spacing: the dot sits evenly between the "p" and the "c".
    static func restShift(_ glyph: String) -> Double {
        switch glyph {
        case "T": return 1
        case "r": return 2
        case "m": return 3.3
        default: return 3
        }
    }

    /// Centre x (reference px) and scale at time t.
    static func state(_ keys: [SplashLetterKey], _ t: Double) -> (x: Double, s: Double) {
        guard let first = keys.first, let last = keys.last else { return (dotX, 0) }
        if t <= first.t { return (first.x, first.s) }
        if t >= last.t { return (last.x, last.s) }
        for i in 1..<keys.count {
            let a = keys[i - 1]
            let b = keys[i]
            if t <= b.t {
                let u = (t - a.t) / (b.t - a.t)
                return (a.x + (b.x - a.x) * u, a.s + (b.s - a.s) * u)
            }
        }
        return (last.x, last.s)
    }
}

// MARK: - Root

struct TripSplashView<Content: View>: View {
    private let content: Content
    @State private var start = Date()
    @State private var finished = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: finished)) { context in
            let elapsed = context.date.timeIntervalSince(start)
            SplashScene(t: min(elapsed, SplashTime.total), content: content)
        }
        .ignoresSafeArea()
        .onAppear { restart() }
        .onTapGesture { restart() }
    }

    private func restart() {
        start = Date()
        finished = false
        let mark = start
        // Stop the 60fps timeline once the animation is over.
        DispatchQueue.main.asyncAfter(deadline: .now() + SplashTime.total + 0.1) {
            if mark == start { finished = true }
        }
    }
}

extension TripSplashView where Content == SplashPlaceholderScreen {
    /// Reveals a neutral placeholder.
    init() { self.init { SplashPlaceholderScreen() } }
}

struct SplashScene<Content: View>: View {
    let t: Double
    let content: Content

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SplashPalette.splash
                SplashRevealLayer(t: t, size: geo.size, content: content)
                SplashLogoLayer(t: t, size: geo.size)
                SplashStreakLayer(t: t, size: geo.size)
            }
            .clipped()
        }
    }
}

// MARK: - Layer 1: your screen, revealed by a circle
// The screen is rasterised once (drawingGroup) and only a cheap circular
// clip changes per frame, which keeps the sweep smooth.

struct SplashRevealCircle: Shape {
    var centerX: CGFloat
    var centerY: CGFloat
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(x: centerX - radius, y: centerY - radius,
                               width: radius * 2, height: radius * 2))
    }
}

struct SplashRevealLayer<Content: View>: View {
    let t: Double
    let size: CGSize
    let content: Content

    // Strongly curved circle: the radius barely grows while its centre slides right,
    // so the corners are still uncovered when the middle reaches the right edge.
    var edge: Double { SplashReveal.edge(t) }

    var radius: CGFloat {
        size.width * CGFloat(1.29 + 0.16 * edge)
    }

    var centerX: CGFloat {
        size.width * CGFloat(edge) - radius
    }

    var body: some View {
        content
            .frame(width: size.width, height: size.height)
            .drawingGroup()
            .clipShape(SplashRevealCircle(centerX: centerX,
                                          centerY: size.height / 2,
                                          radius: radius))
            .frame(width: size.width, height: size.height)
    }
}

// MARK: - Layer 2: logo (inner letters get swallowed by the dot, outer ones follow)

struct SplashLogoLayer: View {
    let t: Double
    let size: CGSize

    private let baselineBelowDot: CGFloat = 0.0067

    var body: some View {
        if t < SplashTime.logoEnd {
            let dotDiameter = CGFloat(SplashTrack.value(t, SplashKeys.dot))
            Canvas { ctx, sz in
                let w = sz.width
                let unit = w / CGFloat(SplashLetters.refWidth)
                let dotX = w * CGFloat(SplashLetters.dotX / SplashLetters.refWidth)
                let dotY = sz.height / 2 + w * 0.0163
                let fontSize = w * 0.101
                for item in SplashLetters.all {
                    let st = SplashLetters.state(item.keys, t)
                    if st.s < 0.01 { continue }
                    let restX = item.keys[0].x
                    let g = min(max((st.x - SplashLetters.dotX) / (restX - SplashLetters.dotX), 0), 1)
                    let resolved = ctx.resolve(
                        Text(item.glyph)
                            .font(.system(size: fontSize, weight: .bold))
                            .foregroundColor(.white)
                    )
                    let textSize = resolved.measure(in: CGSize(width: 400, height: 400))
                    let above = item.above * w
                    let shifted = st.x + SplashLetters.restShift(item.glyph) * st.s
                    let cx = dotX + CGFloat(shifted - SplashLetters.dotX) * unit
                    let cy = dotY + (baselineBelowDot - item.above) * w * CGFloat(g)
                    var c = ctx
                    c.translateBy(x: cx, y: cy)
                    c.scaleBy(x: CGFloat(st.s) * 0.92, y: CGFloat(st.s))
                    c.draw(resolved,
                           at: CGPoint(x: -textSize.width / 2, y: above - resolved.firstBaseline(in: textSize)),
                           anchor: .topLeading)
                }
                // The dot is drawn last so it covers the letters entering it.
                let d = dotDiameter * w
                ctx.fill(Path(ellipseIn: CGRect(x: dotX - d / 2, y: dotY - d / 2, width: d, height: d)),
                         with: .color(SplashPalette.orange))
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

// MARK: - Layer 3: orange streak

struct SplashStreakLayer: View {
    let t: Double
    let size: CGSize

    var body: some View {
        if t >= SplashTime.logoEnd && t < 1.27 {
            let w = size.width
            let head = w * CGFloat(SplashTrack.value(t, SplashKeys.head))
            let tail = w * CGFloat(SplashTrack.value(t, SplashKeys.tail))
            let fade = t < 1.018 ? 1.0 : SplashTrack.value(t, SplashKeys.streakOpacity)
            SplashStreakShape(
                length: max(head - tail, w * 0.0134),
                thickness: w * 0.0148,
                width: w
            )
            .offset(x: tail, y: size.height / 2 + w * 0.0163 - w * 0.0074)
            .opacity(fade)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }
}

struct SplashStreakShape: View {
    let length: CGFloat
    let thickness: CGFloat
    let width: CGFloat

    private var startAlpha: Double {
        let a = 1 - Double(length / (width * 0.18))
        return min(max(a, 0), 1)
    }

    private var gradient: LinearGradient {
        let a = startAlpha
        let stops: [Gradient.Stop] = [
            .init(color: SplashPalette.orange.opacity(a), location: 0),
            .init(color: SplashPalette.orange.opacity(a + (1 - a) * 0.35), location: 0.5),
            .init(color: SplashPalette.orange.opacity(a + (1 - a) * 0.75), location: 0.8),
            .init(color: SplashPalette.orange, location: 1)
        ]
        return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        Capsule()
            .fill(gradient)
            .frame(width: length, height: thickness)
    }
}

// MARK: - Placeholder destination
// Shown when you don't pass your own screen. Just enough structure to judge the sweep.

struct SplashPlaceholderScreen: View {
    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 120)
            VStack(spacing: 16) {
                HStack(spacing: 18) {
                    ForEach(0..<4, id: \.self) { _ in
                        Circle().fill(SplashPalette.tint).frame(width: 52, height: 52)
                    }
                }
                Capsule().fill(SplashPalette.tint).frame(height: 36)
                RoundedRectangle(cornerRadius: 12).fill(SplashPalette.tint).frame(height: 160)
                RoundedRectangle(cornerRadius: 12).fill(SplashPalette.tint).frame(height: 96)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .background(SplashPalette.blue)
    }
}

// MARK: - Preview

struct TripSplashView_Previews: PreviewProvider {
    static var previews: some View {
        TripSplashView()
    }
}
