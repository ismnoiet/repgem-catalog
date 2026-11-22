// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DragableCards",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "DragableCards", targets: ["DragableCards"]),
        .library(name: "DragableCardsDemo", targets: ["DragableCardsDemo"]),
    ],
    targets: [
        .target(
            name: "DragableCards",
            path: "Sources/DragableCards"
        ),
        .target(
            name: "DragableCardsDemo",
            dependencies: ["DragableCards"],
            path: "Sources/DragableCardsDemo"
        ),
        .testTarget(
            name: "DragableCardsTests",
            dependencies: ["DragableCards"],
            path: "Tests/DragableCardsTests"
        ),
    ]
)
