//
//  Examples.swift
//  FireworkFlourishDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  One long scrolling screen that shows the range of FireworkFlourish. Tap things, drag the sliders.
//
//    New Year countdown    3 → 0, then a full-stage finale
//    Anniversary card      continuous, romance palette (just watch)
//    Scoreboard goal       neon one-shot on whichever team scores
//    Achievement toast     slides in, celebrates inside the capsule, leaves
//    Calendar sparkle      quiet twinkle marking today's date
//    Style lab             every preset and palette with live sliders
//
import SwiftUI
import FireworkFlourish

// MARK: - Showcase

public struct FireworkFlourishExamples: View {
    private let dark: Bool
    private let onBack: (() -> Void)?

    public init(dark: Bool = true, onBack: (() -> Void)? = nil) {
        self.dark = dark
        self.onBack = onBack
    }

    public var body: some View {
        let background = dark ? Color(red: 0.03, green: 0.03, blue: 0.04) : Color(red: 0.95, green: 0.95, blue: 0.97)
        DemoScreen(title: "Firework Flourish", dark: dark, background: background, onBack: onBack) {
            LazyVStack(spacing: 28) {
                DemoSection(title: "New Year countdown",
                            note: "3 → 0, then a full-stage finale.", backdrop: midnight, lightBackdrop: sky) {
                    CountdownDemo()
                }
                DemoSection(title: "Anniversary card",
                            note: "Continuous romance palette, just watch.", backdrop: wine, lightBackdrop: blush) {
                    AnniversaryDemo()
                }
                DemoSection(title: "Scoreboard goal",
                            note: "Neon one-shot on whichever team scores.") {
                    ScoreboardDemo()
                }
                DemoSection(title: "Achievement toast",
                            note: "Slides in, celebrates inside the capsule, leaves.", height: 220) {
                    AchievementToastDemo()
                }
                DemoSection(title: "Calendar today sparkle",
                            note: "Quiet twinkle marking today's date.") {
                    CalendarSparkleDemo()
                }
                DemoSection(title: "Style lab",
                            note: "Every preset and palette with live sliders. Tune your own look.") {
                    StyleLabDemo()
                }
            }
            .environment(\.stageLight, !dark)
            .padding(.horizontal, DemoLayout.side)
            .padding(.bottom, 32)
        }
    }
}

#Preview("Dark") { FireworkFlourishExamples() }
