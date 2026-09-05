// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "UserModule",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "UserModule",
            targets: ["UserModule"]
        )
    ],
    dependencies: [
        .package(path: "../AppBase")
    ],
    targets: [
        .target(
            name: "UserModule",
            dependencies: ["AppBase"]
        )
    ]
)
