// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "UnquarantineCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "UnquarantineCore", targets: ["UnquarantineCore"])
    ],
    targets: [
        .target(name: "UnquarantineCore"),
        .testTarget(
            name: "UnquarantineCoreTests",
            dependencies: ["UnquarantineCore"]
        )
    ]
)
