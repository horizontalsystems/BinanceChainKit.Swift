// swift-tools-version:5.5

import PackageDescription

let package = Package(
        name: "BinanceChainKit",
        platforms: [
            .iOS(.v13),
        ],
        products: [
            .library(
                    name: "BinanceChainKit",
                    targets: ["BinanceChainKit"]
            ),
        ],
        dependencies: [
            .package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "6.0.0")),
            .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
            .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
            .package(url: "https://github.com/horizontalsystems/HdWalletKit.Swift.git", .upToNextMajor(from: "1.2.1")),
            .package(url: "https://github.com/horizontalsystems/HsCryptoKit.Swift.git", .upToNextMajor(from: "1.2.1")),
            .package(url: "https://github.com/horizontalsystems/HsExtensions.Swift.git", .upToNextMajor(from: "1.0.6")),
            .package(url: "https://github.com/horizontalsystems/HsToolKit.Swift.git", .upToNextMajor(from: "2.0.0")),
        ],
        targets: [
            .target(
                    name: "BinanceChainKit",
                    dependencies: [
                        .product(name: "GRDB", package: "GRDB.swift"),
                        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                        "SwiftyJSON",
                        .product(name: "HdWalletKit", package: "HdWalletKit.Swift"),
                        .product(name: "HsCryptoKit", package: "HsCryptoKit.Swift"),
                        .product(name: "HsExtensions", package: "HsExtensions.Swift"),
                        .product(name: "HsToolKit", package: "HsToolKit.Swift"),
                    ]
            )
        ]
)
