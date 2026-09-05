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
        .package(path: "../AppBase")
    ],
    targets: [
        .target(
            name: "ProductModule",
            dependencies: ["AppBase"]
        )
    ]
)
