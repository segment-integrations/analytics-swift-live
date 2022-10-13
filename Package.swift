// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EdgeFn",
    platforms: [
        .macOS("10.15"),
        .iOS("13.0"),
        .tvOS("11.0"),
        .watchOS("7.1")
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "EdgeFn",
            targets: ["EdgeFn"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            name: "Segment",
            url: "git@github.com:segmentio/analytics-swift.git",
            from: "1.3.1"
        ),
        .package(name: "Substrata",
                 url: "git@github.com:segmentio/substrata-swift.git",
                 .upToNextMajor(from: "0.0.2")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "EdgeFn",
            dependencies: ["Segment", "Substrata"]),
        .testTarget(
            name: "EdgeFnTests",
            dependencies: ["EdgeFn"],
            resources: [
                .copy("TestHelpers/testbundle.js")
            ]),
    ]
)
