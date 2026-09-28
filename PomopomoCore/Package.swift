// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pomopomo",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PomopomoCore", targets: ["PomopomoCore"]),
    ],
    targets: [
        .target(name: "PomopomoCore"),
        .testTarget(name: "PomopomoCoreTests", dependencies: ["PomopomoCore"]),
    ]
)
