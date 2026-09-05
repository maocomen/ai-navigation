// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "UserContracts",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "UserContracts",
            targets: ["UserContracts"]
        )
    ],
    targets: [
        .target(
            name: "UserContracts",
            path: "Sources"
        )
    ]
)
