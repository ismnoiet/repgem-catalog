//
//  HashTests.swift
//  FireworkFlourishTests
//
//  Author: ismnoiet
//
import XCTest
@testable import FireworkFlourish

final class HashTests: XCTestCase {

    func testIsDeterministicAndInRange() {
        for i in 0..<500 {
            let a = hash01(i, 7)
            XCTAssertEqual(a, hash01(i, 7))
            XCTAssertGreaterThanOrEqual(a, 0)
            XCTAssertLessThan(a, 1)
        }
    }

    func testDoesNotCollapseToOneValue() {
        let values = Set((0..<50).map { hash01($0, 3) })
        XCTAssertGreaterThan(values.count, 40)
    }

    /// Golden values, also asserted in the Android package's tests, so both platforms draw
    /// the same fireworks for the same seed.
    func testMatchesGoldenValues() {
        let golden: [(Int, Int, Double)] = [
            (0, 0, 0.607535),
            (1, 1, 0.015792),
            (7, 3, 0.033577),
            (42, 100, 0.50922),
            (123456, 600, 0.93989),
            (99_999_000, 2, 0.99009),
        ]
        for (seed, k, expected) in golden {
            XCTAssertEqual(hash01(seed, k), expected, accuracy: 1e-9, "hash01(\(seed), \(k))")
        }
    }
}
