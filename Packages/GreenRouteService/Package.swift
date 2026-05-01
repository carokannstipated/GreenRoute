// swift-tools-version: 6.2
// GreenRouteService: service layer providing location monitoring, inactivity detection,
// green area lookup, route calculation, and notification scheduling.

import PackageDescription

let package = Package(
    name: "GreenRouteService",
    platforms: [
        .iOS(.v26),
        .macOS(.v15)
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
