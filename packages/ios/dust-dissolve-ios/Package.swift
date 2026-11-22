// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DustDissolve",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "DustDissolve", targets: ["DustDissolve"]),
        .library(name: "DustDissolveDemo", targets: ["DustDissolveDemo"]),
    ],
    targets: [
        .target(
            name: "DustDissolve",
            path: "Sources/DustDissolve",
            resources: [.process("Shaders")]   // compiles DustDissolve.metal into the bundle's metallib
        ),
        .target(
            name: "DustDissolveDemo",
            dependencies: ["DustDissolve"],
            path: "Sources/DustDissolveDemo"
        ),
        .testTarget(
            name: "DustDissolveTests",
            dependencies: ["DustDissolve"],
            path: "Tests/DustDissolveTests"
        ),
    ]
)
