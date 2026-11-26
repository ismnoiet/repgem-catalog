//
//  FireworkStyle+Presets.swift
//  FireworkFlourish
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

public extension FireworkStyle {
    /// Small bursts inside a card. The default.
    static let card = FireworkStyle()
    /// Quiet and sparse, for banners and list rows.
    static let subtle = FireworkStyle(interval: 0.7, particles: 40, maxRadius: 18)
    /// Gold sparkle for milestones.
    static let milestone = FireworkStyle(interval: 0.5, particles: 48, maxRadius: 20, palettes: FireworkPalette.gold)
    /// Full-screen celebration.
    static let grand = FireworkStyle(interval: 0.20, rocketTime: 0.55, burstLife: 3.2, particles: 90,
                                     maxRadius: 70, gravity: 18, yRange: 0.10...0.55)
    /// Tight burst for button taps.
    static let tap = FireworkStyle(interval: 0.12, rocketTime: 0.25, burstLife: 1.8, particles: 40,
                                   maxRadius: 34, gravity: 12, yRange: 0.0...0.6, palettes: FireworkPalette.success)
    /// Pink bursts for anniversaries and love.
    static let romance = FireworkStyle(interval: 0.45, burstLife: 3.2, particles: 56, maxRadius: 22,
                                       gravity: 8, palettes: FireworkPalette.pink)
    /// Fast, saturated bursts for scoreboards and games.
    static let neonPop = FireworkStyle(interval: 0.16, rocketTime: 0.28, burstLife: 1.6, particles: 54,
                                       maxRadius: 30, gravity: 6, palettes: FireworkPalette.neon)
    /// Embers rising instead of falling. No rockets.
    static let embers = FireworkStyle(interval: 0.22, rocketTime: 0.05, flashTime: 0.1, burstLife: 3.0,
                                      particles: 26, maxRadius: 14, gravity: -16, showRockets: false,
                                      yRange: 0.5...1.0, palettes: FireworkPalette.fire)
    /// Tiny twinkles, great as a "today" marker on a calendar cell.
    static let sparkle = FireworkStyle(interval: 0.35, rocketTime: 0.05, flashTime: 0.1, burstLife: 1.4,
                                       particles: 14, maxRadius: 10, gravity: 0, showRockets: false,
                                       yRange: 0.1...0.9, palettes: FireworkPalette.mono)
    /// Wide, slow, pastel bursts for gentle celebrations.
    static let pastelBloom = FireworkStyle(interval: 0.35, rocketTime: 0.45, burstLife: 3.4, particles: 80,
                                           maxRadius: 55, gravity: 10, yRange: 0.1...0.6, palettes: FireworkPalette.pastel)
    /// Big finale for countdowns.
    static let newYear = FireworkStyle(interval: 0.12, rocketTime: 0.6, burstLife: 3.4, particles: 110,
                                       maxRadius: 85, gravity: 20, yRange: 0.08...0.5,
                                       palettes: FireworkPalette.rainbow + FireworkPalette.gold)
    /// Tiny burst centred on a button (use it inside a ~150pt square).
    static let like = FireworkStyle(interval: 0.10, rocketTime: 0.05, flashTime: 0.1, burstLife: 1.1,
                                    particles: 22, maxRadius: 36, gravity: 10, showRockets: false,
                                    yRange: 0.35...0.65, xRange: 0.35...0.65, palettes: FireworkPalette.pink)
    /// Cold and calm, for winter or "cool" states.
    static let frost = FireworkStyle(interval: 0.6, burstLife: 3.6, particles: 50, maxRadius: 26,
                                     gravity: 14, palettes: FireworkPalette.ice)

    /// Every preset with its name, handy for pickers.
    static let all: [(name: String, style: FireworkStyle)] = [
        ("card", .card), ("subtle", .subtle), ("milestone", .milestone), ("grand", .grand), ("tap", .tap),
        ("romance", .romance), ("neonPop", .neonPop), ("embers", .embers), ("sparkle", .sparkle),
        ("pastelBloom", .pastelBloom), ("newYear", .newYear), ("like", .like), ("frost", .frost),
    ]
}
