// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iOSImageOptimizer",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "iOSImageOptimizer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Files",
                "Rainbow"
            ]
        ),
        .testTarget(
            name: "iOSImageOptimizerTests",
            dependencies: ["iOSImageOptimizer"]
        )
    ]
)