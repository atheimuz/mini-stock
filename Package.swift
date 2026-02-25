// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MiniStock",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MiniStock",
            path: "MiniStock",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
