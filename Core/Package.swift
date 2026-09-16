// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TidelineCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "TidelineCore", targets: ["TidelineCore"])
    ],
    targets: [
        .target(name: "TidelineCore"),
        .testTarget(name: "TidelineCoreTests", dependencies: ["TidelineCore"])
    ]
)
