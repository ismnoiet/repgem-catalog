//
//  ExamplesLight.swift
//  StickyRangeSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Light-theme demos, same layout as the dark ones. Open Package.swift in Xcode, pick the
//  StickyRangeSliderDemo scheme and use the canvas (or call `StickyRangeSliderExamplesLight()`).
//
import SwiftUI

public struct StickyRangeSliderExamplesLight: View {
    private let onBack: (() -> Void)?
    public init(onBack: (() -> Void)? = nil) { self.onBack = onBack }

    public var body: some View {
        let theme = DemoTheme(dark: false)
        DemoScreen(title: "Sticky Range Slider", dark: false, background: theme.page, titleColor: theme.ink, onBack: onBack) {
            ExampleStack(theme: theme)
        }
    }
}

#Preview { StickyRangeSliderExamplesLight() }
