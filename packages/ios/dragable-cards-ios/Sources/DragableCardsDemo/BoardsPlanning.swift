//
//  BoardsPlanning.swift
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Planning-style showcase boards: a hiring pipeline (reports every move through `onCardMove`), a
//  weekly meal planner (five columns, so the board scrolls sideways as you drag) and a trip planner
//  (card height follows the content, and a day turns amber when it is overbooked).
//
import SwiftUI
import DragableCards

// MARK: - Hiring pipeline

private struct Candidate: Identifiable {
    let id: Int
    let name: String
    let role: String
    let score: Int
    let tags: [String]
    let tone: Art
}

private let stages = ["Applied", "Interview", "Offer", "Hired"]
/// Index into the theme accents (green, blue, yellow, purple) for each stage.
private let stageAccent = [1, 2, 3, 0]

private let coral = Art(a: Color(hex: 0xFF7A59), b: Color(hex: 0xE23E7B))
private let ocean = Art(a: Color(hex: 0x38BDF8), b: Color(hex: 0x6366F1))
private let mint = Art(a: Color(hex: 0x34D399), b: Color(hex: 0x0EA5A4))
private let amber = Art(a: Color(hex: 0xFBBF24), b: Color(hex: 0xF97316))
private let orchid = Art(a: Color(hex: 0xC084FC), b: Color(hex: 0x7C3AED))
private let slate = Art(a: Color(hex: 0x94A3B8), b: Color(hex: 0x475569))

private func candidates() -> [[Candidate]] {
    [
        [
            Candidate(id: 1, name: "Maya Chen", role: "Senior iOS Engineer", score: 88, tags: ["Remote", "Senior"], tone: coral),
            Candidate(id: 2, name: "Jonas Weber", role: "Product Designer", score: 74, tags: ["Referral"], tone: ocean),
            Candidate(id: 3, name: "Priya Nair", role: "SwiftUI Engineer", score: 81, tags: ["Remote"], tone: mint),
        ],
        [Candidate(id: 4, name: "Leo Martins", role: "Design Systems Lead", score: 91, tags: ["Onsite", "Lead"], tone: amber)],
        [Candidate(id: 5, name: "Amira Haddad", role: "Staff Engineer", score: 95, tags: ["Remote", "Staff"], tone: orchid)],
        [Candidate(id: 6, name: "Tom Okafor", role: "QA Engineer", score: 79, tags: ["Hybrid"], tone: slate)],
    ]
}

struct HiringBoard: View {
    let theme: DemoTheme
    @StateObject private var state = DragBoardState(candidates())
    @State private var message: String?
    @State private var lastMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Fed by `onCardMove`: the board tells you where a card landed.
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.accents[0])
                txt(lastMessage, 12, theme.text, .medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(theme.card))
            .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))
            .opacity(message == nil ? 0 : 1)
            .offset(y: message == nil ? -8 : 0)
            .frame(height: 30)

            DragBoard(
                state: state,
                columnWidth: 252,
                appearance: theme.appearance(cornerRadius: 12)
            ) { index, people in
                HStack(spacing: 8) {
                    Circle().fill(theme.accents[stageAccent[index]]).frame(width: 8, height: 8)
                    txt(stages[index], 14, theme.text, .semibold)
                    txt("\(people.count)", 13, theme.muted)
                    Spacer(minLength: 0)
                    if !people.isEmpty {
                        txt("avg \(people.reduce(0) { $0 + $1.score } / people.count)", 11, theme.muted)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 12)
            } card: { candidate in
                CandidateCard(theme: theme, candidate: candidate)
            }
            .onCardMove { candidate, from, to, _ in
                guard from != to else { return }
                lastMessage = "\(candidate.name) moved to \(stages[to])"
                withAnimation(.easeOut(duration: 0.22)) { message = lastMessage }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                    if message == lastMessage { withAnimation(.easeOut(duration: 0.22)) { message = nil } }
                }
            }
            .frame(height: 390)
        }
    }
}

private struct CandidateCard: View {
    let theme: DemoTheme
    let candidate: Candidate

