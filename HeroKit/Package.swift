// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HeroKit",
    platforms: [.watchOS(.v10)],
    products: [
        .library(name: "HeroKit", targets: ["HeroKit"]),
    ],
    targets: [
        .target(
            name: "HeroKit",
            path: "Sources/HeroKit"
        ),
        .testTarget(
            name: "HeroKitTests",
            dependencies: ["HeroKit"],
            path: "Tests/HeroKitTests"
        ),
    ]
)
