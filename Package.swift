// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnalyticsLive",
    platforms: [
        .macOS("10.15"),
        .iOS("13.0"),
        .tvOS("12.0"),
        .watchOS("7.1")
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AnalyticsLive",
            targets: ["AnalyticsLive"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/segmentio/analytics-swift.git", from: "1.4.7"),
        .package(url: "https://github.com/segmentio/substrata-swift.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AnalyticsLive",
            dependencies: [
                .product(name: "Segment", package: "analytics-swift"),
                .product(name: "Substrata", package: "substrata-swift")
            ]),
        .testTarget(
            name: "AnalyticsLiveTests",
            dependencies: ["AnalyticsLive"],
            resources: [
                .copy("TestHelpers/testbundle.js"),
                .copy("TestHelpers/addliveplugin.js")
            ]),
    ]
)
