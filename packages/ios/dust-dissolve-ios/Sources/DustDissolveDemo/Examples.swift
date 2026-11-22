//
//  Examples.swift
//  DustDissolveDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  One screen that shows the range of DustDissolve. Scroll it and tap things (a coupon, the eye, a bubble).
//  Nothing in the layout moves: a dissolving view keeps its place.
//
//    Coupons            tap a coupon: it shimmers, then flows into the pill
//    Hide balance       the amount turns to dust, dots take its place
//    Hide password      the visible text turns to dust, dots take its place
//    Messages           bubbles blow away toward the side they sit on
//
//  One DustDissolveScope around the whole scroll view draws the dust for all of them.
//
import SwiftUI
import DustDissolve

// MARK: - Shared theme

struct DemoTheme {
    let bg: Color, fg: Color, sub: Color, card: Color, line: Color, onAccent: Color

    static let green = Color(red: 0.25, green: 0.82, blue: 0.45)

    init(dark: Bool) {
        if dark {
            bg = .black; fg = .white; sub = .white.opacity(0.6); card = .white.opacity(0.05)
            line = .white.opacity(0.12); onAccent = .black
        } else {
            bg = Color(white: 0.97); fg = .black; sub = .black.opacity(0.55); card = .black.opacity(0.03)
            line = .black.opacity(0.10); onAccent = .white
        }
    }
}

// MARK: - Showcase

public struct DustDissolveExamples: View {
    private let dark: Bool
    private let onBack: (() -> Void)?
    @StateObject private var model = ShowcaseModel()

    public init(dark: Bool = true, onBack: (() -> Void)? = nil) { self.dark = dark; self.onBack = onBack }

    public var body: some View {
        let th = DemoTheme(dark: dark)
        DustDissolveScope(model.all) {
            DemoScreen(title: "Dust Dissolve", dark: dark, background: th.bg, titleColor: th.fg, onBack: onBack) {
                VStack(spacing: 14) {
                    SectionCard(title: "Coupons", th: th) {
                        CouponsCard(dusts: model.coupons, th: th)
                    }

                    BalanceSection(model: model, th: th)
                    PasswordSection(model: model, th: th)
                    MessagesSection(model: model, th: th)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview("Dark") { DustDissolveExamples() }
