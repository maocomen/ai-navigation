// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "ProductModule",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ProductModule",
            targets: ["ProductModule"]
        )
    ],
    dependencies: [
        .package(path: "../AppBase"),
        .package(path: "../ProductContracts"),
        .package(path: "../OrderContracts")
    ],
    targets: [
        .target(
            name: "ProductModule",
            dependencies: ["AppBase", "ProductContracts", "OrderContracts"]
        )
    ]
)
