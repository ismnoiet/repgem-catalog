//
//  Demos.swift
//  FireworkFlourishDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI
import FireworkFlourish

// MARK: - 1. Level up

struct LevelUpDemo: View {
    @State private var xp = 60
    @State private var level = 4
    @State private var levelUps = 0

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Explorer").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.primary.opacity(0.5))
                Text("Level \(level)")
                    .font(.system(size: 34, weight: .bold)).foregroundStyle(Color.primary)
                    .contentTransition(.numericText())
                ProgressView(value: Double(xp), total: 100).tint(.yellow)
                Text("\(xp) / 100 XP").font(.footnote).foregroundStyle(Color.primary.opacity(0.6))
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBackground(glass)
            .fireworkFlourish(trigger: levelUps, duration: 2.2, style: .milestone)
            .clipShape(glass)
            .overlay(glass.strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.75))

            Button("+25 XP") {
                withAnimation(.spring) {
                    xp += 25
                    if xp >= 100 { xp -= 100; level += 1; levelUps += 1 }
                }
            }
            .buttonStyle(QuietButtonStyle())
        }
        .padding(16)
        .sensoryFeedback(.success, trigger: levelUps)
    }
}

// MARK: - 2. Achievement toast

struct AchievementToastDemo: View {
    @State private var showing = false

    var body: some View {
        ZStack(alignment: .top) {
            Button("Unlock achievement") {
                Task {
                    withAnimation(.spring) { showing = true }
                    try? await Task.sleep(for: .seconds(3.5))
                    withAnimation(.easeIn) { showing = false }
                }
            }
            .buttonStyle(QuietButtonStyle())
            .frame(maxHeight: .infinity)

            if showing {
                HStack(spacing: 12) {
                    Image(systemName: "trophy.fill").font(.title).foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Achievement unlocked").font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.primary.opacity(0.55))
                        Text("First 100 sales").font(.system(size: 20, weight: .bold)).foregroundStyle(Color.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .frame(height: 72)
                .glassBackground(Capsule())
                .overlay { FireworkFlourish(.milestone) }
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.yellow.opacity(0.4), lineWidth: 0.75))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sensoryFeedback(.success, trigger: showing)
    }
}

// MARK: - 3. Scoreboard

struct ScoreboardDemo: View {
    @State private var home = 1
    @State private var away = 1

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                team("HOME", home)
                Text("–").font(.title).foregroundStyle(Color.primary.opacity(0.4))
                team("AWAY", away)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .glassBackground(glass)
            .fireworkFlourish(trigger: home, duration: 1.8, style: .neonPop)
            .fireworkFlourish(trigger: away, duration: 1.8, style: .neonPop)
            .clipShape(glass)
            .overlay(glass.strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.75))

            HStack {
                Button("Home scores") { home += 1 }
                Button("Away scores") { away += 1 }
            }
            .buttonStyle(QuietButtonStyle())
        }
        .padding(16)
        .sensoryFeedback(.impact, trigger: home + away)
    }

    private func team(_ name: String, _ score: Int) -> some View {
        VStack(spacing: 2) {
            Text(name).font(.caption.weight(.semibold)).foregroundStyle(Color.primary.opacity(0.5))
            Text("\(score)").font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.primary).contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 4. Like button

struct LikeButtonDemo: View {
    @State private var liked = false
    @State private var bursts = 0

    var body: some View {
        VStack(spacing: 4) {
            Button {
                liked.toggle()
                if liked { bursts += 1 }
            } label: {
                Image(systemName: liked ? "heart.fill" : "heart")
                    .font(.system(size: 44))
                    .foregroundStyle(liked ? .pink : Color.primary)
                    .scaleEffect(liked ? 1.1 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: liked)
                    .frame(width: 160, height: 160)
                    .fireworkFlourish(trigger: bursts, duration: 0.3, style: .like)
            }
            .buttonStyle(.plain)
            Text(liked ? "Liked" : "Tap to like").font(.footnote).foregroundStyle(Color.primary.opacity(0.6))
        }
        .padding(.vertical, 12)
        .sensoryFeedback(.impact, trigger: bursts)
    }
}

// MARK: - 5. Calendar sparkle

struct CalendarSparkleDemo: View {
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("March").font(.system(size: 26, weight: .bold)).foregroundStyle(Color.primary)
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(1...31, id: \.self) { day in cell(day) }
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private func cell(_ day: Int) -> some View {
        let isToday = day == 13
        ZStack {
            Circle().fill(isToday ? Color.indigo.opacity(0.6) : Color.primary.opacity(0.05))
            if isToday { FireworkFlourish(.sparkle) }
            Text("\(day)").font(.system(size: 15, weight: isToday ? .bold : .regular)).foregroundStyle(Color.primary)
        }
        .clipShape(Circle())
        .aspectRatio(1, contentMode: .fit)
        .overlay(Circle().strokeBorder(isToday ? Color.primary.opacity(0.5) : .clear, lineWidth: 1))
    }
}

// MARK: - 6. Progress ring

struct ProgressRingDemo: View {
    @State private var progress = 0.7
    @State private var fire = 0

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().stroke(Color.primary.opacity(0.12), lineWidth: 14)
                Circle().trim(from: 0, to: progress)
                    .stroke(progress >= 1 ? Color.green : Color.cyan,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%").font(.system(size: 40, weight: .bold)).foregroundStyle(Color.primary)
                    Text(progress >= 1 ? "Goal reached!" : "of $10,000").font(.footnote)
                        .foregroundStyle(Color.primary.opacity(0.6))
                }
            }
            .frame(width: 180, height: 180)
            .padding(36)
            .fireworkFlourish(trigger: fire, duration: 2.2, style: .pastelBloom)

            Slider(value: $progress, in: 0...1).padding(.horizontal, 32)
        }
        .padding(.bottom, 16)
        .onChange(of: progress >= 1) { _, reached in if reached { fire += 1 } }
        .sensoryFeedback(.success, trigger: fire)
    }
}

