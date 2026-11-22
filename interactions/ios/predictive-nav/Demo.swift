//
//  Demo.swift
//
//  Author: ismnoiet
//  Minimum supported: iOS 17
//
//  Previews the interaction inside the shared demo frame (title and @repgem). Not needed in your app.
//
import SwiftUI

#Preview("Demo frame") {
    DemoScreen(title: "Edge-Swipe Navigation", dark: true, background: .black, scrolls: false) {
        ClaudeStyleNavigation()
    }
}