    private var ring: Color {
        candidate.score >= 90 ? theme.accents[0] : candidate.score >= 80 ? theme.accents[1] : theme.accents[2]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                txt(candidate.name.split(separator: " ").compactMap { $0.first.map(String.init) }.joined(), 13, .white, .bold)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(candidate.tone.gradient))
                VStack(alignment: .leading, spacing: 0) {
                    txt(candidate.name, 14, theme.text, .semibold).lineLimit(1)
                    txt(candidate.role, 12, theme.muted).lineLimit(1)
                }
                Spacer(minLength: 0)
                txt("\(candidate.score)", 11, theme.text, .bold)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(ring, lineWidth: 2))
            }
            HStack(spacing: 6) {
                ForEach(candidate.tags, id: \.self) { Pill(theme: theme, text: $0) }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.card))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Weekly meal planner

private struct Meal: Identifiable {
    let id: Int
    let type: Int
    let name: String
    let kcal: Int
}

private let mealTypes = ["BREAKFAST", "LUNCH", "DINNER", "SNACK"]
private let mealColors = [Color(hex: 0xF59E0B), Color(hex: 0x22C55E), Color(hex: 0x8B5CF6), Color(hex: 0xEC4899)]
private let weekDays = [("Mon", 16), ("Tue", 17), ("Wed", 18), ("Thu", 19), ("Fri", 20)]

private func meals() -> [[Meal]] {
    [
        [Meal(id: 1, type: 0, name: "Overnight oats", kcal: 320), Meal(id: 2, type: 1, name: "Chicken grain bowl", kcal: 610), Meal(id: 3, type: 2, name: "Salmon and greens", kcal: 540)],
        [Meal(id: 4, type: 0, name: "Veggie omelette", kcal: 380), Meal(id: 5, type: 1, name: "Lentil soup", kcal: 430), Meal(id: 6, type: 2, name: "Pasta al limone", kcal: 640)],
        [Meal(id: 7, type: 0, name: "Yogurt and berries", kcal: 280), Meal(id: 8, type: 1, name: "Greek salad", kcal: 390), Meal(id: 9, type: 3, name: "Apple and almonds", kcal: 210)],
        [Meal(id: 10, type: 0, name: "Green smoothie", kcal: 260), Meal(id: 11, type: 1, name: "Falafel wrap", kcal: 520)],
        [Meal(id: 12, type: 2, name: "Friday pizza night", kcal: 820)],
    ]
}

struct MealPlanner: View {
    let theme: DemoTheme
    @StateObject private var state = DragBoardState(meals())

    var body: some View {
        DragBoard(
            state: state,
            columnWidth: 190,
            columnStyle: theme.roundedColumnStyle(16),
            appearance: theme.appearance(cornerRadius: 10, liftTilt: 3)
        ) { index, items in
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    txt(weekDays[index].0, 14, theme.text, .semibold)
                    txt("\(weekDays[index].1)", 14, theme.muted)
                }
                txt("\(items.reduce(0) { $0 + $1.kcal }) kcal", 12, theme.muted)
            }
            .padding(.leading, 2)
            .padding(.bottom, 12)
        } card: { meal in
            HStack(spacing: 0) {
                Rectangle().fill(mealColors[meal.type]).frame(width: 4)
                VStack(alignment: .leading, spacing: 3) {
                    txt(mealTypes[meal.type], 10, mealColors[meal.type], .bold)
                    txt(meal.name, 13, theme.text, .medium)
                    txt("\(meal.kcal) kcal", 11, theme.muted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.cardBorder, lineWidth: 1))
        }
        .frame(height: 420)
    }
}

// MARK: - Trip planner

private struct Place: Identifiable {
    let id: Int
    let title: String
    let minutes: Int
    let kind: String
    let art: Art
    var note: String? = nil
    var booked = false
}

private let tripColumns = ["Ideas", "Day 1", "Day 2", "Day 3"]
private let dayLimitMinutes = 8 * 60

private func shortDuration(_ m: Int) -> String {
    if m < 60 { return "\(m)m" }
    if m % 60 == 0 { return "\(m / 60)h" }
    return "\(m / 60)h\(m % 60)"
}