// MARK: - 7. Anniversary

struct AnniversaryDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Anniversary · Alex & Sam")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.primary.opacity(0.55))
            Text("5 years today")
                .font(.system(size: 34, weight: .bold)).foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
        .glassBackground(glass)
        .overlay { FireworkFlourish(.romance) }
        .clipShape(glass)
        .overlay(glass.strokeBorder(Color.primary.opacity(0.18), lineWidth: 0.75))
        .padding(16)
    }
}

// MARK: - 8. New Year countdown

struct CountdownDemo: View {
    @State private var count: Int? = nil
    @State private var fire = 0
    @State private var running = false

    var body: some View {
        VStack(spacing: 16) {
            Text(label)
                .font(.system(size: count == 0 ? 34 : 80, weight: .black, design: .rounded))
                .foregroundStyle(Color.primary)
                .contentTransition(.numericText())
                .animation(.spring, value: count)
            Button("Start countdown") { start() }
                .buttonStyle(QuietButtonStyle()).disabled(running)
                .opacity(running ? 0 : 1)   // hidden from the countdown until the year is back
                .animation(.easeInOut(duration: 0.3), value: running)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .fireworkFlourish(trigger: fire, duration: 7, style: .newYear)
        .sensoryFeedback(.success, trigger: fire)
    }

    private var label: String {
        guard let count else { return "2027" }
        return count == 0 ? "Happy New Year!" : "\(count)"
    }

    private func start() {
        running = true
        Task {
            for n in stride(from: 3, through: 1, by: -1) {
                count = n
                try? await Task.sleep(for: .seconds(0.4))
            }
            count = 0
            fire += 1
            try? await Task.sleep(for: .seconds(8))
            count = nil
            running = false
        }
    }
}

// MARK: - 9. Style lab

struct StyleLabDemo: View {
    @State private var presetIndex = 0
    @State private var interval = FireworkStyle.card.interval
    @State private var particles = Double(FireworkStyle.card.particles)
    @State private var radius = Double(FireworkStyle.card.maxRadius)
    @State private var gravity = Double(FireworkStyle.card.gravity)
    @State private var life = FireworkStyle.card.burstLife
    @State private var rockets = true
    @State private var paletteIndex = 0

    private var style: FireworkStyle {
        var s = FireworkStyle.all[presetIndex].style
        s.interval = interval
        s.particles = Int(particles)
        s.maxRadius = CGFloat(radius)
        s.gravity = CGFloat(gravity)
        s.burstLife = life
        s.showRockets = rockets
        s.palettes = FireworkPalette.all[paletteIndex].colors
        return s
    }

    var body: some View {
        VStack(spacing: 12) {
            FireworkFlourish(style)
                .frame(height: 240)
                .background(Color.black.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .id("\(presetIndex)-\(paletteIndex)")

            HStack {
                Picker("Preset", selection: $presetIndex) {
                    ForEach(FireworkStyle.all.indices, id: \.self) {
                        Text(FireworkStyle.all[$0].name).tag($0)
                    }
                }
                .onChange(of: presetIndex) { load() }
                Spacer()
                Picker("Palette", selection: $paletteIndex) {
                    ForEach(FireworkPalette.all.indices, id: \.self) {
                        Text(FireworkPalette.all[$0].name).tag($0)
                    }
                }
            }
            .pickerStyle(.menu)

            slider("Interval", $interval, 0.05...1.2, "%.2fs")
            slider("Particles", $particles, 8...140, "%.0f")
            slider("Radius", $radius, 8...100, "%.0fpt")
            slider("Gravity", $gravity, -25...35, "%.0f")
            slider("Fade time", $life, 0.8...4, "%.1fs")
            Toggle("Rockets", isOn: $rockets).font(.footnote)
        }
        .padding(16)
    }

    private func load() {
        let s = FireworkStyle.all[presetIndex].style
        interval = s.interval; particles = Double(s.particles); radius = Double(s.maxRadius)
        gravity = Double(s.gravity); life = s.burstLife; rockets = s.showRockets
    }

    private func slider(_ name: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ fmt: String) -> some View {
        HStack {
            Text(name).frame(width: 76, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: fmt, value.wrappedValue)).monospacedDigit().frame(width: 54, alignment: .trailing)
        }
        .font(.footnote)
    }
}
