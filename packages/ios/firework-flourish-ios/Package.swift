// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FireworkFlourish",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "FireworkFlourish", targets: ["FireworkFlourish"]),
        .library(name: "FireworkFlourishDemo", targets: ["FireworkFlourishDemo"]),
    ],
    targets: [
        .target(
            name: "FireworkFlourish",
            path: "Sources/FireworkFlourish"
        ),
        .target(
            name: "FireworkFlourishDemo",
            dependencies: ["FireworkFlourish"],
            path: "Sources/FireworkFlourishDemo"
        ),
        .testTarget(
            name: "FireworkFlourishTests",
            dependencies: ["FireworkFlourish"],
            path: "Tests/FireworkFlourishTests"
        ),
    ]
)
