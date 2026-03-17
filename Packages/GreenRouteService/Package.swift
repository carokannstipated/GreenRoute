// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GreenRouteService",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "GreenRouteService",
            targets: ["GreenRouteService"]
        )
    ],
    dependencies: [
        .package(path: "../GreenRouteDomain")
    ],
    targets: [
        .target(
            name: "GreenRouteService",
            dependencies: [
                .product(name: "GreenRouteDomain", package: "GreenRouteDomain")
            ],
            path: "Sources/GreenRouteService"
        ),
        .testTarget(
            name: "GreenRouteServiceTests",
            dependencies: [
                "GreenRouteService",
                .product(name: "GreenRouteDomain", package: "GreenRouteDomain")
            ],
            path: "Tests/GreenRouteServiceTests"
        )
    ]
)
