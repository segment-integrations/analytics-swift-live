// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnalyticsLive",
    platforms: [
        .macOS("10.15"),
        .iOS("13.0"),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AnalyticsLive",
            targets: ["AnalyticsLive", "AnalyticsLiveCore", "Substrata", "SubstrataQuickJS"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/segmentio/analytics-swift.git", from: "1.6.0")
    ],
    targets: [
        .target(
            name: "AnalyticsLive",
            dependencies: [
                .product(name: "Segment", package: "analytics-swift"),
            ]),
        .binaryTarget(
            name: "AnalyticsLiveCore",
            path: "xcframeworks/AnalyticsLiveCore.xcframework"
        ),
        .binaryTarget(
            name: "Substrata",
            path: "xcframeworks/Substrata.xcframework"
        ),
        .binaryTarget(
            name: "SubstrataQuickJS",
            path: "xcframeworks/SubstrataQuickJS.xcframework"
        )
    ]
)
