//
//  DemoSupport.swift
//  StickyRangeSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Shared pieces for the dark and light demo screens.
//
import SwiftUI
import StickyRangeSlider

/// Colors for one demo theme.
struct DemoTheme {
    let dark: Bool

    var page: Color { dark ? Color(white: 0.07) : Color(red: 0.96, green: 0.96, blue: 0.97) }
    var card: Color { dark ? Color(white: 0.11) : .white }
    var ink: Color { dark ? Color(white: 0.96) : Color(red: 0.10, green: 0.11, blue: 0.14) }
    var subtle: Color { dark ? .white.opacity(0.45) : Color(red: 0.45, green: 0.47, blue: 0.52) }
    var hairline: Color { dark ? .white.opacity(0.08) : .black.opacity(0.06) }
    var barOff: Color { dark ? .white.opacity(0.12) : .black.opacity(0.09) }
    var style: StickySliderStyle { dark ? .paper : .ink }
    var buttonText: Color { dark ? Color(white: 0.10) : .white }
}

/// Fake listings: how many stays there are at each price, for the histogram demo.
enum PriceData {
    static let start = 20
    static let binWidth = 8
    static let counts: [Int] = (0..<48).map { i in
        let x = Double(start + i * binWidth + binWidth / 2)
        let main = 220 * exp(-pow((x - 105) / 60, 2))
        let luxury = 70 * exp(-pow((x - 290) / 55, 2))
        return Int((main + luxury).rounded()) + 4
    }

    static func isInside(bin i: Int, _ lo: Int, _ hi: Int) -> Bool {
        let centre = start + i * binWidth + binWidth / 2
        return centre >= lo && centre <= hi
    }

    static func stays(_ lo: Int, _ hi: Int) -> Int {
        let total = counts.enumerated().reduce(0) { $0 + (isInside(bin: $1.offset, lo, hi) ? $1.element : 0) }
        return Int(Double(total) * 0.12)
    }
}

struct PriceHistogram: View {
    let lo: Int
    let hi: Int
    let theme: DemoTheme

    var body: some View {
        let peak = CGFloat(PriceData.counts.max() ?? 1)
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(PriceData.counts.enumerated()), id: \.offset) { i, count in
                let on = PriceData.isInside(bin: i, lo, hi)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(on ? theme.ink : theme.barOff)
                    .frame(height: max(2, CGFloat(count) / peak * 84))
                    .animation(.easeOut(duration: 0.14), value: on)
            }
        }
        .frame(height: 84, alignment: .bottom)
    }
}

struct DemoSection<Content: View>: View {
    let title: String
    let theme: DemoTheme
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.subtle)
            content
        }
    }
}

struct DemoCard<Content: View>: View {
    let theme: DemoTheme
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(.vertical, 20)
            .frame(width: 340)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(theme.card))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(theme.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(theme.dark ? 0 : 0.06), radius: 14, y: 6)
    }
}

/// The hero demo: a price filter with a histogram that follows the handles.
struct PriceFilterCard: View {
    let theme: DemoTheme
    @State private var lo = 85
    @State private var hi = 240

    var body: some View {
        DemoCard(theme: theme) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Price per night")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.ink)
                Text("Includes all fees, before taxes")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.subtle)
            }
            .padding(.horizontal, 30)

            PriceHistogram(lo: lo, hi: hi, theme: theme)
                .padding(.horizontal, 30)
                .padding(.top, 14)

            StickyRangeSlider(lower: $lo, upper: $hi, bounds: 20...400, step: 5,
                              style: theme.style, accessibilityName: "Price per night")

            HStack {
                Button {
                    withAnimation(.snappy) { lo = 20; hi = 400 }
                } label: {
                    Text("Clear")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.subtle)
                }
                .buttonStyle(.plain)
                Spacer()
                let stays = PriceData.stays(lo, hi)
                Text("Show \(stays) stays")
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundStyle(theme.buttonText)
                    .contentTransition(.numericText(value: Double(stays)))
                    .animation(.snappy(duration: 0.28), value: stays)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 11).fill(theme.ink))
            }
            .padding(.horizontal, 30)
            .padding(.top, 6)
        }
    }
}

/// A titled slider inside a card, with its own state.
struct RangeDemo: View {
    let title: String
    let theme: DemoTheme
    @State var lo: Int
    @State var hi: Int
    var bounds: ClosedRange<Int> = 20...400
    var step = 5
    var prefix = "$"
    var suffix = ""
    var style: StickySliderStyle? = nil
    var timing: StickyTiming = .default

    var body: some View {
        DemoCard(theme: theme) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.subtle)
                .padding(.horizontal, 30)
            StickyRangeSlider(lower: $lo, upper: $hi, bounds: bounds, step: step,
                              prefix: prefix, suffix: suffix, style: style ?? theme.style,
                              timing: timing, accessibilityName: title)
        }
    }
}

struct SingleDemo: View {
    let title: String
    let theme: DemoTheme
    @State var value: Int
    var bounds: ClosedRange<Int> = 20...400
    var step = 5
    var prefix = "$"
    var suffix = ""
    var style: StickySliderStyle? = nil

    var body: some View {
        DemoCard(theme: theme) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.subtle)
                .padding(.horizontal, 30)
            StickyRangeSlider(value: $value, bounds: bounds, step: step,
                              prefix: prefix, suffix: suffix, style: style ?? theme.style,
                              accessibilityName: title)
        }
    }
}

/// Everything the dark and light showcases have in common.
struct ExampleStack: View {
    let theme: DemoTheme

    var body: some View {
        VStack(spacing: 30) {
            PriceFilterCard(theme: theme)

            DemoSection(title: "One handle · tap anywhere on the track", theme: theme) {
                SingleDemo(title: "Max distance", theme: theme, value: 12,
                           bounds: 1...50, step: 1, prefix: "", suffix: " km")
            }
            DemoSection(title: "Any range, any unit", theme: theme) {
                VStack(spacing: 16) {
                    RangeDemo(title: "Salary", theme: theme, lo: 85, hi: 140,
                              bounds: 40...200, step: 5, prefix: "$", suffix: "k")
                    RangeDemo(title: "Age", theme: theme, lo: 24, hi: 38,
                              bounds: 18...65, step: 1, prefix: "")
                }
            }
            DemoSection(title: "Your colors", theme: theme) {
                VStack(spacing: 16) {
                    RangeDemo(title: "Blue", theme: theme, lo: 60, hi: 220, style: .accent(.blue))
                    RangeDemo(title: "Green", theme: theme, lo: 110, hi: 180,
                              style: .accent(Color(red: 0.12, green: 0.72, blue: 0.45)))
                    RangeDemo(title: "Orange", theme: theme, lo: 40, hi: 300,
                              style: .accent(Color(red: 1.0, green: 0.55, blue: 0.25)))
                }
            }
            DemoSection(title: "Lazy follow (slower springs)", theme: theme) {
                RangeDemo(title: "Heavy handles", theme: theme, lo: 90, hi: 260,
                          timing: StickyTiming(follow: 0.45, glide: 0.6, merge: 0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}
