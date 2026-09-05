// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "OrderModule",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OrderModule",
            targets: ["OrderModule"]
        )
    ],
    dependencies: [
        .package(path: "../AppBase")
    ],
    targets: [
        .target(
            name: "OrderModule",
            dependencies: ["AppBase"]
        )
    ]
)
