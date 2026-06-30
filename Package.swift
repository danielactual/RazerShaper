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
        )
    ],
    targets: [
        .target(
            name: "RazerShaperCore",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "RazerShaperProbe",
            dependencies: ["RazerShaperCore"]
        ),
        .testTarget(
            name: "RazerShaperCoreTests",
            dependencies: ["RazerShaperCore"]
        )
    ]
)
