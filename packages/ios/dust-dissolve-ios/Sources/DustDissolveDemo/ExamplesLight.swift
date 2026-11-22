//
//  ExamplesLight.swift
//  DustDissolveDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI
import DustDissolve

/// Same demo, starting in the light theme.
public struct DustDissolveExamplesLight: View {
    private let onBack: (() -> Void)?
    public init(onBack: (() -> Void)? = nil) { self.onBack = onBack }
    public var body: some View { DustDissolveExamples(dark: false, onBack: onBack) }
}

#Preview("Light") { DustDissolveExamplesLight() }
