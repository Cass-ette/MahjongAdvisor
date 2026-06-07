// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MahjongOCR",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MahjongOCR", targets: ["MahjongOCR"]),
    ],
    dependencies: [
        .package(path: "../MahjongCore"),
    ],
    targets: [
        .target(
            name: "MahjongOCR",
            dependencies: ["MahjongCore"]
        ),
        .testTarget(
            name: "MahjongOCRTests",
            dependencies: ["MahjongOCR"]
        ),
    ]
)
