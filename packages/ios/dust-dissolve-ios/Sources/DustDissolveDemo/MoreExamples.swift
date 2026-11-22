//
//  MoreExamples.swift
//  DustDissolveDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  The sections of the showcase that need no target: the dust drifts away. In every
//  one of them the dissolving view keeps its place in the layout, so nothing around it moves.
//
import SwiftUI
import DustDissolve

// MARK: - Model: every controller of the showcase, so one scope can draw all the dust

@MainActor
final class ShowcaseModel: ObservableObject {
    let coupons: [DustDissolveController]
    let balance: DustDissolveController
    @Published var balanceHidden = false
    let password: DustDissolveController
    @Published var passwordHidden = false
    let messages: [DustDissolveController]

    var all: [DustDissolveController] { coupons + [balance, password] + messages }

    init() {
        coupons = (0..<2).map { i in
            var c = DustDissolveConfiguration.coupon          // shimmer, dissolve, then flow to the target
            c.seed = UInt64(7 + i * 13)
            return DustDissolveController(c)
        }
        var p = DustDissolveConfiguration.dismiss
        p.direction = .leftToRight
        p.motion = .drift(angle: .degrees(-25), distance: 90)
        p.particleCount = 420
        p.dotSize = 1.4...2.6
        p.sparkleEvery = 0
        p.dissolveStart = 0.0; p.dissolveEnd = 0.55
        p.flightStart = 0.25; p.flightStagger = 0.3
        p.total = 1.6
        p.seed = 90
        password = DustDissolveController(p)

        var b = p
        b.particleCount = 520
        b.dotSize = 1.6...3.0
        b.motion = .drift(angle: .degrees(-20), distance: 110)
        b.dissolveEnd = 0.6
        b.seed = 91
        balance = DustDissolveController(b)
        messages = (0..<3).map { i in
            var c = DustDissolveConfiguration.dismiss
            let fromLeft = i % 2 == 0
            c.direction = fromLeft ? .rightToLeft : .leftToRight
            c.motion = .drift(angle: .degrees(fromLeft ? 195 : -15), distance: 130)
            c.particleCount = 520
            c.seed = UInt64(70 + i)
            return DustDissolveController(c)
        }
    }

    func fire(_ cs: [DustDissolveController], every ms: Int = 140, shuffled: Bool = false) async {
        for c in (shuffled ? cs.shuffled() : cs) {
            c.fire()
            try? await Task.sleep(for: .milliseconds(ms))
        }
    }

    func reset(_ cs: [DustDissolveController]) { cs.forEach { $0.reset() } }

    /// Hide: the visible text turns to dust, then the dots fade in. Show: the text is simply back.
    func setPassword(hidden: Bool) {
        passwordHidden = hidden
        if hidden { password.fire() } else { password.reset() }
    }

    func setBalance(hidden: Bool) {
        balanceHidden = hidden
        if hidden { balance.fire() } else { balance.reset() }
    }
}

// MARK: - Section chrome

struct SectionCard<Content: View>: View {
    let title: String
    let th: DemoTheme
    var padded = true
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, padded ? 16 : 16)
            .padding(.top, 14)
            content
                .padding(.horizontal, padded ? 16 : 0)
                .padding(.bottom, padded ? 16 : 0)
        }
        .foregroundStyle(th.fg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(th.card))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(th.line, lineWidth: 1))
    }
}

// MARK: - Shared helper

/// Flips `gone` to true as soon as the view has fully dissolved (the dust may still be flying), and back to
/// false when the controller is reset or fired again.
private struct GoneTracker: ViewModifier {
    @ObservedObject var dust: DustDissolveController
    @Binding var gone: Bool

    func body(content: Content) -> some View {
        content.task(id: dust.startDate) {
            gone = false
            guard let start = dust.startDate else { return }
            let wait = max(0, start.timeIntervalSinceNow + dust.configuration.dissolveEnd + 0.05)
            try? await Task.sleep(for: .seconds(wait))
            if !Task.isCancelled { gone = true }
        }
    }
}

// MARK: - Show / hide balance

struct BalanceSection: View {
    @ObservedObject var model: ShowcaseModel
    let th: DemoTheme

    private let amount = "$12,480.50"

    var body: some View {
        SectionCard(title: "Hide balance", th: th) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total balance").font(.system(size: 12)).foregroundStyle(th.sub)
                    ZStack(alignment: .leading) {
                        Text(amount)                                  // ← the amount that dissolves
                            .font(.system(size: 32, weight: .bold)).monospacedDigit()
                            .dustSource(model.balance)
                        Text("••••••")
                            .font(.system(size: 32, weight: .bold))
                            .opacity(model.balanceHidden ? 1 : 0)
                            .animation(.easeIn(duration: 0.3).delay(model.balanceHidden ? 0.5 : 0), value: model.balanceHidden)
                    }
                }
                Spacer()
                Button { model.setBalance(hidden: !model.balanceHidden) } label: {
                    Image(systemName: model.balanceHidden ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16)).foregroundStyle(th.sub)
                        .frame(width: 40, height: 40)
                        .background(th.fg.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .frame(height: 64)
        }
    }
}

// MARK: - Show / hide password

struct PasswordSection: View {
    @ObservedObject var model: ShowcaseModel
    let th: DemoTheme

    private let secret = "hunter2-Mochi!"

    var body: some View {
        SectionCard(title: "Hide password", th: th) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill").font(.system(size: 14)).foregroundStyle(th.sub)
                ZStack(alignment: .leading) {
                    Text(secret)                                      // ← the text that dissolves
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .dustSource(model.password)
                    Text(String(repeating: "•", count: secret.count))
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .opacity(model.passwordHidden ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(model.passwordHidden ? 0.5 : 0), value: model.passwordHidden)
                }
                Spacer()
                Button { model.setPassword(hidden: !model.passwordHidden) } label: {
                    Image(systemName: model.passwordHidden ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 15)).foregroundStyle(th.sub)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 12).fill(th.fg.opacity(0.06)))
        }
    }
}

// MARK: - Disappearing messages

private struct MessageRow: View {
    @ObservedObject var dust: DustDissolveController
    let th: DemoTheme
    let text: String
    let mine: Bool

    /// As soon as the bubble is gone (dissolve finished) its row folds away and the ones below slide up.
    /// The bubble keeps its full size, so the dust that is still flying does not move.
    @State private var gone = false

    var body: some View {
        HStack {
            if mine { Spacer(minLength: 60) }
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(mine ? .white : th.fg)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(mine ? AnyShapeStyle(Color.blue.gradient) : AnyShapeStyle(th.fg.opacity(0.10)),
                            in: RoundedRectangle(cornerRadius: 18))
                .dustSource(dust)
                .onTapGesture { dust.fire() }
            if !mine { Spacer(minLength: 60) }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 8)
        .frame(height: gone ? 0 : 46, alignment: .top)    // 38 bubble + 8 gap
        .animation(.easeInOut(duration: 0.25), value: gone)
        .modifier(GoneTracker(dust: dust, gone: $gone))
    }
}

struct MessagesSection: View {
    @ObservedObject var model: ShowcaseModel
    let th: DemoTheme

    private let texts = ["Are you free tonight?", "Yes! 8pm works", "Perfect, see you then"]

    var body: some View {
        SectionCard(title: "Disappearing messages", th: th) {
            VStack(spacing: 0) {
                ForEach(Array(model.messages.enumerated()), id: \.element.id) { i, dust in
                    MessageRow(dust: dust, th: th, text: texts[i], mine: i % 2 == 1)
                }
            }
        }
    }
}
