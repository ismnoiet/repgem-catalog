//
//  FireworkPalette.swift
//  FireworkFlourish
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// Ready-made color sets. Every entry is a list of color pairs; a burst picks one pair and mixes
/// its particles between the two colors.
public enum FireworkPalette {
    /// Cyan/green, magenta/violet, blue/purple, orange/yellow, green/lime, white/ice (default).
    public static let rainbow: [FireworkColors] = [
        (Color(red: 0.25, green: 0.95, blue: 0.85), Color(red: 0.30, green: 0.90, blue: 0.45)),
        (Color(red: 1.00, green: 0.30, blue: 0.80), Color(red: 0.85, green: 0.35, blue: 0.95)),
        (Color(red: 0.35, green: 0.55, blue: 1.00), Color(red: 0.55, green: 0.40, blue: 1.00)),
        (Color(red: 1.00, green: 0.60, blue: 0.25), Color(red: 1.00, green: 0.85, blue: 0.30)),
        (Color(red: 0.45, green: 1.00, blue: 0.40), Color(red: 0.85, green: 1.00, blue: 0.45)),
        (Color(red: 0.95, green: 0.95, blue: 1.00), Color(red: 0.55, green: 0.65, blue: 1.00)),
    ]
    public static let gold: [FireworkColors] = [
        (Color(red: 1.00, green: 0.85, blue: 0.40), Color(red: 1.00, green: 0.65, blue: 0.20)),
        (Color(red: 1.00, green: 0.95, blue: 0.70), Color(red: 1.00, green: 0.78, blue: 0.30)),
    ]
    public static let success: [FireworkColors] = [
        (Color(red: 0.35, green: 1.00, blue: 0.65), Color(red: 0.30, green: 0.85, blue: 0.95)),
        (Color(red: 0.70, green: 1.00, blue: 0.50), Color(red: 0.95, green: 1.00, blue: 0.70)),
    ]
    public static let pink: [FireworkColors] = [
        (Color(red: 1.00, green: 0.35, blue: 0.55), Color(red: 1.00, green: 0.60, blue: 0.75)),
        (Color(red: 1.00, green: 0.45, blue: 0.45), Color(red: 0.95, green: 0.30, blue: 0.65)),
    ]
    public static let neon: [FireworkColors] = [
        (Color(red: 0.10, green: 1.00, blue: 0.80), Color(red: 0.95, green: 0.20, blue: 1.00)),
        (Color(red: 0.70, green: 1.00, blue: 0.10), Color(red: 0.10, green: 0.80, blue: 1.00)),
    ]
    public static let ice: [FireworkColors] = [
        (Color(red: 0.75, green: 0.90, blue: 1.00), .white),
        (Color(red: 0.55, green: 0.75, blue: 1.00), Color(red: 0.85, green: 0.95, blue: 1.00)),
    ]
    public static let fire: [FireworkColors] = [
        (Color(red: 1.00, green: 0.45, blue: 0.10), Color(red: 1.00, green: 0.80, blue: 0.25)),
        (Color(red: 1.00, green: 0.25, blue: 0.15), Color(red: 1.00, green: 0.60, blue: 0.20)),
    ]
    public static let pastel: [FireworkColors] = [
        (Color(red: 1.00, green: 0.75, blue: 0.85), Color(red: 0.75, green: 0.85, blue: 1.00)),
        (Color(red: 0.80, green: 1.00, blue: 0.85), Color(red: 1.00, green: 0.95, blue: 0.75)),
    ]
    public static let mono: [FireworkColors] = [(.white, Color(white: 0.8))]

    /// Every palette with its name, handy for pickers.
    public static let all: [(name: String, colors: [FireworkColors])] = [
        ("Rainbow", rainbow), ("Gold", gold), ("Success", success), ("Pink", pink),
        ("Neon", neon), ("Ice", ice), ("Fire", fire), ("Pastel", pastel), ("Mono", mono),
    ]
}
