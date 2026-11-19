// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FullIslandCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "FullIslandCore", targets: ["FullIslandCore"])
    ],
    targets: [
        .target(name: "FullIslandCore"),
        .testTarget(name: "FullIslandCoreTests", dependencies: ["FullIslandCore"])
    ]
)
