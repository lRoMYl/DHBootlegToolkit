// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JSONEditorKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "JSONEditorKit", targets: ["JSONEditorKit"])
    ],
    dependencies: [
        .package(path: "../GitCore"),
        .package(path: "../JSONEditorCore"),
        .package(path: "../JSONEditorUI")
    ],
    targets: [
        .target(
            name: "JSONEditorKit",
            dependencies: ["GitCore", "JSONEditorCore", "JSONEditorUI"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "JSONEditorKitTests",
            dependencies: ["JSONEditorKit"]
        )
    ]
)
