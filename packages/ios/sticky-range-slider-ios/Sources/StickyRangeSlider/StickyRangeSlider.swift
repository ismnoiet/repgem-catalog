//
//  StickyRangeSlider.swift
//  StickyRangeSlider
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// A slider whose handles are value pills that spring after your finger.
///
///  • Two handles that drift together fuse into ONE gooey pill ("$185 – 240") and pull apart
///    again, with a stretchy neck, when you drag one back out.
///  • Tap the track and the nearest handle glides there.
///  • Digits roll as the value changes.
///
///     StickyRangeSlider(lower: $min, upper: $max)                    // two handles
///     StickyRangeSlider(value: $distance, bounds: 1...50, prefix: "", suffix: " km")
///     StickyRangeSlider(lower: $min, upper: $max, style: .paper)     // for dark surfaces
public struct StickyRangeSlider: View {
    private enum Handle { case lower, upper }

    @Binding private var lower: Int
    @Binding private var upper: Int
    private let isRange: Bool
    private let bounds: ClosedRange<Int>
    private let step: Int
    private let prefix: String
    private let suffix: String
    private let style: StickySliderStyle
    private let timing: StickyTiming
    private let haptics: Bool
    private let accessibilityName: String
    private let onEditingChanged: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Continuous handle positions (in value units); `lower`/`upper` are these, snapped to `step`.
    @State private var rawLo: Double
    @State private var rawHi: Double
    @State private var merged = false
    @State private var active: Handle?
    @State private var grabOffset: CGFloat = 0
    @State private var trackWidth: CGFloat = 300
    @State private var idle = false
    @State private var sim = StickySim()

    // MARK: Init

    /// One handle.
    public init(
        value: Binding<Int>,
        bounds: ClosedRange<Int> = 20...400,
        step: Int = 5,
        prefix: String = "$",
        suffix: String = "",
        style: StickySliderStyle = .ink,
        timing: StickyTiming = .default,
        haptics: Bool = true,
        accessibilityName: String = "Value",
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _lower = value
        _upper = .constant(bounds.upperBound)
        isRange = false
        self.bounds = bounds
        self.step = max(step, 1)
        self.prefix = prefix
        self.suffix = suffix
        self.style = style
        self.timing = timing
        self.haptics = haptics
        self.accessibilityName = accessibilityName
        self.onEditingChanged = onEditingChanged
        _rawLo = State(initialValue: Double(value.wrappedValue))
        _rawHi = State(initialValue: Double(bounds.upperBound))
    }

    /// Two handles.
    public init(
        lower: Binding<Int>,
        upper: Binding<Int>,
        bounds: ClosedRange<Int> = 20...400,
        step: Int = 5,
        prefix: String = "$",
        suffix: String = "",
        style: StickySliderStyle = .ink,
        timing: StickyTiming = .default,
        haptics: Bool = true,
        accessibilityName: String = "Range",
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _lower = lower
        _upper = upper
        isRange = true
        self.bounds = bounds
        self.step = max(step, 1)
        self.prefix = prefix
        self.suffix = suffix
        self.style = style
        self.timing = timing
        self.haptics = haptics
        self.accessibilityName = accessibilityName
        self.onEditingChanged = onEditingChanged
        _rawLo = State(initialValue: Double(lower.wrappedValue))
        _rawHi = State(initialValue: Double(upper.wrappedValue))
    }

    // MARK: Body

    public var body: some View {
        GeometryReader { geo in
            let W = max(1, geo.size.width - 2 * StickyMetrics.inset)
            let cy = geo.size.height / 2
            let tLo = StickyMath.x(for: rawLo, width: W, bounds: bounds)
            let tHi = isRange ? StickyMath.x(for: rawHi, width: W, bounds: bounds) : tLo
            let tM: CGFloat = merged ? 1 : 0

            TimelineView(.animation(minimumInterval: nil, paused: idle)) { tl in
                let _ = sim.step(tl.date, tLo: tLo, tHi: tHi, tM: tM,
                                 timing: timing, instant: reduceMotion)
                let _ = pauseIfSettled(tLo: tLo, tHi: tHi, tM: tM)
                layers(size: geo.size, trackWidth: W, cy: cy)
            }
            .contentShape(Rectangle())
            .gesture(drag(W))
            .onChange(of: W, initial: true) { _, w in
                trackWidth = w
                refreshMerged()
            }
        }
        .frame(height: StickyMetrics.height)
        .onChange(of: lower) { _, new in
            guard active == nil else { return }
            rawLo = Double(new)
            wake()
            refreshMerged()
        }
        .onChange(of: upper) { _, new in
            guard active == nil, isRange else { return }
            rawHi = Double(new)
            wake()
            refreshMerged()
        }
        .sensoryFeedback(trigger: lower) { _, _ in haptics ? .selection : nil }
        .sensoryFeedback(trigger: upper) { _, _ in haptics && isRange ? .selection : nil }
        .sensoryFeedback(trigger: merged) { _, _ in haptics ? .impact(flexibility: .soft, intensity: 0.6) : nil }
        .accessibilityRepresentation { accessibilityControls }
    }

