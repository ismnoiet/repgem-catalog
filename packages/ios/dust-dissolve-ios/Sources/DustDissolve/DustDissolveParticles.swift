//
//  DustDissolveParticles.swift
//  DustDissolve
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  The dust: a cloud of round pastel dots born exactly where the shader eats the view away,
//  hanging for a moment, then flowing to a target, drifting away, or bursting outward.
//
import SwiftUI

// MARK: - Erosion field (shared with DustDissolve.metal)

/// A smooth erosion field over the view (0…~1.05). A pixel disappears when the shader's threshold
/// passes its value, and a particle is born at the same moment.
/// Keep in sync with `dissolveField()` in DustDissolve.metal.
func dissolveField(_ nx: Double, _ ny: Double, _ dir: DustDissolveDirection) -> Double {
    let x: Double, y: Double
    switch dir {
    case .leftToRight: x = nx;     y = ny
    case .rightToLeft: x = 1 - nx; y = ny
    case .topToBottom: x = ny;     y = nx
    case .bottomToTop: x = 1 - ny; y = nx
    case .centerOut:
        let dx = nx - 0.5, dy = ny - 0.5
        x = min((dx * dx + dy * dy).squareRoot() * 1.4, 1); y = nx + ny
    }
    let a = sin(x * 17 + y * 6) * 0.5 + sin(x * 7 - y * 13 + 1.7) * 0.35 + sin(y * 21 + x * 3 + 0.6) * 0.25
    return x * 0.82 + (a * 0.5 + 0.5) * 0.22
}

// MARK: - Particle model

