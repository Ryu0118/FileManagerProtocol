// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FileManagerProtocol",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "FileManagerProtocol",
            targets: ["FileManagerProtocol"]
        ),
    ],
    targets: [
        .target(
            name: "FileManagerProtocol"
        ),
        .testTarget(
            name: "FileManagerProtocolTests",
            dependencies: ["FileManagerProtocol"]
        ),
    ]
)
