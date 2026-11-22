// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "StickyRangeSlider",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "StickyRangeSlider", targets: ["StickyRangeSlider"]),
        .library(name: "StickyRangeSliderDemo", targets: ["StickyRangeSliderDemo"]),
    ],
    targets: [
        .target(
            name: "StickyRangeSlider",
            path: "Sources/StickyRangeSlider"
        ),
        .target(
            name: "StickyRangeSliderDemo",
            dependencies: ["StickyRangeSlider"],
            path: "Sources/StickyRangeSliderDemo"
        ),
        .testTarget(
            name: "StickyRangeSliderTests",
            dependencies: ["StickyRangeSlider"],
            path: "Tests/StickyRangeSliderTests"
        ),
    ]
)
