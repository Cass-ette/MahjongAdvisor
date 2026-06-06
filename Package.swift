// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MahjongAdvisor",
    platforms: [.macOS(.v14)],
    products: [],
    dependencies: [
        .package(name: "MahjongCore", path: "MahjongCore"),
        .package(name: "MahjongOCR", path: "MahjongOCR"),
        .package(name: "MahjongAdvisorApp", path: "MahjongAdvisorApp"),
    ],
    targets: []
)
