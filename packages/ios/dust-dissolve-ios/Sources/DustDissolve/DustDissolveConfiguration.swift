//
//  DustDissolveConfiguration.swift
//  DustDissolve
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// Which way the view is eaten away. The dust is born in the same order.
public enum DustDissolveDirection: Int, CaseIterable {
    case leftToRight = 0
    case rightToLeft
    case topToBottom
    case bottomToTop
    /// From the centre outwards (pairs well with `.burst` and `.ellipse`).
    case centerOut
}

/// Where the dust goes once it has left the view.
public enum DustDissolveMotion {
    /// Streams along an arc to the view marked with `.dustTarget()`
    /// (falls back to a small burst when there is no target).
    case flowToTarget
    /// Blows away in one direction. `angle`: 0° = right, 90° = down, −90° = up.
    case drift(angle: Angle, distance: CGFloat)
    /// Flies outward from the centre of the view.
    case burst(distance: CGFloat)
}

/// Where dust may be born. Use `.ellipse` for round views so no dots appear in the empty corners.
public enum DustDissolveShape {
    case rectangle
    case ellipse
}

/// Timing and look of one dust-dissolve run. All times are seconds since `fire()`.
///
/// The defaults are matched frame by frame to the original 3-second coupon recording:
///
///     0.28 – 0.62   shimmer line crosses the coupon
///     0.55 – 1.10   coupon dissolves left → right, dust is born where it is eaten away
///     0.95 – 2.10   the cloud collapses and streams along an arc to the target
///     3.00          end of the sequence (host UI can use the whole range through `elapsed(at:)`)
///
/// Presets for other behaviors: `.snap`, `.fall`, `.burst`, `.dismiss`.
public struct DustDissolveConfiguration {
    /// A light line crosses the view before it dissolves.
    public var shimmer: Bool = true
    public var shimmerStart: Double = 0.28
    public var shimmerEnd: Double = 0.62

    public var direction: DustDissolveDirection = .leftToRight
    public var motion: DustDissolveMotion = .flowToTarget
    public var shape: DustDissolveShape = .rectangle

    public var dissolveStart: Double = 0.55
    public var dissolveEnd: Double = 1.10
    public var flightStart: Double = 0.95
    /// Random extra delay (0…flightStagger) before each dot leaves the cloud.
    public var flightStagger: Double = 0.15
    /// How long one dot takes to fly away (picked per dot from this range).
    public var flightDuration: ClosedRange<Double> = 0.8...0.95
    /// Length of the whole sequence. The timeline stops (and the end state holds) after this.
    public var total: Double = 3.0

    public var particleCount: Int = 1100
    /// Dot diameter range, in points.
    public var dotSize: ClosedRange<Double> = 1.8...3.2
    /// Every n-th dot flares into a 4-point sparkle. `0` turns sparkles off.
    public var sparkleEvery: Int = 60
    /// Dot colors, picked at random per dot.
    public var palette: [Color] = DustDissolveConfiguration.pastel
    public var seed: UInt64 = 7

    /// When the first dots are gone / reach the target (a good moment to pop the "landed" UI).
    public var arrival: Double { flightStart + flightDuration.lowerBound }

    public init() {}

    public static let `default` = DustDissolveConfiguration()

    /// Lavender, pink, ice blue and white: reads well on dark and light backgrounds.
    public static let pastel: [Color] = [
        Color(red: 0.84, green: 0.76, blue: 1.00),
        Color(red: 0.93, green: 0.80, blue: 1.00),
        Color(red: 1.00, green: 0.82, blue: 0.93),
        Color(red: 0.76, green: 0.90, blue: 1.00),
        Color(red: 0.74, green: 1.00, blue: 0.95),
        Color.white,
    ]
}

// MARK: - Presets

public extension DustDissolveConfiguration {
    /// The original coupon: shimmer, dissolve left → right, dust flows to a target.
    static var coupon: DustDissolveConfiguration { DustDissolveConfiguration() }

    /// "Thanos snap": no shimmer, dissolves left → right, the dust blows away up and to the right.
    static var snap: DustDissolveConfiguration {
        var c = DustDissolveConfiguration()
        c.shimmer = false
        c.motion = .drift(angle: .degrees(-28), distance: 150)
        c.dissolveStart = 0.05; c.dissolveEnd = 0.85
        c.flightStart = 0.40; c.flightStagger = 0.45; c.flightDuration = 1.0...1.5
        c.total = 2.4
        return c
    }

    /// Dismiss a card: dissolves left → right, the dust is carried off to the right.
    static var dismiss: DustDissolveConfiguration {
        var c = DustDissolveConfiguration()
        c.shimmer = false
        c.motion = .drift(angle: .degrees(-12), distance: 230)
        c.dissolveStart = 0.05; c.dissolveEnd = 0.75
        c.flightStart = 0.35; c.flightStagger = 0.35; c.flightDuration = 0.9...1.3
        c.total = 2.2
        return c
    }

    /// Delete a row: dissolves top → bottom and the dust falls.
    static var fall: DustDissolveConfiguration {
        var c = DustDissolveConfiguration()
        c.shimmer = false
        c.direction = .topToBottom
        c.motion = .drift(angle: .degrees(90), distance: 110)
        c.dissolveStart = 0.05; c.dissolveEnd = 0.70
        c.flightStart = 0.30; c.flightStagger = 0.35; c.flightDuration = 0.8...1.2
        c.total = 2.0
        return c
    }

    /// Round avatar or badge: dissolves from the centre out, the dust bursts outward.
    static var burst: DustDissolveConfiguration {
        var c = DustDissolveConfiguration()
        c.shimmer = false
        c.direction = .centerOut
        c.shape = .ellipse
        c.motion = .burst(distance: 120)
        c.dissolveStart = 0.05; c.dissolveEnd = 0.70
        c.flightStart = 0.30; c.flightStagger = 0.30; c.flightDuration = 0.9...1.3
        c.total = 2.1
        return c
    }
}

// MARK: - Small math helpers shared by the library

@inline(__always) func ramp(_ t: Double, _ a: Double, _ b: Double) -> Double {
    min(max((t - a) / (b - a), 0), 1)
}
@inline(__always) func smooth(_ x: Double) -> Double { x * x * (3 - 2 * x) }
@inline(__always) func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
