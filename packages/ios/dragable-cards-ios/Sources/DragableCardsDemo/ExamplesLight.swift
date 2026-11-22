//
//  ExamplesLight.swift
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Light-theme demos, same layout as the dark page. Open Package.swift in Xcode, pick the
//  DragableCardsDemo scheme and use the canvas (or show `DragableCardsExamplesLight()` from an app).
//
import SwiftUI

public struct DragableCardsExamplesLight: View {
    private let onBack: (() -> Void)?
    public init(onBack: (() -> Void)? = nil) { self.onBack = onBack }

    public var body: some View {
        DemoPage(theme: .light, onBack: onBack)
    }
}

#Preview("Light") {
    DragableCardsExamplesLight()
}
