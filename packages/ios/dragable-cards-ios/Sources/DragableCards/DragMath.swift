//
//  DragMath.swift
//  DragableCards
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  The decisions of the interaction as pure functions (no views, no state), so they can be tested.
//
import CoreGraphics

enum DragMath {
    /// Which slot the pointer is over: the number of cards whose middle is above it.
    /// `midYs` are the middles of the cards in the column, without the dragged one.
    static func insertionIndex(pointerY: CGFloat, midYs: [CGFloat]) -> Int {
        midYs.filter { $0 < pointerY }.count
    }

    /// The column closest to the pointer horizontally. A pointer inside a column has distance 0 and
    /// a pointer in a gap goes to the nearer side, so there are no dead zones.
    /// `ranges` holds each column's horizontal extent, or nil while it is not laid out.
    static func nearestColumn(x: CGFloat, ranges: [ClosedRange<CGFloat>?], fallback: Int) -> Int {
        var best = CGFloat.infinity
        var column = fallback
        for (index, range) in ranges.enumerated() {
            guard let range else { continue }
            let distance = max(range.lowerBound - x, 0, x - range.upperBound)
            if distance < best {
                best = distance
                column = index
            }
        }
        return column
    }

    /// Where the empty slot goes in a column's row list. The list holds every card, including the
    /// dragged one (kept in place, collapsed to zero height). `targetIndex` counts the cards without
    /// the dragged one, so the slot goes in front of the `targetIndex`-th other card, or at the end.
    static func slotRowIndex<ID: Equatable>(ids: [ID], draggedID: ID, targetIndex: Int) -> Int {
        let others = ids.indices.filter { ids[$0] != draggedID }
        return targetIndex >= others.count ? ids.count : others[max(targetIndex, 0)]
    }

    /// Returns `columns` with the item moved to `toColumn` at `toIndex`. The index counts that column
    /// without the moved item and is clamped. An unknown id or column returns the input unchanged.
    static func moveItem<T: Identifiable>(
        _ columns: [[T]], id: T.ID, toColumn: Int, toIndex: Int
    ) -> [[T]] {
        guard columns.indices.contains(toColumn),
              let source = columns.firstIndex(where: { column in column.contains { $0.id == id } }),
              let position = columns[source].firstIndex(where: { $0.id == id })
        else { return columns }

        var result = columns
        let item = result[source].remove(at: position)
        let at = min(max(toIndex, 0), result[toColumn].count)
        result[toColumn].insert(item, at: at)
        return result
    }
}
