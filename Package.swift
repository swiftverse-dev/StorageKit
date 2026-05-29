// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StorageKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "StorageKit", targets: ["StorageKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.0.0"),
    ],
    targets: [
        .target(name: "StorageKit"),
        .testTarget(
            name: "StorageKitTests",
            dependencies: [
                "StorageKit",
                .product(name: "Clocks", package: "swift-clocks"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
