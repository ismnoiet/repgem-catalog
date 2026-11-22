//
//  Examples.swift
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Dark-theme demos. Open Package.swift in Xcode, pick the DragableCardsDemo scheme and use the
//  canvas (or show `DragableCardsExamples()` from an app). Add demos by appending a `DemoSection`.
//
import SwiftUI

public struct DragableCardsExamples: View {
    private let onBack: (() -> Void)?
    public init(onBack: (() -> Void)? = nil) { self.onBack = onBack }

    public var body: some View {
        DemoPage(theme: .dark, onBack: onBack)
    }
}

/// One page for both themes, so dark and light show exactly the same layout.
struct DemoPage: View {
    let theme: DemoTheme
    var onBack: (() -> Void)? = nil

    var body: some View {
        DemoScreen(title: "Dragable Cards", dark: !theme.isLight, background: theme.page, titleColor: theme.text, onBack: onBack) {
            VStack(spacing: 30) {
                Text("Long-press a card, then drag it anywhere")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.muted)
                DemoSection(title: "Project board", theme: theme) { ProjectBoard(theme: theme) }
                DemoSection(title: "Hiring pipeline (reports every move)", theme: theme) { HiringBoard(theme: theme) }
                DemoSection(title: "Music queue (live equalizer, live totals)", theme: theme) { MusicQueue(theme: theme) }
                DemoSection(title: "Weekly meals (five columns, scrolls as you drag)", theme: theme) { MealPlanner(theme: theme) }
                DemoSection(title: "Trip planner (a day turns amber when overbooked)", theme: theme) { TripPlanner(theme: theme) }
            }
            .padding(.bottom, 24)
        }
    }
}

#Preview("Dark") {
    DragableCardsExamples()
}
