// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "adadapted-swift-sdk",
    platforms: [.iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "adadapted-swift-sdk",
            targets: ["adadapted-swift-sdk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        //.package(url: "https://github.com/developerinsider/SPMDeveloperInsider", from: "1.0.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "adadapted-swift-sdk", dependencies: [.product(name: "Logging", package: "swift-log")]),
        .testTarget(name: "adadapted-swift-sdkTests",dependencies: ["adadapted-swift-sdk"]),
    ]
)
