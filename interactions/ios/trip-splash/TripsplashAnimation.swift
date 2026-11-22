//
//  TripsplashAnimation.swift
//  Testbed
//
//  Created by kitchen on 10.11.2026.
//

import SwiftUI

// MARK: - Timeline (seconds, measured from the reference recording @60fps)
//
//  0.00 – 0.45  logo rests
//  0.45 – 0.70  letters spread outward from the orange dot, dot swells
//  0.70 – 0.80  whole wordmark collapses into the dot
//  0.80 – 1.25  dot stretches into a gradient line that sweeps right, off screen
//  0.95 – 1.335  home screen revealed through a fast circular sweep
//  1.9 +       idle (tap to replay)

private enum Splash {
    static let blue   = Color(red: 0.14, green: 0.20, blue: 0.97)
    static let orange = Color(red: 1.00, green: 0.66, blue: 0.00)

    /// Piecewise-linear curve through (time, value) points.
    static func curve(_ t: Double, _ pts: [(Double, Double)]) -> Double {
        guard let first = pts.first, let last = pts.last else { return 0 }
        if t <= first.0 { return first.1 }
        if t >= last.0 { return last.1 }
        for i in 1..<pts.count where t <= pts[i].0 {
            let (t0, v0) = pts[i - 1], (t1, v1) = pts[i]
            let k = (t - t0) / (t1 - t0)
            let eased = k * k * (3 - 2 * k) * 0.35 + k * 0.65   // gentle smoothing between keys
            return v0 + (v1 - v0) * eased
        }
        return last.1
    }

    // Wordmark scale (anchored on the dot)
    static let logoScale: [(Double, Double)] = [
        (0.45, 1.0), (0.60, 1.05), (0.667, 1.0), (0.70, 0.80),
        (0.733, 0.33), (0.767, 0.16), (0.80, 0.0)
    ]
    // Letter spread multiplier
    static let spread: [(Double, Double)] = [
        (0.45, 1.0), (0.55, 1.05), (0.60, 1.18), (0.667, 1.35), (0.70, 1.3), (0.80, 1.2)
    ]
    // Dot size multiplier
    static let dotScale: [(Double, Double)] = [
        (0.45, 1.0), (0.62, 1.4), (0.70, 1.1), (0.80, 0.55)
    ]
    // Line head / tail as fraction of screen width — smooth closed-form motion (no keyframe kinks)
    static func lineHead(_ t: Double) -> Double {
        let u = max(t - 0.80, 0)
        return 0.5 + 8.5 * pow(u, 1.5)
    }
    /// Exact moment the line's head first reaches the right edge: 0.5 + 8.5·u^1.5 = 1
    static let lineHitTime = 0.80 + pow(0.5 / 8.5, 2.0 / 3.0)
    /// Tail stays put while the line grows, then — once the head leaves the screen and the blue swipe starts —
    /// chases it to the right: ~0.66 of the width when the swipe edge reaches the right side, off screen soon after.
    static func lineTail(_ t: Double) -> Double {
        let p = min(max((t - 0.80) / 0.2, 0), 1)
        let v = max(t - lineHitTime, 0)
        return 0.5 - 0.23 * (p * p * (3 - 2 * p)) + 3.8 * pow(v, 1.5)
    }
    // Reveal: fluid circular sweep. Starts the moment the edge enters the screen, glides through the middle
    // and decelerates smoothly into the end (no bounce).
    static let revealStart = 0.90, revealEnd = 1.26
    static func revealRadius(_ t: Double) -> Double {
        let p = min(max((t - revealStart) / (revealEnd - revealStart), 0), 1)
        let smooth = p * p * (3 - 2 * p)
        let out = 1 - pow(1 - p, 3)
        let e = 0.5 * smooth + 0.5 * out
        return 380 + (930 - 380) * e   // 380pt = edge just off the left side; 930pt covers the far corner
    }
}

// MARK: - Root view

