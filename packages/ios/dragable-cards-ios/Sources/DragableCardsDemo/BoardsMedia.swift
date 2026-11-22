//
//  BoardsMedia.swift
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Media-style showcase board: a music queue (the live equalizer keeps moving while the card is
//  lifted, and the header totals update as songs move).
//
import SwiftUI
import DragableCards

private struct Song: Identifiable {
    let id: Int
    let title: String
    let artist: String
    let seconds: Int
    let art: Art
    var playing = false
}

private let sunsetArt = Art(a: Color(hex: 0xFF8A5B), b: Color(hex: 0xD6336C))
private let tideArt = Art(a: Color(hex: 0x38BDF8), b: Color(hex: 0x4338CA))
private let fernArt = Art(a: Color(hex: 0x86EFAC), b: Color(hex: 0x0F766E))
private let duskArt = Art(a: Color(hex: 0xC4B5FD), b: Color(hex: 0x6D28D9))
private let honeyArt = Art(a: Color(hex: 0xFDE68A), b: Color(hex: 0xEA580C))
private let inkArt = Art(a: Color(hex: 0x64748B), b: Color(hex: 0x0F172A))
private let roseArt = Art(a: Color(hex: 0xFBCFE8), b: Color(hex: 0xDB2777))

private func songs() -> [[Song]] {
    [
        [
            Song(id: 1, title: "Neon Harbor", artist: "Kite Season", seconds: 214, art: sunsetArt, playing: true),
            Song(id: 2, title: "Slow Orbit", artist: "Lumen", seconds: 187, art: tideArt),
            Song(id: 3, title: "Paper Planes at Noon", artist: "Okra", seconds: 203, art: honeyArt),
            Song(id: 4, title: "Static Bloom", artist: "Vela", seconds: 241, art: duskArt),
        ],
        [
            Song(id: 5, title: "Glass Garden", artist: "Nori", seconds: 196, art: fernArt),
            Song(id: 6, title: "Low Tide Radio", artist: "Pelham", seconds: 228, art: inkArt),
            Song(id: 7, title: "Cinder", artist: "Aya Moreau", seconds: 175, art: roseArt),
        ],
    ]
}

struct MusicQueue: View {
    let theme: DemoTheme
    @StateObject private var state = DragBoardState(songs())

    var body: some View {
        DragBoard(
            state: state,
            columnWidth: 318,
            cardSpacing: 6,
            columnStyle: theme.roundedColumnStyle(18),
            appearance: theme.appearance(cornerRadius: 14, liftScale: 1.05)
        ) { index, items in
            HStack(spacing: 8) {
                if index == 1 {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0xEC4899))
                }
                txt(index == 0 ? "Up next" : "Liked", 14, theme.text, .semibold)
                txt("\(items.count) songs  ·  \(items.reduce(0) { $0 + $1.seconds } / 60) min", 12, theme.muted)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 12)
        } card: { song in
            SongCard(theme: theme, song: song)
        }
        .frame(height: 380)
    }
}

private struct SongCard: View {
    let theme: DemoTheme
    let song: Song

    private var duration: String {
        "\(song.seconds / 60):" + String(format: "%02d", song.seconds % 60)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(song.art.gradient)
                if song.playing { Equalizer(color: .white) }
            }
            .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 0) {
                txt(song.title, 14, theme.text, .semibold).lineLimit(1)
                txt(song.artist, 12, theme.muted).lineLimit(1)
            }
            Spacer(minLength: 0)
            txt(duration, 12, theme.muted).padding(.trailing, 6)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(theme.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.cardBorder, lineWidth: 1))
    }
}

/// Three bouncing bars. It keeps animating on the floating copy while the card is lifted.
private struct Equalizer: View {
    let color: Color
    private let periods: [Double] = [0.52, 0.38, 0.45]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2.5) {
                ForEach(0..<3, id: \.self) { i in
                    // A triangle wave between 0.25 and 1, like a reversing linear animation.
                    let phase = (t / periods[i]).truncatingRemainder(dividingBy: 2)
                    let level = 0.25 + 0.75 * (phase < 1 ? phase : 2 - phase)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(color)
                        .frame(width: 3, height: 18 * level)
                }
            }
            .frame(height: 18, alignment: .bottom)
        }
    }
}
