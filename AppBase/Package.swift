// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "AppBase",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AppBase",
            targets: ["AppBase"]
        )
    ],
    targets: [
        .target(
            name: "AppBase",
            path: "Sources"
        ),
        .testTarget(
            name: "AppBaseTests",
            dependencies: ["AppBase"],
            path: "Tests"
        )
    ]
)
