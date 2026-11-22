//
//  CouponsExample.swift
//  DustDissolveDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Two coupons. Tap one and it shimmers, then turns to dust and flows into the "Applied" pill. Each
//  coupon has its own controller, so they dissolve independently. The DustDissolve calls are
//  `.dustSource(_:)` (the coupon), `.dustTarget()` (where the dust lands), `dust.fire()` and the scope
//  that draws the dust (in Examples.swift).
//
import SwiftUI
import DustDissolve

// MARK: - Coupon ticket

private struct TicketShape: Shape {
    var notchX: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: r, cornerSize: CGSize(width: 9, height: 9))
        p.addEllipse(in: CGRect(x: notchX - 4, y: r.minY - 4, width: 8, height: 8))
        p.addEllipse(in: CGRect(x: notchX - 4, y: r.maxY - 4, width: 8, height: 8))
        return p
    }
}

private struct Ticket: View {
    enum Kind { case mochi70, mochi50 }
    let kind: Kind

    private var code: String {
        switch kind { case .mochi70: return "MOCHI70"; case .mochi50: return "MOCHI50" }
    }
    private var pct: String {
        switch kind { case .mochi70: return "70%"; case .mochi50: return "50%" }
    }
    private var gradient: LinearGradient {
        switch kind {
        case .mochi70:
            return LinearGradient(colors: [
                Color(red: 0.80, green: 0.93, blue: 1.0), Color(red: 0.86, green: 0.80, blue: 1.0),
                Color(red: 1.0, green: 0.85, blue: 0.93), Color(red: 1.0, green: 0.95, blue: 0.80),
                Color(red: 0.80, green: 1.0, blue: 0.93), Color(red: 0.85, green: 0.88, blue: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mochi50:
            return LinearGradient(colors: [Color(red: 0.86, green: 0.80, blue: 1.0), Color(red: 0.74, green: 0.66, blue: 1.0)],
                                  startPoint: .top, endPoint: .bottom)
        }
    }

    var body: some View {
        let w: CGFloat = 138
        let notch: CGFloat = 104
        ZStack {
            TicketShape(notchX: notch).fill(gradient, style: FillStyle(eoFill: true))
            Path { p in
                p.move(to: CGPoint(x: notch, y: 6))
                p.addLine(to: CGPoint(x: notch, y: 38))
            }
            .stroke(Color.black.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("mochi").font(.system(size: 5, weight: .semibold))
                    Text(code).font(.system(size: 14, weight: .bold))
                }
                .padding(.leading, 9)
                Spacer(minLength: 0)
                Text(pct).font(.system(size: 13, weight: .semibold)).frame(width: w - 104)
            }
            .foregroundStyle(Color.black.opacity(0.88))
        }
        .frame(width: w, height: 44)
    }
}

// MARK: - Target

/// Counts the coupons whose dust has landed. It observes the controllers so the timeline un-pauses
/// as soon as a coupon is tapped (a plain view holding them would never re-render).
private struct AppliedPill: View {
    @ObservedObject var first: DustDissolveController
    @ObservedObject var second: DustDissolveController
    let th: DemoTheme

    var body: some View {
        TimelineView(.animation(paused: !(first.isActive || second.isActive))) { tl in
            let landed = [first, second].filter { ($0.elapsed(at: tl.date) ?? -1) >= $0.configuration.arrival }.count
            HStack(spacing: 8) {
                Text("Applied").font(.system(size: 13, weight: .medium))
                Text("\(landed)")
                    .font(.system(size: 13, weight: .semibold)).monospacedDigit()
                    .frame(minWidth: 22, minHeight: 22)
                    .background(th.fg.opacity(0.14), in: Capsule())
            }
            .foregroundStyle(th.fg)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(th.fg.opacity(0.08), in: Capsule())
            .dustTarget()
        }
    }
}

// MARK: - Card

struct CouponsCard: View {
    let dusts: [DustDissolveController]
    let th: DemoTheme

    var body: some View {
        VStack(spacing: 26) {
            HStack(spacing: 14) {
                Ticket(kind: .mochi70)
                    .dustSource(dusts[0])                       // ← the coupon
                    .onTapGesture { tap(dusts[0]) }
                Ticket(kind: .mochi50)
                    .dustSource(dusts[1])
                    .onTapGesture { tap(dusts[1]) }
            }

            // ← where the dust lands: the dots of both coupons flow into this pill
            AppliedPill(first: dusts[0], second: dusts[1], th: th)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    /// Ignore taps while a coupon is mid-dissolve.
    private func tap(_ dust: DustDissolveController) {
        let t = dust.elapsed(at: Date()) ?? -1
        if t < 0 || t > dust.configuration.total { dust.fire() }
    }
}

#Preview("Coupons") {
    let th = DemoTheme(dark: true)
    let dusts = [DustDissolveController(), DustDissolveController()]
    return DustDissolveScope(dusts) { CouponsCard(dusts: dusts, th: th) }
        .background(th.bg)
}
