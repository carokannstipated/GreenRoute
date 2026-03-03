// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GreenRouteData",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "GreenRouteData", targets: ["GreenRouteData"])
    ],
    dependencies: [
        .package(path: "../GreenRouteDomain")
    ],
    targets: [
        .target(
            name: "GreenRouteData",
            dependencies: [
                .product(name: "GreenRouteDomain", package: "GreenRouteDomain")
            ]
        ),
        .testTarget(
            name: "GreenRouteDataTests",
            dependencies: [
                "GreenRouteData",
                .product(name: "GreenRouteDomain", package: "GreenRouteDomain")
            ]
        )
    ]
)
