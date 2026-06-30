// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RazerShaper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RazerShaperCore",
            targets: ["RazerShaperCore"]
        ),
        .executable(
            name: "RazerShaperProbe",
            targets: ["RazerShaperProbe"]
        ),
        .executable(
            name: "RazerShaperApp",
            targets: ["RazerShaperApp"]
        )
    ],
    targets: [
        .target(
            name: "RazerShaperCore",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "RazerShaperProbe",
            dependencies: ["RazerShaperCore"]
        ),
        .executableTarget(
            name: "RazerShaperApp",
            dependencies: ["RazerShaperCore"],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        .testTarget(
            name: "RazerShaperCoreTests",
            dependencies: ["RazerShaperCore"]
        )
    ]
)
