//
//  DemoSupport.swift
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Small helpers shared by the demo screens.
//
import SwiftUI
import DragableCards

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Text with a size, color and weight in one call.
func txt(_ s: String, _ size: CGFloat, _ color: Color, _ weight: Font.Weight = .regular) -> Text {
    Text(s).font(.system(size: size, weight: weight)).foregroundColor(color)
}

/// Colors shared by the demo boards so the same layout can be shown dark or light.
struct DemoTheme {
    let isLight: Bool
    let page: Color
    let column: Color
    let columnBorder: Color
    let card: Color
    let cardBorder: Color
    let text: Color
    let muted: Color
    let pill: Color
    let placeholder: Color
    /// Green, blue, yellow, purple: the status colors of the project board.
    let accents: [Color]

    static let dark = DemoTheme(
        isLight: false,
        page: Color(hex: 0x161616),
        column: Color(hex: 0x1E1E1E),
        columnBorder: Color(hex: 0x34393F),
        card: Color(hex: 0x2A2A2A),
        cardBorder: Color(hex: 0x3A3F45),
        text: .white.opacity(0.92),
        muted: .white.opacity(0.6),
        pill: .white.opacity(0.08),
        placeholder: Color(hex: 0x262626),
        accents: [Color(hex: 0x3FB950), Color(hex: 0x58A6FF), Color(hex: 0xD29922), Color(hex: 0xA371F7)]
    )

    static let light = DemoTheme(
        isLight: true,
        page: .white,
        column: Color(hex: 0xF6F8FA),
        columnBorder: Color(hex: 0xD0D7DE),
        card: .white,
        cardBorder: Color(hex: 0xD0D7DE),
        text: Color(hex: 0x1F2328),
        muted: Color(hex: 0x59636E),
        pill: .white,
        placeholder: Color(hex: 0xE6EAEF),
        accents: [Color(hex: 0x1A7F37), Color(hex: 0x0969DA), Color(hex: 0xBF8700), Color(hex: 0x8250DF)]
    )
}

extension DemoTheme {
    var columnStyle: ColumnStyle {
        var s = ColumnStyle()
        s.background = column
        s.border = columnBorder
        return s
    }

    func appearance(cornerRadius: CGFloat = 6, liftScale: CGFloat = 1.04, liftTilt: Double = 4) -> DragAppearance {
        var a = DragAppearance()
        a.cornerRadius = cornerRadius
        a.liftScale = liftScale
        a.liftTilt = liftTilt
        a.placeholderFill = placeholder
        a.placeholderBorder = columnBorder
        return a
    }

    func roundedColumnStyle(_ cornerRadius: CGFloat) -> ColumnStyle {
        var s = columnStyle
        s.cornerRadius = cornerRadius
        return s
    }
}

/// A labelled demo block.
struct DemoSection<Content: View>: View {
    let title: String
    let theme: DemoTheme
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 10) {
            txt(title, 12, theme.muted, .medium)
            content
        }
    }
}

/// Initials in a colored circle.
struct AvatarDot: View {
    let initials: String
    let color: Color
    var size: CGFloat = 20

    var body: some View {
        txt(initials, size * 0.4, .white, .bold)
            .frame(width: size, height: size)
            .background(Circle().fill(color))
    }
}

/// A small rounded label.
struct Pill: View {
    let theme: DemoTheme
    let text: String

    var body: some View {
        txt(text, 11, theme.muted, .medium)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(Capsule().fill(theme.pill))
            .overlay(Capsule().stroke(theme.columnBorder, lineWidth: 1))
            .contentTransition(.numericText())
    }
}

/// A two-color gradient tile.
struct Art {
    let a: Color
    let b: Color
    var gradient: LinearGradient {
        LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
