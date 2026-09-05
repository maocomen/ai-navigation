// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "OrderContracts",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OrderContracts",
            targets: ["OrderContracts"]
        )
    ],
    targets: [
        .target(
            name: "OrderContracts",
            path: "Sources"
        )
    ]
)
