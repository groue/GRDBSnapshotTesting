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
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.20.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.14.1"),
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
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: [
                "__Snapshots__",
            ],
            resources: [
                .copy("Fixtures"),
            ]),
    ]
)
