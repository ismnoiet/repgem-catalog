//
//  FireworkStyleTests.swift
//  FireworkFlourishTests
//
//  Author: ismnoiet
//
import XCTest
@testable import FireworkFlourish

final class FireworkStyleTests: XCTestCase {

    func testDefaultsMatchTheCardPreset() {
        let d = FireworkStyle()
        let c = FireworkStyle.card
        XCTAssertEqual(d.interval, c.interval)
        XCTAssertEqual(d.particles, c.particles)
        XCTAssertEqual(d.maxRadius, c.maxRadius)
        XCTAssertEqual(c.interval, 0.30, accuracy: 1e-9)
        XCTAssertEqual(c.particles, 64)
    }

    func testTotalLifeCoversRocketAndFade() {
        let s = FireworkStyle(rocketTime: 0.5, burstLife: 2.0)
        XCTAssertEqual(s.totalLife, 2.7, accuracy: 1e-9)
    }

    func testEveryPresetHasAUniqueNameAndUsableValues() {
        let names = FireworkStyle.all.map(\.name)
        XCTAssertEqual(names.count, 13)
        XCTAssertEqual(Set(names).count, names.count)
        for (name, style) in FireworkStyle.all {
            XCTAssertGreaterThan(style.interval, 0, "\(name) needs a positive interval")
            XCTAssertGreaterThan(style.particles, 0, "\(name) needs particles")
            XCTAssertFalse(style.palettes.isEmpty, "\(name) needs palettes")
            XCTAssertGreaterThanOrEqual(style.yRange.lowerBound, 0, "\(name) yRange")
            XCTAssertLessThanOrEqual(style.yRange.upperBound, 1, "\(name) yRange")
            XCTAssertGreaterThanOrEqual(style.xRange.lowerBound, 0, "\(name) xRange")
            XCTAssertLessThanOrEqual(style.xRange.upperBound, 1, "\(name) xRange")
        }
    }

    func testPresetNamesMatchTheAndroidPackage() {
        XCTAssertEqual(
            FireworkStyle.all.map(\.name),
            ["card", "subtle", "milestone", "grand", "tap", "romance", "neonPop",
             "embers", "sparkle", "pastelBloom", "newYear", "like", "frost"]
        )
    }

    func testEmbersRiseAndHaveNoRockets() {
        XCTAssertLessThan(FireworkStyle.embers.gravity, 0)
        XCTAssertFalse(FireworkStyle.embers.showRockets)
    }

    func testEveryPaletteHasColors() {
        XCTAssertEqual(FireworkPalette.all.count, 9)
        for (name, colors) in FireworkPalette.all {
            XCTAssertFalse(colors.isEmpty, "\(name) is empty")
        }
    }

    func testNewYearMixesRainbowAndGold() {
        XCTAssertEqual(FireworkStyle.newYear.palettes.count,
                       FireworkPalette.rainbow.count + FireworkPalette.gold.count)
    }
}
