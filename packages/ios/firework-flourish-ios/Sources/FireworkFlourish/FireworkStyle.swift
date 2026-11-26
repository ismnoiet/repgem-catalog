//
//  FireworkStyle.swift
//  FireworkFlourish
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// Two colors a burst mixes between, e.g. `(.cyan, .green)`.
public typealias FireworkColors = (Color, Color)

/// Everything tweakable about the effect. Use a preset (`.card`, `.grand`, ...) or build your own:
///
///     FireworkStyle(interval: 0.2, particles: 90, maxRadius: 60, palettes: FireworkPalette.gold)
public struct FireworkStyle {
    /// Seconds between rockets.
    public var interval: Double
    /// Rise duration of the rocket trail.
    public var rocketTime: Double
    /// Duration of the white glow ball before it bursts.
    public var flashTime: Double
    /// How long the particles take to fade out.
    public var burstLife: Double
    /// Particles per burst.
    public var particles: Int
    /// Burst spread in points.
    public var maxRadius: CGFloat
    /// Downward drift in pt/s². Negative values make the particles rise (embers).
    public var gravity: CGFloat
    /// Draw the thin rocket trail before each burst.
    public var showRockets: Bool
    /// Where bursts happen, as a fraction of the height.
    public var yRange: ClosedRange<Double>
    /// Where bursts happen, as a fraction of the width.
    public var xRange: ClosedRange<Double>
    /// Color pairs; every burst picks one pair.
    public var palettes: [FireworkColors]

    public init(
        interval: Double = 0.30,
        rocketTime: Double = 0.34,
        flashTime: Double = 0.30,
        burstLife: Double = 2.8,
        particles: Int = 64,
        maxRadius: CGFloat = 24,
        gravity: CGFloat = 5,
        showRockets: Bool = true,
        yRange: ClosedRange<Double> = 0.08...0.78,
        xRange: ClosedRange<Double> = 0.04...0.96,
        palettes: [FireworkColors] = FireworkPalette.rainbow
    ) {
        self.interval = interval
        self.rocketTime = rocketTime
        self.flashTime = flashTime
        self.burstLife = burstLife
        self.particles = particles
        self.maxRadius = maxRadius
        self.gravity = gravity
        self.showRockets = showRockets
        self.yRange = yRange
        self.xRange = xRange
        self.palettes = palettes
    }

    /// How long one burst stays on screen, from launch to the last fading particle.
    var totalLife: Double { rocketTime + burstLife + 0.2 }
}
