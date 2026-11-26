//
//  FireworkFlourishModifier.swift
//  FireworkFlourish
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

private struct FireworkTriggerModifier<T: Equatable>: ViewModifier {
    let trigger: T
    let duration: TimeInterval
    let style: FireworkStyle

    @State private var start: Double = 0
    @State private var running = false
    @State private var cleanup: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .overlay {
                if running {
                    FireworkFlourish(style: style, start: start, end: start + duration)
                }
            }
            .onChange(of: trigger) {
                start = Date.timeIntervalSinceReferenceDate
                running = true
                cleanup?.cancel()
                // Keep the layer until the last particle has faded, then remove it so it costs nothing.
                cleanup = Task {
                    try? await Task.sleep(for: .seconds(duration + style.totalLife))
                    if !Task.isCancelled { running = false }
                }
            }
    }
}

public extension View {
    /// Plays fireworks over this view for `duration` seconds each time `trigger` changes.
    /// Apply `.clipShape(...)` after it to keep the effect inside a rounded card.
    ///
    ///     card
    ///         .fireworkFlourish(trigger: levelUps, duration: 2, style: .milestone)
    ///         .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    func fireworkFlourish<T: Equatable>(
        trigger: T,
        duration: TimeInterval = 2.0,
        style: FireworkStyle = .card
    ) -> some View {
        modifier(FireworkTriggerModifier(trigger: trigger, duration: duration, style: style))
    }

    /// Continuous fireworks over this view while `active` is true.
    ///
    ///     row.fireworkFlourish(active: isBirthdayToday, style: .subtle)
    func fireworkFlourish(active: Bool = true, style: FireworkStyle = .card) -> some View {
        overlay { FireworkFlourish(style, active: active) }
    }
}
