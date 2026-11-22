import XCTest
import SwiftUI
@testable import DustDissolve

/// Pure configuration tests: no rendering, no Metal. Mirrors DustDissolveConfigurationTest.kt on Android.
final class DustDissolveConfigurationTests: XCTestCase {
    func testDefaultsMatchTheCouponRecording() {
        let c = DustDissolveConfiguration()
        XCTAssertTrue(c.shimmer)
        XCTAssertEqual(c.dissolveStart, 0.55)
        XCTAssertEqual(c.dissolveEnd, 1.10)
        XCTAssertEqual(c.total, 3.0)
        XCTAssertEqual(c.particleCount, 1100)
    }

    func testArrivalIsWhenTheFirstDotLands() {
        let c = DustDissolveConfiguration()
        XCTAssertEqual(c.arrival, c.flightStart + 0.8, accuracy: 0.0001)
    }

    func testPastelPaletteHasSixColors() {
        XCTAssertEqual(DustDissolveConfiguration.pastel.count, 6)
        XCTAssertEqual(DustDissolveConfiguration().palette.count, 6)
    }

    func testPresetsTurnTheShimmerOffExceptCoupon() {
        XCTAssertTrue(DustDissolveConfiguration.coupon.shimmer)
        for c in [DustDissolveConfiguration.snap, .dismiss, .fall, .burst] { XCTAssertFalse(c.shimmer) }
    }

    func testFallGoesTopToBottomAndBurstIsRoundFromTheCentre() {
        XCTAssertEqual(DustDissolveConfiguration.fall.direction, .topToBottom)
        XCTAssertEqual(DustDissolveConfiguration.burst.direction, .centerOut)
        if case .ellipse = DustDissolveConfiguration.burst.shape {} else { XCTFail("burst should be an ellipse") }
    }

    func testEveryPresetEndsAfterItsDustHasLeft() {
        for c in [DustDissolveConfiguration.coupon, .snap, .dismiss, .fall, .burst] {
            XCTAssertGreaterThan(c.total, c.dissolveEnd)
            XCTAssertGreaterThanOrEqual(c.total, c.flightStart)
        }
    }

    func testEasingHelpersStayInRangeAndHitTheirEnds() {
        XCTAssertEqual(ramp(0.5, 0, 1), 0.5, accuracy: 0.0001)
        XCTAssertEqual(ramp(-1, 0, 1), 0)
        XCTAssertEqual(ramp(2, 0, 1), 1)
        XCTAssertEqual(smooth(0), 0)
        XCTAssertEqual(smooth(1), 1)
        XCTAssertEqual(easeOut(0), 0, accuracy: 0.0001)
        XCTAssertEqual(easeOut(1), 1, accuracy: 0.0001)
    }
}
