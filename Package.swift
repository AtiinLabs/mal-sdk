// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "mal",
    platforms: [
        .macOS(.v12), .iOS(.v15)
    ],
    products: [
        .library(
            name: "mal",
            targets: ["mal"]
        ),
    ],
    targets: [
        .target(
            name: "mal"
        ),
        .testTarget(
            name: "malTests",
            dependencies: ["mal"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
