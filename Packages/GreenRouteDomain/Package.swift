// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GreenRouteDomain",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "GreenRouteDomain",
            targets: ["GreenRouteDomain"]
        ),
    ],
    targets: [
        .target(
            name: "GreenRouteDomain"
        ),
        .testTarget(
            name: "GreenRouteDomainTests",
            dependencies: ["GreenRouteDomain"]
        ),
    ]
)
