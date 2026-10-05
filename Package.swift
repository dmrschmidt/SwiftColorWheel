// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftColorWheel",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "SwiftColorWheel", targets: ["SwiftColorWheel"]),
    ],
    targets: [
        .target(name: "SwiftColorWheel"),
        .testTarget(name: "SwiftColorWheelTests", dependencies: ["SwiftColorWheel"]),
    ]
)
