//
//  Stages.swift
//  FireworkFlourishDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

// Dark stages for the dark theme, pastel stages for the light one. On the light stages the fireworks
// switch to normal blending and deeper colors (`fireworkLightBackground`), since additive light can't show.

let night = LinearGradient(
    colors: [Color(red: 0.17, green: 0.16, blue: 0.18), Color(red: 0.05, green: 0.05, blue: 0.06)],
    startPoint: .topTrailing, endPoint: .bottomLeading)

let wine = LinearGradient(
    colors: [Color(red: 0.30, green: 0.10, blue: 0.25), Color(red: 0.08, green: 0.05, blue: 0.12)],
    startPoint: .topTrailing, endPoint: .bottomLeading)

let midnight = LinearGradient(
    colors: [Color(red: 0.06, green: 0.06, blue: 0.07), Color(red: 0.02, green: 0.02, blue: 0.03)],
    startPoint: .top, endPoint: .bottom)

let glass = RoundedRectangle(cornerRadius: 28, style: .continuous)

// MARK: - Light stages (used when the page is light)

let day = LinearGradient(
    colors: [Color(red: 0.90, green: 0.90, blue: 0.99), Color(red: 0.97, green: 0.96, blue: 1.00)],
    startPoint: .topTrailing, endPoint: .bottomLeading)

let blush = LinearGradient(
    colors: [Color(red: 0.99, green: 0.88, blue: 0.92), Color(red: 1.00, green: 0.96, blue: 0.97)],
    startPoint: .topTrailing, endPoint: .bottomLeading)

let sky = LinearGradient(
    colors: [Color(red: 0.84, green: 0.91, blue: 1.00), Color(red: 0.95, green: 0.97, blue: 1.00)],
    startPoint: .top, endPoint: .bottom)

// MARK: - Section wrapper

private struct StageLightKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    /// True when the page around the stages is light: stages switch to pastel backdrops, dark text and
    /// fireworks drawn for a light surface.
    var stageLight: Bool {
        get { self[StageLightKey.self] }
        set { self[StageLightKey.self] = newValue }
    }
}

/// Title + a rounded stage with its own backdrop (dark by default, a pastel one on a light page).
struct DemoSection<Content: View>: View {
    @Environment(\.stageLight) private var light
    let title: String
    let note: String
    var backdrop: LinearGradient = night
    var lightBackdrop: LinearGradient = day
    var height: CGFloat? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // The title is shown in the subtitle style; `note` is kept for API compatibility but not shown.
            Text(title).font(.footnote.weight(.medium)).foregroundStyle(light ? Color.black.opacity(0.5) : Color.secondary)
                .padding(.horizontal, 4)

            content
                .environment(\.colorScheme, light ? .light : .dark)
                .fireworkLightBackground(light)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(light ? lightBackdrop : backdrop)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.black.opacity(light ? 0.06 : 0), lineWidth: 0.75))
                .shadow(color: .black.opacity(light ? 0.07 : 0), radius: 14, y: 6)
        }
    }
}

/// Card surface inside a stage: frosted material on dark stages, a crisp white card on light ones.
private struct GlassBackground<S: Shape>: ViewModifier {
    @Environment(\.stageLight) private var light
    let shape: S

    func body(content: Content) -> some View {
        if light {
            content
                .background(Color.white.opacity(0.78), in: shape)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}

extension View {
    func glassBackground<S: Shape>(_ shape: S) -> some View { modifier(GlassBackground(shape: shape)) }
}

/// Quiet frosted capsule used by every demo button: primary-colored text on a faint tint with a hairline.
struct QuietButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.stageLight) private var light

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(light ? Color.white : Color.primary)
            .padding(.horizontal, 20).padding(.vertical, 11)
            .background(light ? Color.black.opacity(configuration.isPressed ? 0.7 : 0.85)
                              : Color.primary.opacity(configuration.isPressed ? 0.20 : 0.10), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(light ? 0 : 0.15), lineWidth: 0.75))
            .opacity(isEnabled ? 1 : 0.4)
    }
}
