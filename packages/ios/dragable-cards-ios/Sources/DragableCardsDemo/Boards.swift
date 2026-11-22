//
//  Boards.swift
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  The GitHub-style project board, themed so the dark and light pages show exactly the same layout.
//
import SwiftUI
import DragableCards

private struct Issue: Identifiable {
    let id: Int
    var title: String
    var estimate = 1
    var avatar: (String, Color)? = nil
    var tracking = false
}

private struct StatusColumn {
    let title: String
    let subtitle: String
    let accent: Int
    let limit: Int?
}

private let statusColumns = [
    StatusColumn(title: "Backlog", subtitle: "This item hasn't been started", accent: 0, limit: 5),
    StatusColumn(title: "Ready", subtitle: "This is ready to be picked up", accent: 1, limit: nil),
    StatusColumn(title: "In progress", subtitle: "This is actively being worked on", accent: 2, limit: 3),
    StatusColumn(title: "In review", subtitle: "This item is in review", accent: 3, limit: 5),
]

private let jd = ("JD", Color(hex: 0x2D333B))
private let am = ("AM", Color(hex: 0xB5651D))
private let tk = ("TK", Color(hex: 0x6E4B8B))

private func projectIssues() -> [[Issue]] {
    [
        [
            Issue(id: 1366, title: "Explore a bug"),
            Issue(id: 821, title: "Updates to alien, beam, bomb and cannon sprites", estimate: 2, avatar: am),
        ],
        [Issue(id: 797, title: "Easter egg with high score unlocking new paid levels", avatar: jd)],
        [
            Issue(id: 1304, title: "Make sure that it delights customers", avatar: jd),
            Issue(id: 829, title: "Hero site - Copy"),
        ],
        [Issue(id: 1101, title: "[Tracking] Integrate payments system", avatar: tk, tracking: true)],
    ]
}

struct ProjectBoard: View {
    let theme: DemoTheme
    @StateObject private var state = DragBoardState(projectIssues())

    var body: some View {
        DragBoard(
            state: state,
            columnStyle: theme.columnStyle,
            appearance: theme.appearance()
        ) { index, issues in
            ProjectHeader(theme: theme, column: statusColumns[index], issues: issues)
        } card: { issue in
            IssueCard(theme: theme, issue: issue)
        }
        .frame(height: 430)
    }
}

private struct ProjectHeader: View {
    let theme: DemoTheme
    let column: StatusColumn
    let issues: [Issue]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle().stroke(theme.accents[column.accent], lineWidth: 2).frame(width: 14, height: 14)
                txt(column.title, 14, theme.text, .semibold)
                Pill(theme: theme, text: column.limit.map { "\(issues.count)/\($0)" } ?? "\(issues.count)")
                Pill(theme: theme, text: "Estimate: \(issues.reduce(0) { $0 + $1.estimate })")
                Spacer(minLength: 0)
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.muted)
            }
            .lineLimit(1)
            txt(column.subtitle, 13, theme.muted)
        }
        .padding(.bottom, 12)
    }
}

private struct IssueCard: View {
    let theme: DemoTheme
    let issue: Issue

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: issue.tracking ? "checkmark.circle" : "smallcircle.filled.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(issue.tracking ? theme.accents[3] : theme.accents[0])
                txt("planning-tracking-demo #\(issue.id)", 12, theme.muted).lineLimit(1)
                Spacer(minLength: 4)
                if let a = issue.avatar { AvatarDot(initials: a.0, color: a.1) }
            }
            txt(issue.title, 14, theme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6).fill(theme.card))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.cardBorder, lineWidth: 1))
    }
}
