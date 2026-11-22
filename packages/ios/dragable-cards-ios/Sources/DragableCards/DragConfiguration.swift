//
//  DragConfiguration.swift
//  DragableCards
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Everything you can tune: timing (long press and springs), the lifted card, and the column look.
//
import SwiftUI

/// Long-press delay and the springs that drive the interaction.
public struct DragTiming {
    /// Hold time before a card lifts, in seconds.
    public var longPress: Double = 0.15
    /// Scale, tilt and shadow ease in.
    public var lift: Animation = .spring(response: 0.2, dampingFraction: 0.72)
    /// Neighbours sliding aside as the slot moves.
    public var shuffle: Animation = .spring(response: 0.22, dampingFraction: 0.86)
    /// The snap into the slot: fast and almost critically damped, like an app icon settling.
    public var drop: Animation = .interpolatingSpring(mass: 1, stiffness: 600, damping: 49)
    /// How long the drop spring runs before the lists are updated, in seconds.
    public var dropDuration: Double = 0.25
    /// Minimum gap between automatic scrolls, in seconds.
    public var edgeScrollDelay: Double = 0.7

    public init() {}
}

/// The lifted card and the empty slot.
public struct DragAppearance {
    /// Scale of the lifted card.
    public var liftScale: CGFloat = 1.04
    /// Tilt of the lifted card, in degrees.
    public var liftTilt: Double = 4
    /// Blur radius of the lifted card's shadow.
    public var liftShadow: CGFloat = 12
    /// Opacity of that shadow.
    public var liftShadowOpacity: Double = 0.28
    /// Match your card's corner radius so the empty slot has the same shape.
    public var cornerRadius: CGFloat = 6
    /// Fill of the default empty slot.
    public var placeholderFill: Color = Color(red: 0xE6 / 255, green: 0xEA / 255, blue: 0xEF / 255)
    /// Dashed border of the default empty slot.
    public var placeholderBorder: Color = Color(red: 0xD0 / 255, green: 0xD7 / 255, blue: 0xDE / 255)

    public init() {}
}

/// The container drawn around each column.
public struct ColumnStyle {
    public var background: Color = Color(red: 0xF6 / 255, green: 0xF8 / 255, blue: 0xFA / 255)
    public var border: Color = Color(red: 0xD0 / 255, green: 0xD7 / 255, blue: 0xDE / 255)
    public var cornerRadius: CGFloat = 10
    /// Space between the column edge and its content.
    public var padding: CGFloat = 12

    public init() {}
}
