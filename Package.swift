// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CryptoFloat",
    platforms: [
        .macOS(.v11)
    ],
    targets: [
        .target(
            name: "CryptoFloatCore",
            path: "Sources/CryptoFloatCore"
        ),
        .testTarget(
            name: "CryptoFloatCoreTests",
            dependencies: ["CryptoFloatCore"],
            path: "Tests/CryptoFloatCoreTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
