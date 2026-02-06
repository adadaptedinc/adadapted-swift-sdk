// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "adadapted-swift-sdk",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "adadapted-swift-sdk",
            targets: ["adadapted-swift-sdk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3")
    ],
    targets: [
        .target(
            name: "adadapted-swift-sdk",
            dependencies: [.product(name: "Logging", package: "swift-log")],
            resources: [.process("Assets.xcassets")]
        ),
        .testTarget(
            name: "adadapted-swift-sdkTests",
            dependencies: ["adadapted-swift-sdk"]
        ),
    ]
)
