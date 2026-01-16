// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DHBootlegToolkitCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DHBootlegToolkitCore", targets: ["DHBootlegToolkitCore"])
    ],
    targets: [
        .target(
            name: "DHBootlegToolkitCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "DHBootlegToolkitCoreTests",
            dependencies: ["DHBootlegToolkitCore"]
        )
    ]
)
