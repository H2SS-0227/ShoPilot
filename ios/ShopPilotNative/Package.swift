// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ShopPilotNative",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "ShopPilotCore", targets: ["ShopPilotCore"]),
        .executable(name: "ShopPilotNativeApp", targets: ["ShopPilotNativeApp"])
    ],
    targets: [
        .target(name: "ShopPilotCore"),
        .executableTarget(
            name: "ShopPilotNativeApp",
            dependencies: ["ShopPilotCore"]
        ),
        .testTarget(
            name: "ShopPilotCoreTests",
            dependencies: ["ShopPilotCore"]
        )
    ]
)
