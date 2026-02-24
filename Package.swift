// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "StealthStockWidget",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "StealthStockWidget",
            path: "StealthStockWidget",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
