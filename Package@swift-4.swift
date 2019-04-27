// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CLImate",
    products: [
        .library(
            name: "CLImate",
            targets: ["CLImate"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ilyapuchka/common-parsers.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "CLImate",
            dependencies: ["CommonParsers"]),
        .testTarget(
            name: "CLImateTests",
            dependencies: ["CLImate"]),
    ]
)
