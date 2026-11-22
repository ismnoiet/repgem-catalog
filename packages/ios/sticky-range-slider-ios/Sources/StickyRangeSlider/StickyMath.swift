//
//  StickyMath.swift
//  StickyRangeSlider
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Pure geometry and value math, kept free of SwiftUI state so it can be unit-tested.
//
import SwiftUI

/// Sizes measured from the reference interaction.
enum StickyMetrics {
    static let pillHeight: CGFloat = 26
    static let pillRadius: CGFloat = 11
    static let pillPad: CGFloat = 10
    static let fontSize: CGFloat = 12
    static let dashWidth: CGFloat = 14          // " – " between the two merged values
    static let dashGlyph: CGFloat = 6
    static let trackHeight: CGFloat = 2
    static let inset: CGFloat = 30              // room so the end pills don't clip
    static let height: CGFloat = 72

    /// Centre distance at which two pills fuse, and at which they release. The gap between the
    /// two is the hysteresis that stops the pair flickering while you hover around the threshold.
    static let mergeBelow: CGFloat = 48
    static let splitAbove: CGFloat = 58

    static let gooBlur: CGFloat = 4.5
    static let tapSlop: CGFloat = 6             // extra grab area around a pill
    static let dragStart: CGFloat = 6           // travel before a tap becomes a drag
}

enum StickyMath {

    // MARK: Values <-> positions

    /// x position (including the leading inset) of a value on a track `width` wide.
    static func x(for value: Double, width: CGFloat, bounds: ClosedRange<Int>) -> CGFloat {
        let lo = Double(bounds.lowerBound), hi = Double(bounds.upperBound)
        guard hi > lo else { return StickyMetrics.inset }
        return StickyMetrics.inset + CGFloat((value - lo) / (hi - lo)) * width
    }

    /// The (unsnapped) value under an x position, clamped to the bounds.
    static func value(atX x: CGFloat, width: CGFloat, bounds: ClosedRange<Int>) -> Double {
        let lo = Double(bounds.lowerBound), hi = Double(bounds.upperBound)
        let raw = lo + Double((x - StickyMetrics.inset) / max(width, 1)) * (hi - lo)
        return min(max(raw, lo), hi)
    }

    /// Rounds to the nearest `step` and clamps to the bounds.
    static func snap(_ value: Double, step: Int, bounds: ClosedRange<Int>) -> Int {
        let s = Double(max(step, 1))
        let n = Int((value / s).rounded()) * max(step, 1)
        return min(max(n, bounds.lowerBound), bounds.upperBound)
    }

    // MARK: Merging

    /// Fuse when the pills get close, release only once they are clearly apart.
    static func merged(current: Bool, distance: CGFloat) -> Bool {
        if !current && distance < StickyMetrics.mergeBelow { return true }
        if current && distance > StickyMetrics.splitAbove { return false }
        return current
    }

    // MARK: Text

    /// Width estimate for the 12pt label font (digits are monospaced). Avoids measuring views.
    static func textWidth(_ s: String) -> CGFloat {
        s.reduce(CGFloat(0)) { total, c in
            if c.isNumber { return total + 7.2 }
            if c == " " { return total + 3.3 }
            if c == "." || c == "," || c == "'" { return total + 3.4 }
            if c.isUppercase { return total + 7.9 }
            if c.isLowercase { return total + 6.4 }
            return total + 7.2                       // currency signs and the like
        }
    }

    static func pillWidth(for text: String) -> CGFloat {
        textWidth(text) + 2 * StickyMetrics.pillPad
    }

    static func mergedWidth(lower: String, upper: String) -> CGFloat {
        textWidth(lower) + textWidth(upper) + StickyMetrics.dashWidth + 2 * StickyMetrics.pillPad
    }

    // MARK: Springs

    /// Angular frequency for a spring that takes about `response` seconds to catch up.
    static func omega(response: Double) -> CGFloat {
        CGFloat(2 * Double.pi / max(response, 0.05))
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
    static func clamp01(_ v: CGFloat) -> CGFloat { min(max(v, 0), 1) }
}
