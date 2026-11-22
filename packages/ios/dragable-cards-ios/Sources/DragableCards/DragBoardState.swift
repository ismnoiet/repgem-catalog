//
//  DragBoardState.swift
//  DragableCards
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  The cards of every column plus all the drag state. Create it once with `@StateObject`.
//
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Finger-follow position lives in its own tiny observable so only the floating card
/// re-renders every frame, not the whole board.
final class DragPoint: ObservableObject {
    @Published var center: CGPoint = .zero
}

enum FrameTag: Hashable {
    case card(AnyHashable)
    case column(Int)
    case placeholder
}

struct FramesKey: PreferenceKey {
    static var defaultValue: [FrameTag: CGRect] = [:]
    static func reduce(value: inout [FrameTag: CGRect], nextValue: () -> [FrameTag: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Light, medium and selection haptics (no-ops where UIKit is not available).
final class DragHaptics {
    #if canImport(UIKit) && !os(visionOS)
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let soft = UIImpactFeedbackGenerator(style: .light)
    private let tick = UISelectionFeedbackGenerator()
    func prepare() { impact.prepare(); tick.prepare() }
    func lift() { impact.impactOccurred() }
    func change() { tick.selectionChanged(); tick.prepare() }
    func drop() { soft.impactOccurred() }
    #else
    func prepare() {}
    func lift() {}
    func change() {}
    func drop() {}
    #endif
}

/// Holds the columns and the state of the drag in progress.
///
/// ```swift
/// @StateObject private var state = DragBoardState([[task1, task2], [task3], []])
/// ```
public final class DragBoardState<Item: Identifiable>: ObservableObject {
    /// The cards of every column, in order. Changes when a card lands.
    @Published public private(set) var columns: [[Item]]

    let drag = DragPoint()
    private let haptics = DragHaptics()

    // drag state
    @Published var dragging: Item?
    @Published var targetColumn = 0
    @Published var targetIndex = 0
    @Published var cardSize: CGSize = .zero
    @Published var isLifted = false
    @Published var isDropping = false
    /// Offset of the landing card from its slot; springs to .zero on release.
    @Published var landing: CGSize = .zero

    var sourceColumn = 0
    private var grab: CGSize?
    private var originCenter: CGPoint = .zero
    var cardFrames: [Item.ID: CGRect] = [:]
    var columnFrames: [Int: CGRect] = [:]
    var placeholderFrame: CGRect = .zero
    var boardWidth: CGFloat = 390
    var scrollTo: ((Int, UnitPoint) -> Void)?
    private var lastScroll = Date.distantPast

    var timing = DragTiming()
    var onMove: ((Item, Int, Int, Int) -> Void)?

    public init(_ columns: [[Item]]) {
        self.columns = columns
    }

    /// True from the long press until the card has landed.
    public var isDragging: Bool { dragging != nil }

    /// Replaces the lists, for example after loading from a server. Ignored while a card is being dragged.
    public func updateColumns(_ columns: [[Item]]) {
        guard dragging == nil else { return }
        self.columns = columns
    }

    // MARK: - Drag

    func locate(_ id: Item.ID) -> (col: Int, idx: Int)? {
        for (c, column) in columns.enumerated() {
            if let i = column.firstIndex(where: { $0.id == id }) { return (c, i) }
        }
        return nil
    }

    func begin(_ item: Item) {
        guard dragging == nil, let loc = locate(item.id), let frame = cardFrames[item.id] else { return }
        cardSize = frame.size
        originCenter = CGPoint(x: frame.midX, y: frame.midY)
        drag.center = originCenter
        grab = nil
        haptics.prepare()
        sourceColumn = loc.col
        targetColumn = loc.col
        targetIndex = loc.idx
        haptics.lift()
        withAnimation(timing.lift) {
            dragging = item
            isLifted = true
        }
    }

    func move(to location: CGPoint, start: CGPoint) {
        guard let dragging, !isDropping else { return }
        if grab == nil {
            grab = CGSize(width: start.x - originCenter.x, height: start.y - originCenter.y)
        }
        let g = grab ?? .zero
        drag.center = CGPoint(x: location.x - g.width, y: location.y - g.height)

        // Nearest column to the finger (no dead zones between columns).
        let ranges: [ClosedRange<CGFloat>?] = columns.indices.map { i in
            columnFrames[i].map { $0.minX...$0.maxX }
        }
        let col = DragMath.nearestColumn(x: location.x, ranges: ranges, fallback: targetColumn)

        // Insertion index among the other cards in that column.
        let mids = columns[col]
            .filter { $0.id != dragging.id }
            .map { cardFrames[$0.id]?.midY ?? .infinity }
        let idx = DragMath.insertionIndex(pointerY: location.y, midYs: mids)

        if col != targetColumn, let f = columnFrames[col] {
            // Entering a column that isn't fully on screen: scroll it into view.
            let inset: CGFloat = 16
            if f.minX < inset {
                lastScroll = Date()
                scrollTo?(col, .leading)
            } else if f.maxX > boardWidth - inset {
                lastScroll = Date()
                scrollTo?(col, .trailing)
            }
        }

        if col != targetColumn || idx != targetIndex {
            haptics.change()
            withAnimation(timing.shuffle) {
                targetColumn = col
                targetIndex = idx
            }
        }

        // Holding near an edge brings in the next column.
        let now = Date()
        if now.timeIntervalSince(lastScroll) > timing.edgeScrollDelay {
            if location.x < 56, targetColumn > 0 {
                lastScroll = now
                scrollTo?(targetColumn - 1, .leading)
            } else if location.x > boardWidth - 56, targetColumn < columns.count - 1 {
                lastScroll = now
                scrollTo?(targetColumn + 1, .trailing)
            }
        }
    }

    func drop() {
        guard dragging != nil, !isDropping else { return }
        haptics.drop()
        // 1. Hand off: render the card inside its slot, offset to exactly where the floating card
        //    is (no animation, so the swap is invisible).
        let c = drag.center, p = placeholderFrame
        landing = p == .zero ? .zero : CGSize(width: c.x - p.midX, height: c.y - p.midY)
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { isDropping = true }
        // 2. Next frame: spring the offset (and tilt, scale and shadow) to rest. The card lives in
        //    the layout, so scrolling or neighbours settling can't desync it.
        DispatchQueue.main.async { [self] in
            withAnimation(timing.drop) {
                landing = .zero
                isLifted = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.dropDuration) { [self] in
            commit()
        }
    }

    private func commit() {
        guard let item = dragging else { return }
        let from = sourceColumn
        let to = targetColumn
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            columns = DragMath.moveItem(columns, id: item.id, toColumn: to, toIndex: targetIndex)
            dragging = nil
            isDropping = false
            landing = .zero
        }
        let index = columns[to].firstIndex { $0.id == item.id } ?? 0
        onMove?(item, from, to, index)
    }
}
