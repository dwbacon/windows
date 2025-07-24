
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "DockPreviews",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DockPreviews", targets: ["DockPreviews"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DockPreviews",
            path: "Sources/DockPreviews"
        )
    ]
)
