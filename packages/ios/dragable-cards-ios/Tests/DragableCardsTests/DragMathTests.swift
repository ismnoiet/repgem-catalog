import XCTest
@testable import DragableCards

private struct Card: Identifiable, Equatable {
    let id: String
}

final class DragMathTests: XCTestCase {

    private let board: [[Card]] = [
        [Card(id: "a"), Card(id: "b"), Card(id: "c")],
        [Card(id: "d")],
        [],
    ]

    private func ids(_ columns: [[Card]]) -> [[String]] { columns.map { $0.map(\.id) } }

    // ---- insertion index ---------------------------------------------------------------------

    func testInsertionIndexCountsCardsAboveThePointer() {
        let mids: [CGFloat] = [50, 150, 250]
        XCTAssertEqual(DragMath.insertionIndex(pointerY: 0, midYs: mids), 0)
        XCTAssertEqual(DragMath.insertionIndex(pointerY: 100, midYs: mids), 1)
        XCTAssertEqual(DragMath.insertionIndex(pointerY: 200, midYs: mids), 2)
        XCTAssertEqual(DragMath.insertionIndex(pointerY: 900, midYs: mids), 3)
    }

    func testInsertionIndexOnAnEmptyColumnIsZero() {
        XCTAssertEqual(DragMath.insertionIndex(pointerY: 300, midYs: []), 0)
    }

    func testInsertionIndexIgnoresCardsThatAreNotLaidOutYet() {
        XCTAssertEqual(DragMath.insertionIndex(pointerY: 300, midYs: [50, .infinity]), 1)
    }

    // ---- nearest column ----------------------------------------------------------------------

    private let columns: [ClosedRange<CGFloat>?] = [16...296, 308...588, 600...880]

    func testPointerInsideAColumnPicksThatColumn() {
        XCTAssertEqual(DragMath.nearestColumn(x: 100, ranges: columns, fallback: 0), 0)
        XCTAssertEqual(DragMath.nearestColumn(x: 450, ranges: columns, fallback: 0), 1)
        XCTAssertEqual(DragMath.nearestColumn(x: 700, ranges: columns, fallback: 0), 2)
    }

    func testPointerInAGapGoesToTheNearerSide() {
        XCTAssertEqual(DragMath.nearestColumn(x: 299, ranges: columns, fallback: 2), 0)
        XCTAssertEqual(DragMath.nearestColumn(x: 305, ranges: columns, fallback: 0), 1)
    }

    func testPointerOutsideTheBoardPicksTheEdgeColumn() {
        XCTAssertEqual(DragMath.nearestColumn(x: -50, ranges: columns, fallback: 1), 0)
        XCTAssertEqual(DragMath.nearestColumn(x: 5000, ranges: columns, fallback: 1), 2)
    }

    func testColumnsThatAreNotLaidOutAreSkipped() {
        XCTAssertEqual(DragMath.nearestColumn(x: 100, ranges: [nil, nil], fallback: 1), 1)
        XCTAssertEqual(DragMath.nearestColumn(x: 100, ranges: [nil, 308...588], fallback: 0), 1)
    }

    // ---- slot placement in the row list ------------------------------------------------------

    func testSlotStaysWhereTheDraggedCardWas() {
        // "b" is lifted and hasn't moved: the slot sits right after it, before "c".
        XCTAssertEqual(DragMath.slotRowIndex(ids: ["a", "b", "c"], draggedID: "b", targetIndex: 1), 2)
    }

    func testSlotGoesInFrontOfTheTargetCard() {
        let ids = ["a", "b", "c", "d"]
        XCTAssertEqual(DragMath.slotRowIndex(ids: ids, draggedID: "c", targetIndex: 0), 0)
        XCTAssertEqual(DragMath.slotRowIndex(ids: ids, draggedID: "c", targetIndex: 1), 1)
        XCTAssertEqual(DragMath.slotRowIndex(ids: ids, draggedID: "c", targetIndex: 2), 3) // skips the lifted "c"
        XCTAssertEqual(DragMath.slotRowIndex(ids: ids, draggedID: "c", targetIndex: 3), 4) // at the end
    }

