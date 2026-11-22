//
//  DustDissolveController.swift
//  DustDissolve
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// Owns one dust-dissolve run. Create it once, call `fire()` when the coupon is applied.
///
///     @StateObject private var dust = DustDissolveController()
///     dust.fire()                     // run the effect
///     dust.reset()                    // back to the intact coupon
///
/// Host UI that has to move in step with the dust (the price, a banner…) reads
/// `elapsed(at:)` inside a `TimelineView(.animation(paused: !dust.isActive))`.
@MainActor
public final class DustDissolveController: ObservableObject, Identifiable {
    public let configuration: DustDissolveConfiguration

    /// When `fire()` was called. `nil` while idle.
    @Published public private(set) var startDate: Date?
    /// `true` while the sequence runs (frames are being produced), `false` when idle or finished.
    @Published public private(set) var isActive = false

    public nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }

    let particles: [DustParticle]
    private var generation = 0

    public init(_ configuration: DustDissolveConfiguration = .default) {
        self.configuration = configuration
        self.particles = DustParticle.make(configuration)
    }

    /// Runs the effect from the start (restarts it if it is already running).
    public func fire() {
        generation += 1
        let g = generation
        startDate = Date()
        isActive = true
        let total = configuration.total
        Task {
            try? await Task.sleep(for: .seconds(total + 0.1))
            if g == generation { isActive = false }
        }
    }

    /// Puts the coupon back, intact.
    public func reset() {
        generation += 1
        startDate = nil
        isActive = false
    }

    /// Seconds since `fire()`. `nil` while idle. Once the sequence is over it returns a value past
    /// `configuration.total`, so end states hold without a running timeline.
    public func elapsed(at date: Date) -> Double? {
        guard let s = startDate else { return nil }
        return isActive ? date.timeIntervalSince(s) : configuration.total + 1
    }

    /// Suspends until the sequence has finished (`isActive` is `false`).
    public func finished() async {
        while isActive { try? await Task.sleep(for: .milliseconds(40)) }
    }
}
