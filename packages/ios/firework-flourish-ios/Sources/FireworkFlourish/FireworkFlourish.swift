//
//  FireworkFlourish.swift
//  FireworkFlourish
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

// MARK: - Stateless randomness

/// A hash instead of stored particle state: every rocket and particle is a pure function of its
/// index, so nothing is allocated or kept between frames and the loop never repeats a fixed clip.
func hash01(_ seed: Int, _ k: Int) -> Double {
    var z = UInt64(truncatingIfNeeded: seed &* 7919 &+ k &* 104729) &+ 0x9E3779B97F4A7C15
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    z = z ^ (z >> 31)
    return Double(z % 1_000_000) / 1_000_000
}

/// A layer of fireworks that fills its parent. Rockets rise, flash and burst into twinkling dots
/// that fade out. Put it over any view, usually clipped to the shape that should hold the effect:
///
///     card
///         .overlay { FireworkFlourish(.card) }
///         .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
///
///     FireworkFlourish(.milestone, active: isToday)
///
/// For a one-shot celebration use `.fireworkFlourish(trigger:duration:style:)` instead.
/// Reduce Motion is respected: nothing is drawn.
public struct FireworkFlourish: View {
    private let style: FireworkStyle
    private let active: Bool
    private let start: Double
    private let end: Double?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.fireworkLightBackground) private var onLight

    /// Continuous fireworks. `active: false` fades the layer out and pauses the timeline, so an idle
    /// layer costs nothing.
    public init(_ style: FireworkStyle = .card, active: Bool = true) {
        self.style = style
        self.active = active
        self.start = 0
        self.end = nil
    }

    /// Fireworks that start at `start` and stop launching rockets at `end`
    /// (times are `Date.timeIntervalSinceReferenceDate`). Used by the one-shot modifier.
    init(style: FireworkStyle, start: Double, end: Double?) {
        self.style = style
        self.active = true
        self.start = start
        self.end = end
    }

    public var body: some View {
        if reduceMotion {
            Color.clear.allowsHitTesting(false)
        } else {
            TimelineView(.animation(paused: !active)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    draw(&ctx, size, t)
                }
            }
            .opacity(active ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: active)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Drawing

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let s = style
        guard !s.palettes.isEmpty, s.interval > 0 else { return }

        // Each one-shot gets its own seed, so two celebrations never look identical.
        let seedBase = Int((start * 1000).truncatingRemainder(dividingBy: 100_000)) * 1000
        let first = max(0, Int(floor((t - s.totalLife - start) / s.interval)))
        let last = Int(floor((t - start) / s.interval))
        guard first <= last else { return }

        for i in first...last {
            let spawn = start + Double(i) * s.interval + hash01(i, 1) * 0.12 * s.interval
            if let end, spawn > end { continue }
            let age = t - spawn
            if age < 0 || age > s.totalLife { continue }
            let id = seedBase + i

            let cx = size.width * (s.xRange.lowerBound + (s.xRange.upperBound - s.xRange.lowerBound) * hash01(id, 2))
            let cy = size.height * (s.yRange.lowerBound + (s.yRange.upperBound - s.yRange.lowerBound) * hash01(id, 3))
            let rawPal = s.palettes[Int(hash01(id, 4) * Double(s.palettes.count)) % s.palettes.count]
            let pal: FireworkColors = onLight ? (lightSurfaceTone(rawPal.0), lightSurfaceTone(rawPal.1)) : rawPal
            let scale = CGFloat(0.7 + 0.6 * hash01(id, 5))

            // 1. Rocket trail
            if s.showRockets && age < s.rocketTime {
                let p = age / s.rocketTime
                let e = 1 - pow(1 - p, 2.2)
                let sx = cx + (hash01(id, 6) - 0.5) * 50
                let sy = size.height + 6
                let head = CGPoint(x: sx + (cx - sx) * e, y: sy + (cy - sy) * e)
                let tp = max(0, e - 0.16)
                let tail = CGPoint(x: sx + (cx - sx) * tp, y: sy + (cy - sy) * tp)
                var path = Path()
                path.move(to: tail)
                path.addLine(to: head)
                let trail: Color = onLight ? pal.0.opacity(0.6 * (1 - p * 0.4)) : .white.opacity(0.75 * (1 - p * 0.4))
                ctx.stroke(path, with: .color(trail), lineWidth: onLight ? 0.9 : 0.7)
            }

            // 2. Glow ball: white, then tinted, fading as it bursts
            let flashStart = s.rocketTime * 0.8
            if age >= flashStart && age < s.rocketTime + s.flashTime {
                let p = (age - flashStart) / (s.flashTime + s.rocketTime * 0.2)
                let r: CGFloat = (5 + 3 * CGFloat(sin(p * .pi))) * max(0.8, scale)
                let fade = 1 - pow(p, 3)
                var g = ctx
                g.blendMode = onLight ? .normal : .plusLighter
                let halo: [Color] = onLight
                    ? [pal.0.opacity(0.45 * fade), pal.0.opacity(0.15 * fade), .clear]
                    : [.white.opacity(0.55 * fade), pal.0.opacity(0.18 * fade), .clear]
                g.fill(Path(ellipseIn: CGRect(x: cx - r * 3, y: cy - r * 3, width: r * 6, height: r * 6)),
                       with: .radialGradient(Gradient(colors: halo),
                           center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r * 3))
                g.fill(Path(ellipseIn: CGRect(x: cx - r * 0.55, y: cy - r * 0.55, width: r * 1.1, height: r * 1.1)),
                       with: .color((p < 0.5 && !onLight ? Color.white : pal.0).opacity(fade)))
            }

            // 3. Particles: fast out, then drift, twinkle and fade
            let ba = age - s.rocketTime
            if ba > 0 && ba < s.burstLife {
                let life = ba / s.burstLife
                let baseFade = pow(1 - life, 1.4)
                let ease = CGFloat(1 - exp(-4.2 * ba))
                let drop = 0.5 * s.gravity * CGFloat(ba * ba)
                var g = ctx
                g.blendMode = onLight ? .normal : .plusLighter
                let dotScale: CGFloat = onLight ? 1.9 : 1   // dark dots on a light surface need more body
                for k in 0..<s.particles {
                    let ang = hash01(id, 100 + k) * 2 * .pi
                    let reach = s.maxRadius * scale * CGFloat(sqrt(hash01(id, 200 + k)))   // fills the disc
                    let px = cx + CGFloat(cos(ang)) * reach * ease
                    let py = cy + CGFloat(sin(ang)) * reach * ease + drop
                    let tw = 0.55 + 0.45 * sin(ba * (9 + 10 * hash01(id, 300 + k)) + hash01(id, 400 + k) * 6.28)
                    // On a light surface a steadier, stronger dot reads better than a faint twinkle.
                    let o = onLight ? min(1, baseFade * (0.65 + 0.35 * tw) * 1.5) : baseFade * tw
                    if o < 0.02 { continue }
                    let col = hash01(id, 500 + k) < 0.5 ? pal.0 : pal.1
                    let d: CGFloat = (1.3 + 0.5 * CGFloat(hash01(id, 600 + k))) * dotScale
                    g.fill(Path(ellipseIn: CGRect(x: px - d / 2, y: py - d / 2, width: d, height: d)),
                           with: .color(col.opacity(o)))
                }
            }
        }
    }
}
