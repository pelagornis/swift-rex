// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-rex",
    platforms: [
        .iOS(.v14),
        .macOS(.v14),
        .macCatalyst(.v14),
        .tvOS(.v14),
        .visionOS(.v2),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "Rex",
            targets: [
                "Rex"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.5")
    ],
    targets: [
        .target(name: "Rex"),
        .testTarget(
            name: "RexTests",
            dependencies: ["Rex"]
        )
    ]
)
