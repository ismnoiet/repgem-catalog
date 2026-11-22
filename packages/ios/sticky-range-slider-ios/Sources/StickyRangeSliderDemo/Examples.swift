//
//  Examples.swift
//  StickyRangeSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Dark-theme demos. Open Package.swift in Xcode, pick the StickyRangeSliderDemo scheme and use
//  the canvas (or call `StickyRangeSliderExamples()` from an app). Add demos by appending a
//  `DemoSection` in `ExampleStack` (DemoSupport.swift).
//
import SwiftUI

public struct StickyRangeSliderExamples: View {
    private let onBack: (() -> Void)?
    public init(onBack: (() -> Void)? = nil) { self.onBack = onBack }

    public var body: some View {
        let theme = DemoTheme(dark: true)
        DemoScreen(title: "Sticky Range Slider", dark: true, background: theme.page, titleColor: theme.ink, onBack: onBack) {
            ExampleStack(theme: theme)
        }
    }
}

#Preview { StickyRangeSliderExamples() }
