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
            targets: [
                "AnalyticsLive", "AnalyticsLiveCore", "Segment", "JSONSafeEncoding", "Sovran", "Substrata", "SubstrataQuickJS"
            ]
        ),
    ],
    targets: [
        .target(
            name: "AnalyticsLive"
        ),
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
        ),
        .binaryTarget(
            name: "JSONSafeEncoding",
            path: "xcframeworks/JSONSafeEncoding.xcframework"
        ),
        .binaryTarget(
            name: "Sovran",
            path: "xcframeworks/Sovran.xcframework"
        ),
        .binaryTarget(
            name: "Segment",
            path: "xcframeworks/Segment.xcframework"
        ),
        .testTarget(
            name: "AnalyticsLiveTests",
            dependencies: [
                "AnalyticsLive",
                "Segment",
            ],
            resources: [
                //.copy("TestHelpers/filterSettings.json"),
                //.copy("TestHelpers/testbundle.js"),
                //.copy("TestHelpers/addliveplugin.js"),
                //.copy("TestHelpers/MyEdgeFunctions.js"),
            ]
        ),
    ]
)
