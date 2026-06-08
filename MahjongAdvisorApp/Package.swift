// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MahjongAdvisorApp",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MahjongAdvisorApp", targets: ["MahjongAdvisorApp"]),
    ],
    dependencies: [
        .package(name: "MahjongCore", path: "../MahjongCore"),
        .package(name: "MahjongOCR", path: "../MahjongOCR"),
    ],
    targets: [
        .executableTarget(
            name: "MahjongAdvisorApp",
            dependencies: [
                .product(name: "MahjongCore", package: "MahjongCore"),
                .product(name: "MahjongOCR", package: "MahjongOCR"),
            ],
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "MahjongAdvisorAppTests",
            dependencies: ["MahjongAdvisorApp"]
        ),
    ]
)
