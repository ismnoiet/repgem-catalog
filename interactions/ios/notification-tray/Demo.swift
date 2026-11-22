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
    DemoScreen(title: "Notification Icon Tray", dark: true, background: .black, scrolls: false) {
        AndroidStyleNotificationIconTray()
    }
}
