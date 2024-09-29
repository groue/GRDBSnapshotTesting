// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GRDBSnapshotTesting",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GRDBSnapshotTesting",
            targets: ["GRDBSnapshotTesting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0-beta"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GRDBSnapshotTesting",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
        .testTarget(
            name: "GRDBSnapshotTestingTests",
            dependencies: [
                "GRDBSnapshotTesting",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ],
            resources: [
                .copy("Fixtures"),
            ]),
    ]
)
