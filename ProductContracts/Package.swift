// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "ProductContracts",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ProductContracts",
            targets: ["ProductContracts"]
        )
    ],
    targets: [
        .target(
            name: "ProductContracts",
            path: "Sources"
        )
    ]
)
