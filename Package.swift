// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalhostWatcher",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LocalhostWatcher",
            path: "Sources/LocalhostWatcher",
            resources: [
                .copy("Resources/AppIcon.icns")
            ]
        ),
        .testTarget(
            name: "LocalhostWatcherTests",
            dependencies: ["LocalhostWatcher"]
        )
    ]
)
