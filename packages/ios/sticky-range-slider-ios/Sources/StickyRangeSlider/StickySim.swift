//
//  StickySim.swift
//  StickyRangeSlider
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// Per-frame spring simulation for the two handles and the merge amount.
///
/// A reference type on purpose: it is stepped every frame from a `TimelineView`, which would
/// otherwise invalidate SwiftUI state sixty times a second.
final class StickySim {
    var xLo: CGFloat = 0, vLo: CGFloat = 0
    var xHi: CGFloat = 0, vHi: CGFloat = 0
    /// 0 = two pills, 1 = one fused pill.
    var m: CGFloat = 0, vm: CGFloat = 0

    /// Softer follow spring, used while a tapped handle glides to its new spot.
    var glide = false
    private var last: Date?
    private(set) var primed = false

    func step(_ now: Date, tLo: CGFloat, tHi: CGFloat, tM: CGFloat,
              timing: StickyTiming, instant: Bool = false) {
        // `instant` (Reduce Motion) jumps straight to the targets.
        guard primed, let prev = last, !instant else {
            xLo = tLo; xHi = tHi; m = tM
            vLo = 0; vHi = 0; vm = 0
            primed = true; last = now
            return
        }
        last = now
        let dt = min(CGFloat(now.timeIntervalSince(prev)), 1.0 / 20.0)
        guard dt > 0 else { return }

        let follow = StickyMath.omega(response: glide ? timing.glide : timing.follow)
        let zFollow = glide ? StickyDamping.glide : StickyDamping.follow
        let merge = StickyMath.omega(response: timing.merge)

        // Sub-step so stiff springs stay stable even after a dropped frame.
        let n = max(1, Int((dt / (1.0 / 240.0)).rounded(.up)))
        let h = dt / CGFloat(n)
        for _ in 0..<n {
            Self.spring(&xLo, &vLo, tLo, follow, zFollow, h)
            Self.spring(&xHi, &vHi, tHi, follow, zFollow, h)
            Self.spring(&m, &vm, tM, merge, StickyDamping.merge, h)
        }
    }

    /// True once everything has come to rest on its target, so the timeline can pause.
    func isSettled(tLo: CGFloat, tHi: CGFloat, tM: CGFloat) -> Bool {
        primed
            && abs(xLo - tLo) < 0.05 && abs(xHi - tHi) < 0.05 && abs(m - tM) < 0.002
            && abs(vLo) < 0.5 && abs(vHi) < 0.5 && abs(vm) < 0.02
    }

    private static func spring(_ x: inout CGFloat, _ v: inout CGFloat,
                               _ target: CGFloat, _ w: CGFloat, _ z: CGFloat, _ h: CGFloat) {
        let a = w * w * (target - x) - 2 * z * w * v
        v += a * h
        x += v * h
    }
}
