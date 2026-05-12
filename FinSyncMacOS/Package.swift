// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FinSyncMacOS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "FinSyncCore", targets: ["FinSyncCore"]),
        .executable(name: "FinSyncMacOSApp", targets: ["FinSyncMacOSApp"]),
        .executable(name: "FinSyncValidation", targets: ["FinSyncValidation"])
    ],
    targets: [
        .target(
            name: "FinSyncCore",
            path: "FinSyncMacOS",
            exclude: ["Resources"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .executableTarget(
            name: "FinSyncMacOSApp",
            dependencies: ["FinSyncCore"],
            path: "FinSyncMacOSAppRunner"
        ),
        .executableTarget(
            name: "FinSyncValidation",
            dependencies: ["FinSyncCore"],
            path: "FinSyncValidation"
        )
    ]
)
