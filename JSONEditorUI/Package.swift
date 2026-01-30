// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JSONEditorUI",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "JSONEditorUI", targets: ["JSONEditorUI"])
    ],
    dependencies: [
        .package(path: "../JSONEditorCore")
    ],
    targets: [
        .target(
            name: "JSONEditorUI",
            dependencies: ["JSONEditorCore"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
