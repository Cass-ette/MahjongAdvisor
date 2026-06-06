// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MahjongCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MahjongCore", targets: ["MahjongCore"]),
    ],
    targets: [
        .target(name: "MahjongCore"),
        .testTarget(name: "MahjongCoreTests", dependencies: ["MahjongCore"]),
    ]
)
