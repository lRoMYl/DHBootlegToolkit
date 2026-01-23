// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GitCore", targets: ["GitCore"])
    ],
    targets: [
        .target(
            name: "GitCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "GitCoreTests",
            dependencies: ["GitCore"]
        )
    ]
)