    // MARK: Layers

    private func layers(size: CGSize, trackWidth W: CGFloat, cy: CGFloat) -> some View {
        let m = StickyMath.clamp01(sim.m)
        let sLo = sim.xLo
        let sHi = isRange ? sim.xHi : sim.xLo

        let lowerText = fullText(lower)
        let upperText = fullText(upper)
        let wL = StickyMath.pillWidth(for: lowerText)
        let wR = StickyMath.pillWidth(for: upperText)
        let wM = StickyMath.mergedWidth(lower: lowerText, upper: "\(upper)\(suffix)")
        let mid = (sLo + sHi) / 2

        // Where each pill is actually drawn: on its own handle when apart; tucked against the
        // other so the pair forms one pill when fused.
        let cL = isRange ? StickyMath.lerp(sLo, mid - wM / 2 + wL / 2, m) : sLo
        let cR = StickyMath.lerp(sHi, mid + wM / 2 - wR / 2, m)

        let separateOpacity = StickyMath.clamp01(1.5 - 2 * m)
        let mergedOpacity = StickyMath.clamp01(2 * m - 0.5)

        let segStart = isRange ? sLo : StickyMetrics.inset
        let segEnd = isRange ? sHi : sLo

        return ZStack(alignment: .topLeading) {
            // Track
            Capsule()
                .fill(style.track)
                .frame(width: W, height: StickyMetrics.trackHeight)
                .position(x: StickyMetrics.inset + W / 2, y: cy)

            // Active segment
            Rectangle()
                .fill(style.trackFill)
                .frame(width: max(0, segEnd - segStart), height: StickyMetrics.trackHeight)
                .position(x: (segStart + segEnd) / 2, y: cy)

            // Goo: blur + alpha threshold fuses shapes that are close together.
            Canvas { ctx, _ in
                ctx.addFilter(.alphaThreshold(min: 0.5, color: style.pill))
                ctx.addFilter(.blur(radius: StickyMetrics.gooBlur))
                ctx.drawLayer { l in
                    let h = StickyMetrics.pillHeight
                    let r = StickyMetrics.pillRadius
                    l.fill(Path(roundedRect: CGRect(x: cL - wL / 2, y: cy - h / 2, width: wL, height: h),
                                cornerRadius: r), with: .color(style.pill))
                    if isRange {
                        l.fill(Path(roundedRect: CGRect(x: cR - wR / 2, y: cy - h / 2, width: wR, height: h),
                                    cornerRadius: r), with: .color(style.pill))
                        // A thin bridge: the neck that stretches between the pills as they part.
                        l.fill(Path(CGRect(x: cL, y: cy - 3.5, width: max(0, cR - cL), height: 7)),
                               with: .color(style.pill))
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .shadow(color: style.shadow, radius: 5, y: 2)
            .allowsHitTesting(false)

            // Labels
            pillText(lowerText, value: lower)
                .position(x: cL, y: cy)
                .opacity(isRange ? separateOpacity : 1)

            if isRange {
                pillText(upperText, value: upper)
                    .position(x: cR, y: cy)
                    .opacity(separateOpacity)

                HStack(spacing: (StickyMetrics.dashWidth - StickyMetrics.dashGlyph) / 2) {
                    pillText(lowerText, value: lower)
                    Text("–")
                        .font(.system(size: StickyMetrics.fontSize, weight: .medium))
                        .foregroundStyle(style.label.opacity(0.6))
                        .frame(width: StickyMetrics.dashGlyph)
                    pillText("\(upper)\(suffix)", value: upper)
                }
                .position(x: mid, y: cy)
                .opacity(mergedOpacity)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func pillText(_ string: String, value: Int) -> some View {
        Text(string)
            .font(.system(size: StickyMetrics.fontSize, weight: .medium).monospacedDigit())
            .foregroundStyle(style.label)
            .fixedSize()
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(value)))
            .animation(reduceMotion ? nil : .snappy(duration: timing.digitRoll), value: value)
    }

    private func fullText(_ v: Int) -> String { "\(prefix)\(v)\(suffix)" }

    // MARK: Gesture

    private func drag(_ W: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if active == nil {
                    let sx = g.startLocation.x
                    let handle = pickHandle(at: sx)
                    active = handle
                    onEditingChanged(true)
                    if touchesPill(at: sx) {
                        sim.glide = false
                        grabOffset = sx - StickyMath.x(for: handle == .lower ? rawLo : rawHi,
                                                       width: W, bounds: bounds)
                    } else {
                        // Tapped the bare track: send the nearest handle there.
                        sim.glide = true
                        grabOffset = 0
                    }
                }
                // Once the finger really drags, go back to the tight follow spring.
                if sim.glide, abs(g.translation.width) > StickyMetrics.dragStart { sim.glide = false }
                move(toX: g.location.x - grabOffset, W)
            }
            .onEnded { _ in
                active = nil
                rawLo = Double(lower)                   // settle onto the snapped value
                if isRange { rawHi = Double(upper) }
                wake()
                refreshMerged()
                onEditingChanged(false)
            }
    }

    private func pickHandle(at x: CGFloat) -> Handle {
        guard isRange else { return .lower }
        let mid = (sim.xLo + sim.xHi) / 2
        if merged { return x < mid ? .lower : .upper }   // left / right half of the fused pill
        return abs(x - sim.xLo) < abs(x - sim.xHi) ? .lower : .upper
    }

    /// True when the touch landed on a pill (as opposed to empty track).
    private func touchesPill(at x: CGFloat) -> Bool {
        let slop = StickyMetrics.tapSlop
        let lowerText = fullText(lower)
        if !isRange { return abs(x - sim.xLo) <= StickyMath.pillWidth(for: lowerText) / 2 + slop }
        if merged {
            let w = StickyMath.mergedWidth(lower: lowerText, upper: "\(upper)\(suffix)")
            return abs(x - (sim.xLo + sim.xHi) / 2) <= w / 2 + slop
        }
        return abs(x - sim.xLo) <= StickyMath.pillWidth(for: lowerText) / 2 + slop
            || abs(x - sim.xHi) <= StickyMath.pillWidth(for: fullText(upper)) / 2 + slop
    }

    private func move(toX x: CGFloat, _ W: CGFloat) {
        let v = StickyMath.value(atX: x, width: W, bounds: bounds)
        let gap = Double(step)

        switch active {
        case .lower?: rawLo = isRange ? min(v, rawHi - gap) : v
        case .upper?: rawHi = max(v, rawLo + gap)
        case nil: break
        }
        lower = StickyMath.snap(rawLo, step: step, bounds: bounds)
        if isRange { upper = StickyMath.snap(rawHi, step: step, bounds: bounds) }
        wake()
        refreshMerged()
    }

    // MARK: State helpers

    private func refreshMerged() {
        guard isRange else { merged = false; return }
        let d = StickyMath.x(for: rawHi, width: trackWidth, bounds: bounds)
            - StickyMath.x(for: rawLo, width: trackWidth, bounds: bounds)
        let next = StickyMath.merged(current: merged, distance: d)
        if next != merged { merged = next }
    }

    /// Resume the frame loop.
    private func wake() { if idle { idle = false } }

    /// Stop the frame loop once everything is at rest, so an idle slider costs nothing.
    private func pauseIfSettled(tLo: CGFloat, tHi: CGFloat, tM: CGFloat) {
        guard !idle, active == nil, sim.isSettled(tLo: tLo, tHi: tHi, tM: tM) else { return }
        DispatchQueue.main.async { idle = true }
    }

    // MARK: Accessibility

    @ViewBuilder
    private var accessibilityControls: some View {
        let lo = Double(bounds.lowerBound), hi = Double(bounds.upperBound)
        if isRange {
            VStack {
                Slider(value: Binding(get: { Double(lower) }, set: { setLower(Int($0)) }),
                       in: lo...hi, step: Double(step))
                    .accessibilityLabel("\(accessibilityName) minimum")
                    .accessibilityValue(fullText(lower))
                Slider(value: Binding(get: { Double(upper) }, set: { setUpper(Int($0)) }),
                       in: lo...hi, step: Double(step))
                    .accessibilityLabel("\(accessibilityName) maximum")
                    .accessibilityValue(fullText(upper))
            }
        } else {
            Slider(value: Binding(get: { Double(lower) }, set: { setLower(Int($0)) }),
                   in: lo...hi, step: Double(step))
                .accessibilityLabel(accessibilityName)
                .accessibilityValue(fullText(lower))
        }
    }

    private func setLower(_ v: Int) {
        lower = isRange ? min(v, upper - step) : v
        rawLo = Double(lower)
        wake()
        refreshMerged()
    }

    private func setUpper(_ v: Int) {
        upper = max(v, lower + step)
        rawHi = Double(upper)
        wake()
        refreshMerged()
    }
}
