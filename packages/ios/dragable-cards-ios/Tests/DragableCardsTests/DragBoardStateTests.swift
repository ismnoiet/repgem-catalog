import XCTest
@testable import DragableCards

private struct Card: Identifiable {
    let id: Int
}

final class DragBoardStateTests: XCTestCase {

    private func makeState() -> DragBoardState<Card> {
        DragBoardState([[Card(id: 1), Card(id: 2)], [Card(id: 3)], []])
    }

    func testExposesTheInitialColumns() {
        let state = makeState()
        XCTAssertEqual(state.columns.map { $0.map(\.id) }, [[1, 2], [3], []])
        XCTAssertFalse(state.isDragging)
    }

    func testUpdateColumnsReplacesTheLists() {
        let state = makeState()
        state.updateColumns([[Card(id: 9)], []])
        XCTAssertEqual(state.columns.map { $0.map(\.id) }, [[9], []])
    }

    func testStartingADragBeforeLayoutIsIgnored() {
        let state = makeState()
        state.begin(Card(id: 1))          // no frames reported yet
        XCTAssertFalse(state.isDragging)
    }

    func testStartingADragReadsTheReportedFrame() {
        let state = makeState()
        state.cardFrames = [1: CGRect(x: 0, y: 0, width: 200, height: 60)]
        state.begin(Card(id: 1))
        XCTAssertTrue(state.isDragging)
        XCTAssertEqual(state.cardSize, CGSize(width: 200, height: 60))
        XCTAssertEqual(state.targetColumn, 0)
        XCTAssertEqual(state.targetIndex, 0)
    }

    func testMovingOrDroppingWithoutADragDoesNothing() {
        let state = makeState()
        state.move(to: CGPoint(x: 50, y: 50), start: CGPoint(x: 50, y: 50))
        state.drop()
        XCTAssertFalse(state.isDragging)
        XCTAssertEqual(state.columns[0].map(\.id), [1, 2])
    }

    func testDraggingChangesTheTargetSlot() {
        let state = makeState()
        state.cardFrames = [
            1: CGRect(x: 16, y: 40, width: 280, height: 60),
            2: CGRect(x: 16, y: 108, width: 280, height: 60),
            3: CGRect(x: 308, y: 40, width: 280, height: 60),
        ]
        state.columnFrames = [
            0: CGRect(x: 16, y: 0, width: 280, height: 400),
            1: CGRect(x: 308, y: 0, width: 280, height: 400),
            2: CGRect(x: 600, y: 0, width: 280, height: 400),
        ]
        state.boardWidth = 1000   // everything is on screen, so nothing scrolls
        state.begin(Card(id: 1))

        state.move(to: CGPoint(x: 400, y: 200), start: CGPoint(x: 100, y: 60))   // below card 3
        XCTAssertEqual(state.targetColumn, 1)
        XCTAssertEqual(state.targetIndex, 1)

        state.move(to: CGPoint(x: 400, y: 10), start: CGPoint(x: 100, y: 60))    // above card 3
        XCTAssertEqual(state.targetColumn, 1)
        XCTAssertEqual(state.targetIndex, 0)

        state.move(to: CGPoint(x: 700, y: 300), start: CGPoint(x: 100, y: 60))   // the empty column
        XCTAssertEqual(state.targetColumn, 2)
        XCTAssertEqual(state.targetIndex, 0)
    }

    func testTimingDefaults() {
        let timing = DragTiming()
        XCTAssertEqual(timing.longPress, 0.15)
        XCTAssertEqual(timing.dropDuration, 0.25)
        XCTAssertEqual(timing.edgeScrollDelay, 0.7)
    }

    func testAppearanceDefaults() {
        let a = DragAppearance()
        XCTAssertTrue((1...1.1).contains(a.liftScale))
        XCTAssertTrue((0...10).contains(a.liftTilt))
        XCTAssertGreaterThan(a.liftShadow, 0)
    }
}
