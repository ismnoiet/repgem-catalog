import XCTest
import SwiftUI
@testable import StickyRangeSlider

final class StickyMathTests: XCTestCase {
    private let bounds = 20...400

    func testSnapRoundsToStepAndClamps() {
        XCTAssertEqual(StickyMath.snap(187, step: 5, bounds: bounds), 185)
        XCTAssertEqual(StickyMath.snap(188, step: 5, bounds: bounds), 190)
        XCTAssertEqual(StickyMath.snap(-50, step: 5, bounds: bounds), 20)
        XCTAssertEqual(StickyMath.snap(9_999, step: 5, bounds: bounds), 400)
    }

    func testPositionAndValueRoundTrip() {
        let width: CGFloat = 300
        for v in stride(from: 20.0, through: 400.0, by: 20.0) {
            let x = StickyMath.x(for: v, width: width, bounds: bounds)
            XCTAssertEqual(StickyMath.value(atX: x, width: width, bounds: bounds), v, accuracy: 0.001)
        }
    }

    func testValueClampsOutsideTheTrack() {
        XCTAssertEqual(StickyMath.value(atX: -500, width: 300, bounds: bounds), 20)
        XCTAssertEqual(StickyMath.value(atX: 5_000, width: 300, bounds: bounds), 400)
    }

    func testMergeHasHysteresis() {
        // Apart -> stays apart until clearly inside the merge distance.
        XCTAssertFalse(StickyMath.merged(current: false, distance: 52))
        XCTAssertTrue(StickyMath.merged(current: false, distance: 40))
        // Fused -> stays fused until clearly outside the split distance.
        XCTAssertTrue(StickyMath.merged(current: true, distance: 52))
        XCTAssertFalse(StickyMath.merged(current: true, distance: 60))
    }

    func testPillWidthGrowsWithText() {
        XCTAssertLessThan(StickyMath.pillWidth(for: "$85"), StickyMath.pillWidth(for: "$185"))
        XCTAssertEqual(StickyMath.pillWidth(for: "$185"), 4 * 7.2 + 20, accuracy: 0.01)
    }

    func testSimSettlesOnItsTargets() {
        let sim = StickySim()
        var now = Date()
        sim.step(now, tLo: 50, tHi: 200, tM: 0, timing: .default)   // primes at the targets
        for _ in 0..<120 {                                           // 2 s at 60 fps
            now.addTimeInterval(1.0 / 60.0)
            sim.step(now, tLo: 120, tHi: 200, tM: 1, timing: .default)
        }
        XCTAssertTrue(sim.isSettled(tLo: 120, tHi: 200, tM: 1))
    }

    func testReduceMotionJumpsToTargets() {
        let sim = StickySim()
        let now = Date()
        sim.step(now, tLo: 50, tHi: 200, tM: 0, timing: .default)
        sim.step(now.addingTimeInterval(0.016), tLo: 120, tHi: 220, tM: 1, timing: .default, instant: true)
        XCTAssertEqual(sim.xLo, 120)
        XCTAssertEqual(sim.xHi, 220)
        XCTAssertEqual(sim.m, 1)
    }
}
