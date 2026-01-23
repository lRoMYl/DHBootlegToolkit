// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JSONEditorCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "JSONEditorCore", targets: ["JSONEditorCore"])
    ],
    targets: [
        .target(
            name: "JSONEditorCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "JSONEditorCoreTests",
            dependencies: ["JSONEditorCore"]
        )
    ]
)