struct TripSplashView: View {
    @State private var start = Date()
    @State private var finished = false
    @State private var revealed = false      // drives the circular reveal with a real SwiftUI animation

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            TimelineView(.animation(paused: finished)) { ctx in
                let t = ctx.date.timeIntervalSince(start)
                ZStack {
                    Splash.blue
                    HomeScreen().equatable().drawingGroup()
                        .frame(width: size.width, height: size.height)
                        .mask(revealMask(size: size))
                    SplashStage(t: t, size: size)      // above the home screen: the line stays visible over it while it exits
                }
                .frame(width: size.width, height: size.height)
                // Start the sweep on the very frame the line head touches the right edge (locked to the same clock)
                .onChange(of: t >= Splash.lineHitTime) { _, hit in if hit { revealed = true } }
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { start = Date(); finished = false }   // tap to replay
        .task(id: start) {
            var reset = Transaction(); reset.disablesAnimations = true
            withTransaction(reset) { revealed = false }
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            if !Task.isCancelled { finished = true }
        }
    }

    private func revealMask(size: CGSize) -> some View {
        let scale = size.width / 393
        let full = 930 * scale
        let k: CGFloat = revealed ? 1 : 380.0 / 930.0     // edge starts just off the left side; animated as a transform
        return ZStack {
            Circle()
                .frame(width: full * 2, height: full * 2)
                .scaleEffect(k)
                .animation(.timingCurve(0.25, 0.0, 0.05, 1.0, duration: 0.45), value: revealed)
                .position(x: -size.width, y: size.height * 0.5)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Logo + line

private struct SplashStage: View {
    let t: Double
    let size: CGSize

    var body: some View {
        let cy = size.height * 0.507
        let s = Splash.curve(t, Splash.logoScale)
        let k = Splash.curve(t, Splash.spread)
        let d = 11 * Splash.curve(t, Splash.dotScale)

        ZStack {
            // Line (dot stretches into it at t = 0.80)
            if t >= 0.80 && Splash.lineTail(t) < 1.0 {
                let head = Splash.lineHead(t) * size.width
                let tail = Splash.lineTail(t) * size.width
                Capsule()
                    .fill(LinearGradient(colors: [Splash.orange.opacity(0), Splash.orange],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(head - tail + 3, 3), height: 6)
                    .position(x: (head + tail) / 2, y: cy)
            }

            if t < 0.80 {
                Wordmark(k: k, dotScale: d / 11)
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(max(s, 0.001))          // anchored on the dot (dot sits at frame centre)
                    .opacity(t > 0.77 ? 0.5 : 1)
                    .offset(y: cy - size.height / 2)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Wordmark (real text layout; letters spread outward from the dot)

private struct MidKey: PreferenceKey {
    static var defaultValue: [Int: CGPoint] = [:]
    static func reduce(value: inout [Int: CGPoint], nextValue: () -> [Int: CGPoint]) {
        value.merge(nextValue()) { $1 }
    }
}

private struct Wordmark: View {
    let k: Double          // spread multiplier
    let dotScale: Double   // dot size multiplier
    @State private var mids: [Int: CGPoint] = [:]

    private let items = ["T", "r", "i", "p", "•", "c", "o", "m"]
    private let dotIndex = 4

    var body: some View {
        let dot = mids[dotIndex] ?? .zero
        ZStack {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    element(i)
                        .background(GeometryReader { g in
                            Color.clear.preference(key: MidKey.self,
                                                   value: [i: CGPoint(x: g.frame(in: .named("wm")).midX,
                                                                      y: g.frame(in: .named("wm")).midY)])
                        })
                }
            }
            .coordinateSpace(name: "wm")
            .onPreferenceChange(MidKey.self) { mids = $0 }
            // put the dot's centre at the centre of the container
            .alignmentGuide(HorizontalAlignment.center) { _ in dot.x }
            .alignmentGuide(VerticalAlignment.center) { _ in dot.y }
        }
    }

    @ViewBuilder
    private func element(_ i: Int) -> some View {
        if i == dotIndex {
            Circle().fill(Splash.orange)
                .frame(width: 11, height: 11)
                .scaleEffect(dotScale)
                .padding(.horizontal, 1)
                .alignmentGuide(.lastTextBaseline) { d in d[.bottom] - 1 }
        } else {
            let dx = ((mids[i]?.x ?? 0) - (mids[dotIndex]?.x ?? 0)) * (k - 1)
            Text(items[i])
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(.white)
                .offset(x: dx)
        }
    }
}

// MARK: - Home screen (what gets revealed)

private struct HomeScreen: View, Equatable {
    private let blue = Color(red: 0.14, green: 0.20, blue: 0.97)
    private let accent = Color(red: 0.12, green: 0.32, blue: 0.95)
    private let ink = Color(red: 0.10, green: 0.12, blue: 0.20)
    private let amber = Color(red: 1.0, green: 0.72, blue: 0.20)

    var body: some View {
        ZStack(alignment: .top) {
            blue
            Text("Trip.com")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.top, 58)

            VStack(spacing: 0) {
                content
                Spacer(minLength: 0)
                tabBar
            }
            .background(Color.white)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 18, topTrailingRadius: 18))
            .padding(.top, 100)
        }
    }

    // MARK: sections

    private var content: some View {
        VStack(spacing: 20) {
            // Primary categories — fixed icon box + fixed label height so every column lines up
            HStack(alignment: .top, spacing: 0) {
                category("bed.double.fill", "Hotels", big: true)
                category("airplane", "Flights", big: true)
                category("building.2.fill", "Flight + Hotel", big: true)
                category("tram.fill", "Trains", big: true)
            }
            .padding(.top, 16)

            // Secondary categories
            HStack(alignment: .top, spacing: 0) {
                category("house.fill", "Vacation\nRentals", big: false)
                category("ticket.fill", "Attractions\n& Activities", big: false)
                category("car.fill", "Car Rentals\n& Transfers", big: false)
                category("flag.fill", "Tours", big: false)
                category("ellipsis.circle.fill", "+6 more", big: false)
            }

            VStack(spacing: 10) {
            searchField

            HStack(spacing: 12) {
                Text("Hotels in London")
                Text("Near Tower Bridge")
                Spacer()
                Label("Map", systemImage: "map").labelStyle(.titleAndIcon).foregroundStyle(accent)
            }
            .font(.system(size: 11)).foregroundStyle(ink.opacity(0.6))
            }

            HStack(alignment: .top, spacing: 0) {
                tile("tag", "Deals"); tile("calendar", "Events"); tile("checklist", "Trip.Planner")
                tile("chart.line.uptrend.xyaxis", "Trending"); tile("trophy", "Trip.Best")
            }

            promoRow

            HStack {
                Text("Popular destinations").font(.system(size: 15, weight: .bold))
                Spacer()
                Text("See all").font(.system(size: 12, weight: .medium)).foregroundStyle(accent)
            }
            .padding(.top, 4)

            // Plain HStack (not a ScrollView) so the screen can be rasterised with drawingGroup()
            HStack(spacing: 8) {
                Group {
                    destination("London", "From $59", Color(red: 0.95, green: 0.62, blue: 0.30), Color(red: 0.35, green: 0.22, blue: 0.45))
                    destination("Edinburgh", "From $42", Color(red: 0.40, green: 0.70, blue: 0.90), Color(red: 0.10, green: 0.25, blue: 0.55))
                    destination("Brighton", "From $38", Color(red: 0.45, green: 0.85, blue: 0.60), Color(red: 0.05, green: 0.40, blue: 0.40))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private var searchField: some View {
        HStack {
            Text("Hotels in London").font(.system(size: 14)).foregroundStyle(ink.opacity(0.8))
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                .frame(width: 28, height: 28).background(accent, in: Circle())
        }
        .padding(.leading, 12).padding(.trailing, 4)
        .frame(height: 38)
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(accent, lineWidth: 1.2))
    }

    private var promoRow: some View {
        GeometryReader { geo in
            let gap: CGFloat = 8
            let leftW = (geo.size.width - gap) * 0.56
            let rightW = geo.size.width - gap - leftW
            HStack(alignment: .top, spacing: gap) {
                // Big sale card
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text("MEGA\nSALE")
                            .font(.system(size: 11, weight: .heavy)).foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(red: 0.78, green: 0.40, blue: 0.85)))
                        Spacer(minLength: 0)
                        Text("50%\nOFF")
                            .font(.system(size: 13, weight: .heavy)).foregroundStyle(ink)
                            .multilineTextAlignment(.center)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color(red: 0.40, green: 0.92, blue: 0.82)))
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("EARLY"); Text("BLACK"); Text("FRIDAY")
                    }
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(amber)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(Color.black.rotationEffect(.degrees(-3)))
                    Spacer(minLength: 0)
                    Text("View Deals")
                        .font(.system(size: 10, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 22)
                        .background(Capsule().fill(accent))
                }
                .padding(10)
                .frame(width: leftW, height: 176)
                .background(RoundedRectangle(cornerRadius: 10).fill(amber))

                VStack(spacing: gap) {
                    promoTile("EARLY\nBLACK FRIDAY", [Color(red: 1, green: 0.58, blue: 0.30), Color(red: 0.88, green: 0.30, blue: 0.32)])
                        .frame(width: rightW, height: (176 - gap) / 2)
                    promoTile("10 DAYS IN\nLONDON", [Color(red: 0.80, green: 0.60, blue: 0.38), Color(red: 0.20, green: 0.20, blue: 0.30)])
                        .frame(width: rightW, height: (176 - gap) / 2)
                }
            }
        }
        .frame(height: 176)
    }

    private var tabBar: some View {
        HStack(alignment: .top, spacing: 0) {
            tab("house.fill", "Home", active: true)
            tab("bubble.left.fill", "Messages")
            tab("person.2.fill", "Community")
            tab("suitcase.fill", "My Trips")
            tab("person.crop.circle.fill", "Account")
        }
        .padding(.top, 8).padding(.bottom, 26)
        .background(Color.white)
        .overlay(Rectangle().fill(Color.black.opacity(0.07)).frame(height: 0.5), alignment: .top)
    }

    // MARK: pieces

    private func category(_ sf: String, _ title: String, big: Bool) -> some View {
        VStack(spacing: big ? 6 : 4) {
            Image(systemName: sf)
                .font(.system(size: big ? 24 : 16, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 32, height: big ? 30 : 22)
            Text(title)
                .font(.system(size: big ? 11 : 9, weight: big ? .semibold : .regular))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: big ? 14 : 24, alignment: .top)
        }
        .frame(maxWidth: .infinity)
    }

    private func tile(_ sf: String, _ title: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: sf)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(ink.opacity(0.85))
                .frame(width: 28, height: 24)
            Text(title).font(.system(size: 10)).foregroundStyle(ink)
        }
        .frame(maxWidth: .infinity)
    }

    private func promoTile(_ text: String, _ colors: [Color]) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .bottomLeading) {
                Text(text).font(.system(size: 13, weight: .black)).foregroundStyle(.white)
                    .lineLimit(2).minimumScaleFactor(0.8).padding(10)
            }
    }

    private func destination(_ name: String, _ price: String, _ a: Color, _ b: Color) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(LinearGradient(colors: [a, b], startPoint: .top, endPoint: .bottom))
            .frame(maxWidth: .infinity).frame(height: 88)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(name).font(.system(size: 14, weight: .bold))
                    Text(price).font(.system(size: 10))
                }
                .foregroundStyle(.white).padding(10)
            }
    }

    private func tab(_ sf: String, _ title: String, active: Bool = false) -> some View {
        VStack(spacing: 3) {
            Image(systemName: sf).font(.system(size: 18)).frame(height: 22)
            Text(title).font(.system(size: 10))
        }
        .foregroundStyle(active ? accent : Color.gray)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    TripSplashView()
}