private func fullDuration(_ m: Int) -> String {
    if m < 60 { return "\(m)m" }
    if m % 60 == 0 { return "\(m / 60)h" }
    return "\(m / 60)h \(m % 60)m"
}

private let food = Art(a: Color(hex: 0xFF8A5B), b: Color(hex: 0xD6336C))
private let sights = Art(a: Color(hex: 0x38BDF8), b: Color(hex: 0x4338CA))
private let culture = Art(a: Color(hex: 0xC084FC), b: Color(hex: 0x6D28D9))
private let nature = Art(a: Color(hex: 0x34D399), b: Color(hex: 0x0F766E))
private let night = Art(a: Color(hex: 0x818CF8), b: Color(hex: 0x1E1B4B))

private func trip() -> [[Place]] {
    [
        [
            Place(id: 1, title: "Pastel de nata tasting", minutes: 45, kind: "Food", art: food),
            Place(id: 2, title: "Sunset at Miradouro da Graca", minutes: 60, kind: "Viewpoint", art: sights),
            Place(id: 3, title: "LX Factory market", minutes: 120, kind: "Shopping", art: culture),
            Place(id: 4, title: "Day trip to Sintra", minutes: 300, kind: "Day trip", art: nature, note: "Leave before 9am to beat the queues"),
            Place(id: 5, title: "Fado night in Alfama", minutes: 120, kind: "Music", art: night, booked: true),
        ],
        [
            Place(id: 6, title: "Alfama old town walk", minutes: 120, kind: "Walk", art: sights),
            Place(id: 7, title: "Lunch at Time Out Market", minutes: 75, kind: "Food", art: food),
            Place(id: 8, title: "Tram 28 to Estrela", minutes: 45, kind: "Ride", art: culture),
        ],
        [
            Place(id: 9, title: "Belem Tower", minutes: 90, kind: "Sights", art: sights, booked: true),
            Place(id: 10, title: "Pasteis de Belem", minutes: 45, kind: "Food", art: food),
            Place(id: 11, title: "MAAT museum", minutes: 120, kind: "Museum", art: culture, note: "Closes at 7pm"),
        ],
        [
            Place(id: 12, title: "Beach day in Cascais", minutes: 240, kind: "Beach", art: nature),
            Place(id: 13, title: "Dinner by the river", minutes: 120, kind: "Food", art: food),
        ],
    ]
}

struct TripPlanner: View {
    let theme: DemoTheme
    @StateObject private var state = DragBoardState(trip())

    var body: some View {
        DragBoard(
            state: state,
            columnWidth: 248,
            columnStyle: theme.roundedColumnStyle(18),
            appearance: theme.appearance(cornerRadius: 14, liftScale: 1.05)
        ) { index, places in
            let total = places.reduce(0) { $0 + $1.minutes }
            let over = index > 0 && total > dayLimitMinutes
            HStack(spacing: 8) {
                txt(tripColumns[index], 14, theme.text, .semibold)
                Spacer(minLength: 0)
                if index == 0 {
                    txt("\(places.count) ideas", 12, theme.muted)
                } else {
                    Image(systemName: "clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(over ? theme.accents[2] : theme.muted)
                    txt(over ? "\(fullDuration(total)), too packed" : fullDuration(total), 12,
                        over ? theme.accents[2] : theme.muted, .medium)
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 12)
        } card: { place in
            HStack(alignment: .top, spacing: 10) {
                txt(shortDuration(place.minutes), 12, .white, .bold)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 10).fill(place.art.gradient))
                VStack(alignment: .leading, spacing: 3) {
                    txt(place.title, 14, theme.text, .semibold).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        txt(place.kind, 12, theme.muted)
                        if place.booked {
                            txt("Booked", 10, theme.accents[0], .bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(theme.accents[0].opacity(0.16)))
                        }
                    }
                    if let note = place.note {
                        txt(note, 12, theme.muted).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(theme.card))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.cardBorder, lineWidth: 1))
        }
        .frame(height: 430)
    }
}