struct SplitMix: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 {
        s &+= 0x9E3779B97F4A7C15
        var z = s
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct DustParticle {
    let nx: Double, ny: Double      // birth position inside the view (0…1)
    let spawn: Double               // moment the pixel at this spot is eroded away
    let dx: Double, dy: Double      // slow drift while the cloud hangs (mostly left / up)
    let flightDelay: Double
    let dur: Double
    let jx: Double, jy: Double      // lateral scatter
    let k: Double                   // distance factor for drift / burst
    let aj: Double                  // angle jitter for drift / burst
    let size: Double
    let colorIndex: Int
    let twinkle: Double

    static func make(_ c: DustDissolveConfiguration) -> [DustParticle] {
        var g = SplitMix(s: c.seed)
        let paletteCount = max(c.palette.count, 1)
        return (0..<max(c.particleCount, 0)).map { _ in
            var nx: Double, ny: Double
            switch c.shape {
            case .rectangle:
                nx = Double.random(in: 0...1, using: &g)
                ny = Double.random(in: 0.04...0.96, using: &g)
            case .ellipse:
                let a = Double.random(in: 0...(2 * Double.pi), using: &g)
                let r = Double.random(in: 0...1, using: &g).squareRoot() * 0.96
                nx = 0.5 + 0.5 * r * cos(a)
                ny = 0.5 + 0.5 * r * sin(a)
            }
            let f = dissolveField(nx, ny, c.direction) + Double.random(in: -0.05...0.05, using: &g)
            let p = min(max((f + 0.06) / 1.2, 0), 1)
            return DustParticle(
                nx: nx, ny: ny,
                spawn: c.dissolveStart + p * (c.dissolveEnd - c.dissolveStart),
                dx: -Double.random(in: 12...48, using: &g),
                dy: Double.random(in: -22...10, using: &g),
                flightDelay: Double.random(in: 0...max(c.flightStagger, 0.0001), using: &g),
                dur: Double.random(in: c.flightDuration, using: &g),
                jx: Double.random(in: -1...1, using: &g),
                jy: Double.random(in: -1...1, using: &g),
                k: Double.random(in: 0.6...1.4, using: &g),
                aj: Double.random(in: -1...1, using: &g),
                size: Double.random(in: c.dotSize, using: &g),
                colorIndex: Int.random(in: 0..<paletteCount, using: &g),
                twinkle: Double.random(in: 0...6.28, using: &g)
            )
        }
    }
}

// MARK: - Drawing

private func bezier(_ a: Double, _ b: Double, _ c: Double, _ d: Double, _ u: Double) -> Double {
    let m = 1 - u
    return m*m*m*a + 3*m*m*u*b + 3*m*u*u*c + u*u*u*d
}

/// Draws one frame of dust. `source` and `target` are in the Canvas's own coordinate space.
func drawDust(_ ctx: inout GraphicsContext,
              size: CGSize,
              t: Double,
              source c: CGRect,
              target: CGRect?,
              particles: [DustParticle],
              config cfg: DustDissolveConfiguration) {
    let end = cfg.flightStart + cfg.flightStagger + cfg.flightDuration.upperBound + 0.05
    guard t > cfg.dissolveStart, t < end, !cfg.palette.isEmpty else { return }

    var motion = cfg.motion
    var isFlow = false
    if case .flowToTarget = motion {
        if target == nil { motion = .burst(distance: 120) } else { isFlow = true }
    }

    let w = Double(size.width), h = Double(size.height)
    let p0x = Double(c.midX), p0y = Double(c.midY)
    let p3x = target.map { Double($0.midX) } ?? p0x
    let p3y = target.map { Double($0.midY) } ?? p0y
    let p1x = w * 1.02, p1y = p0y + h * 0.04
    let p2x = w * 0.82, p2y = h * 0.80
    let shrink = isFlow ? 1 - 0.3 * smooth(ramp(t, cfg.flightStart, cfg.flightStart + 1.05)) : 1

    for (i, p) in particles.enumerated() {
        let age = t - p.spawn
        if age < 0 { continue }

        let ownX = Double(c.minX) + p.nx * Double(c.width)
        let ownY = Double(c.minY) + p.ny * Double(c.height)
        let drift = easeOut(min(age / 0.55, 1))
        let baseX = ownX + p.dx * drift
        let baseY = ownY + p.dy * drift

        let fs = max(p.spawn + 0.05, cfg.flightStart + p.flightDelay)
        let u = ramp(t, fs, fs + p.dur)
        let e = smooth(u)

        var x = baseX, y = baseY
        var fadeStart = 0.9
        switch motion {
        case .flowToTarget:
            let k = sin(Double.pi * e)
            x = bezier(p0x, p1x, p2x, p3x, e) + (baseX - p0x) * (1 - e) + p.jx * 26 * k
            y = bezier(p0y, p1y, p2y, p3y, e) + (baseY - p0y) * (1 - e) + p.jy * 26 * k
        case .drift(let angle, let distance):
            let a = angle.radians + p.aj * 0.7
            let dist = Double(distance) * p.k
            let wob = p.jy * 18 * sin(Double.pi * e) + sin(e * 7 + p.twinkle) * 5 * e
            x = baseX + cos(a) * dist * e - sin(a) * wob
            y = baseY + sin(a) * dist * e + cos(a) * wob
            fadeStart = 0.45
        case .burst(let distance):
            let a = atan2(ownY - p0y, ownX - p0x) + p.aj * 0.5
            let dist = Double(distance) * p.k
            x = baseX + cos(a) * dist * e
            y = baseY + sin(a) * dist * e
            fadeStart = 0.40
        }

        let tw = 0.8 + 0.2 * sin(t * 16 + p.twinkle)
        let alpha = ramp(age, 0, 0.06) * (1 - ramp(u, fadeStart, 1)) * tw
        if alpha <= 0.01 { continue }

        let s = p.size * shrink
        let color = cfg.palette[p.colorIndex % cfg.palette.count].opacity(alpha)
        ctx.fill(Path(ellipseIn: CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)), with: .color(color))

        // A few of the dots flare into 4-point sparkles.
        if cfg.sparkleEvery > 0, i % cfg.sparkleEvery == 0 {
            let env = max(0, sin(t * 11 + p.twinkle))
            let r = 3 + 7 * env * env
            let pts: [(Double, Double)] = [(0, -1), (0.16, -0.16), (1, 0), (0.16, 0.16),
                                           (0, 1), (-0.16, 0.16), (-1, 0), (-0.16, -0.16)]
            var star = Path()
            for (j, q) in pts.enumerated() {
                let pp = CGPoint(x: x + q.0 * r, y: y + q.1 * r)
                if j == 0 { star.move(to: pp) } else { star.addLine(to: pp) }
            }
            star.closeSubpath()
            ctx.fill(star, with: .color(.white.opacity(alpha * (0.4 + 0.6 * env))))
        }
    }
}
