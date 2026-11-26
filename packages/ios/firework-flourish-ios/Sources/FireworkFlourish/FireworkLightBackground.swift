//
//  FireworkLightBackground.swift
//  FireworkFlourish
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private struct FireworkLightBackgroundKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    /// True when fireworks are drawn over a light surface. See `View.fireworkLightBackground(_:)`.
    public var fireworkLightBackground: Bool {
        get { self[FireworkLightBackgroundKey.self] }
        set { self[FireworkLightBackgroundKey.self] = newValue }
    }
}

extension View {
    /// Tells every `FireworkFlourish` inside this view that its backdrop is light.
    ///
    /// The default look adds light (additive blending), which disappears on a light surface. With this on,
    /// bursts are drawn with normal blending in deeper, more saturated colors, with no white glow.
    ///
    ///     card.overlay { FireworkFlourish(.card) }
    ///         .fireworkLightBackground()
    public func fireworkLightBackground(_ on: Bool = true) -> some View {
        environment(\.fireworkLightBackground, on)
    }
}

/// A deeper version of `color` that stays visible on a light surface. Greys become a mid grey.
func lightSurfaceTone(_ color: Color) -> Color {
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    #if canImport(UIKit)
    UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    #else
    (NSColor(color).usingColorSpace(.sRGB) ?? .black).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    #endif
    if s < 0.08 { return Color(white: 0.3, opacity: Double(a)) }
    return Color(hue: Double(h), saturation: Double(min(1, max(s, 0.6) * 1.15)),
                 brightness: Double(min(max(b, 0.55), 0.85)), opacity: Double(a))
}