    func testSlotInAnotherColumnIgnoresTheDraggedID() {
        XCTAssertEqual(DragMath.slotRowIndex(ids: ["d", "e"], draggedID: "a", targetIndex: 0), 0)
        XCTAssertEqual(DragMath.slotRowIndex(ids: ["d", "e"], draggedID: "a", targetIndex: 1), 1)
        XCTAssertEqual(DragMath.slotRowIndex(ids: ["d", "e"], draggedID: "a", targetIndex: 2), 2)
        XCTAssertEqual(DragMath.slotRowIndex(ids: [String](), draggedID: "a", targetIndex: 0), 0)
    }

    // ---- moving ------------------------------------------------------------------------------

    func testMoveWithinTheSameColumn() {
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "c", toColumn: 0, toIndex: 0)), [["c", "a", "b"], ["d"], []])
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "a", toColumn: 0, toIndex: 2)), [["b", "c", "a"], ["d"], []])
    }

    func testMoveToAnotherColumn() {
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "b", toColumn: 1, toIndex: 0)), [["a", "c"], ["b", "d"], []])
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "b", toColumn: 2, toIndex: 0)), [["a", "c"], ["d"], ["b"]])
    }

    func testMoveClampsTheIndex() {
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "a", toColumn: 1, toIndex: 99)), [["b", "c"], ["d", "a"], []])
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "a", toColumn: 1, toIndex: -5)), [["b", "c"], ["a", "d"], []])
    }

    func testUnknownIDOrColumnReturnsTheInput() {
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "zzz", toColumn: 0, toIndex: 0)), ids(board))
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "a", toColumn: 7, toIndex: 0)), ids(board))
    }

    func testMovingToTheSamePlaceChangesNothing() {
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "b", toColumn: 0, toIndex: 1)), ids(board))
        XCTAssertEqual(ids(DragMath.moveItem(board, id: "d", toColumn: 1, toIndex: 0)), ids(board))
    }

    func testMovingNeverLosesOrDuplicatesCards() {
        var current = board
        let steps: [(String, Int, Int)] = [("a", 2, 0), ("d", 0, 3), ("b", 2, 1), ("a", 1, 0), ("c", 0, 0), ("d", 2, 2)]
        for (id, column, index) in steps {
            current = DragMath.moveItem(current, id: id, toColumn: column, toIndex: index)
            XCTAssertEqual(current.flatMap { $0 }.map(\.id).sorted(), ["a", "b", "c", "d"])
        }
    }

    // ---- regression: moving up and moving down must swap at the same distance -----------------

    func testMovingUpAndDownSwapAtTheSameDistance() {
        // The dragged card's centre starts at 250; the others sit at 50, 150 and 350.
        let others: [CGFloat] = [50, 150, 350]
        let up = stride(from: CGFloat(250), through: 0, by: -1).first { DragMath.insertionIndex(pointerY: $0, midYs: others) < 2 }!
        let down = stride(from: CGFloat(250), through: 500, by: 1).first { DragMath.insertionIndex(pointerY: $0, midYs: others) > 2 }!
        XCTAssertEqual(250 - up, 100, accuracy: 1)
        XCTAssertEqual(down - 250, 100, accuracy: 1)
    }

    func testWalkingAcrossAColumnVisitsEverySlotInOrder() {
        let others: [CGFloat] = (0..<5).map { 50 + CGFloat($0) * 100 }
        let down = stride(from: CGFloat(0), through: 500, by: 10).map { DragMath.insertionIndex(pointerY: $0, midYs: others) }
        let up = stride(from: CGFloat(500), through: 0, by: -10).map { DragMath.insertionIndex(pointerY: $0, midYs: others) }
        XCTAssertEqual(up.reversed(), down)
        XCTAssertEqual(down.reduce(into: [Int]()) { if !$0.contains($1) { $0.append($1) } }, [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(down, down.sorted())
    }
}
