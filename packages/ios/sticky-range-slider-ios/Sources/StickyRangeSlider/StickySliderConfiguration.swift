//
//  StickySliderConfiguration.swift
//  StickyRangeSlider
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// Colors of the slider. Use a preset or build your own.
///
///     StickyRangeSlider(value: $km, style: .ink)             // dark pill, for light surfaces (default)
///     StickyRangeSlider(value: $km, style: .paper)           // light pill, for dark surfaces
///     StickyRangeSlider(value: $km, style: .accent(.blue))   // colored pill
public struct StickySliderStyle: Equatable {
    /// Fill of the pills (and of the neck that joins them).
    public var pill: Color
    /// Text color inside the pills.
    public var label: Color
    /// The full track.
    public var track: Color
    /// The part of the track between the handles.
    public var trackFill: Color
    /// Drop shadow under the pills.
    public var shadow: Color

    public init(
        pill: Color,
        label: Color,
        track: Color,
        trackFill: Color,
        shadow: Color = .black.opacity(0.16)
    ) {
        self.pill = pill
        self.label = label
        self.track = track
        self.trackFill = trackFill
        self.shadow = shadow
    }

    /// Near-black pills on a light surface.
    public static let ink = StickySliderStyle(
        pill: Color(white: 0.11),
        label: .white,
        track: Color(white: 0.89),
        trackFill: Color(white: 0.11)
    )

    /// Near-white pills on a dark surface.
    public static let paper = StickySliderStyle(
        pill: Color(white: 0.96),
        label: Color(white: 0.10),
        track: .white.opacity(0.16),
        trackFill: Color(white: 0.96),
        shadow: .black.opacity(0.45)
    )

    /// A colored pill with white text; the track follows the color.
    public static func accent(_ color: Color) -> StickySliderStyle {
        StickySliderStyle(
            pill: color,
            label: .white,
            track: color.opacity(0.18),
            trackFill: color,
            shadow: color.opacity(0.35)
        )
    }
}

/// How the slider moves. Every value is a spring *response* in seconds: roughly how long the
/// element takes to catch up. Smaller is snappier.
public struct StickyTiming: Equatable {
    /// A pill chasing your finger while you drag.
    public var follow: Double
    /// A pill sliding to a spot you tapped on the track.
    public var glide: Double
    /// Two pills fusing into one, or splitting apart.
    public var merge: Double
    /// Digits rolling when the value changes.
    public var digitRoll: Double

    public init(follow: Double = 0.22, glide: Double = 0.37, merge: Double = 0.26, digitRoll: Double = 0.28) {
        self.follow = follow
        self.glide = glide
        self.merge = merge
        self.digitRoll = digitRoll
    }

    public static let `default` = StickyTiming()
}

/// Spring damping used for all three motions. Slightly under 1 so pills settle with a tiny give.
enum StickyDamping {
    static let follow: CGFloat = 0.82
    static let glide: CGFloat = 0.9
    static let merge: CGFloat = 0.9
}
