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
        .package(url: "https://github.com/swiftlang/swift-docc", from: "swift-6.1.1-RELEASE")
    ],
    targets: [
        .target(name: "Rex"),
        .testTarget(
            name: "RexTests",
            dependencies: ["Rex"]
        )
    ]
)
