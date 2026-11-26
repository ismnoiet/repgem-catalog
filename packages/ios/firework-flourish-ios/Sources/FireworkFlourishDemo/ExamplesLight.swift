//
//  ExamplesLight.swift
//  FireworkFlourishDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// Same demo, starting in the light theme: pastel stages with fireworks drawn for a light surface.
public struct FireworkFlourishExamplesLight: View {
    private let onBack: (() -> Void)?
    public init(onBack: (() -> Void)? = nil) { self.onBack = onBack }
    public var body: some View { FireworkFlourishExamples(dark: false, onBack: onBack) }
}

#Preview("Light") { FireworkFlourishExamplesLight() }
