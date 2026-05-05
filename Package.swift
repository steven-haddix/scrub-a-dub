// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Scrubadub",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Scrubadub", targets: ["Scrubadub"]),
        .executable(name: "scrubadub", targets: ["scrubadub-cli"]),
        .library(name: "ScrubadubCore", targets: ["ScrubadubCore"]),
    ],
    targets: [
        .target(
            name: "ScrubadubCore",
            path: "Sources/ScrubadubCore"
        ),
        .executableTarget(
            name: "Scrubadub",
            dependencies: ["ScrubadubCore"],
            path: "Sources/Scrubadub",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "scrubadub-cli",
            dependencies: ["ScrubadubCore"],
            path: "Sources/scrubadub-cli"
        ),
        .testTarget(
            name: "ScrubadubCoreTests",
            dependencies: ["ScrubadubCore"],
            path: "Tests/ScrubadubCoreTests"
        ),
    ]
)
