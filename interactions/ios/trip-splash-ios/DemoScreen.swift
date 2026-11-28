//
//  DemoScreen.swift
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Shared demo frame. Title on the left, a plain "@repgem" label on the right, your content below.
//  Pass `onBack` to show a back chevron before the title (an app that pushes the demo does; a package
//  preview leaves it out).
//  Source of truth: common/ios/DemoScreen.swift in the catalog repo. Do not edit the copies inside
//  items; edit this file and run `bun run sync-common`.
//
import SwiftUI

/// Spacing shared by every demo screen. The Android frame uses the same numbers in dp.
enum DemoLayout {
    static let side: CGFloat = 20
    static let top: CGFloat = 12
    static let bottom: CGFloat = 16
    static let gap: CGFloat = 12
}

struct DemoScreen<Content: View>: View {
    let title: String
    var dark: Bool = true
    var background: Color
    var titleColor: Color? = nil
    var scrolls: Bool = true
    /// When set, a back chevron appears before the title and calls this. Empty by default.
    var onBack: (() -> Void)? = nil
    @ViewBuilder var content: Content

    private var ink: Color { titleColor ?? (dark ? .white : Color(white: 0.1)) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: DemoLayout.gap) {
                HStack(spacing: 10) {
                    if let onBack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(width: 32, height: 32, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Back")
                    }
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                }
                Spacer(minLength: DemoLayout.gap)
                Text("@repgem")
                    .font(.system(size: 13, weight: .medium))
                    .opacity(0.5)
            }
            .foregroundStyle(ink)
            .padding(.horizontal, DemoLayout.side)
            .padding(.top, DemoLayout.top)
            .padding(.bottom, DemoLayout.bottom)

            if scrolls {
                ScrollView(showsIndicators: false) {
                    content.frame(maxWidth: .infinity)
                }
            } else {
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(background.ignoresSafeArea())
        .preferredColorScheme(dark ? .dark : .light)
    }
}
