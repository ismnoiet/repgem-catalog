//
//  BurstOriginTests.swift
//  FireworkFlourishTests
//
//  Author: ismnoiet
//
import XCTest
@testable import FireworkFlourish

final class BurstOriginTests: XCTestCase {

    func testIsDeterministicAndInsideTheStyleRanges() {
        let size = CGSize(width: 300, height: 200)
        let s = FireworkStyle.card
        for id in 0..<200 {
            let a = burstOrigin(s, id: id, size: size)
            let b = burstOrigin(s, id: id, size: size)
            XCTAssertEqual(a.cx, b.cx)
            XCTAssertEqual(a.cy, b.cy)
            XCTAssertGreaterThanOrEqual(a.cx, size.width * s.xRange.lowerBound)
            XCTAssertLessThanOrEqual(a.cx, size.width * s.xRange.upperBound)
            XCTAssertGreaterThanOrEqual(a.cy, size.height * s.yRange.lowerBound)
            XCTAssertLessThanOrEqual(a.cy, size.height * s.yRange.upperBound)
            XCTAssertGreaterThanOrEqual(a.scale, 0.7)
            XCTAssertLessThanOrEqual(a.scale, 1.3)
        }
    }

    func testReduceMotionCasesAreDistinct() {
        // .fade (the default) acknowledges the moment; .none draws nothing.
        XCTAssertNotEqual(FireworkReduceMotion.fade, FireworkReduceMotion.none)
    }
}
