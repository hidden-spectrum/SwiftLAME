// swift-tools-version: 5.7

import PackageDescription


let package = Package(
    name: "SwiftMP3",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "SwiftLAME",
            targets: ["SwiftLAME"]
        ),
        .library(
            name: "LAME",
            targets: ["LAME"]
        ),
    ],
    targets: [
        
        // Targets
        
        .target(
            name: "LAME",
            publicHeadersPath: "include",
            cSettings: [
                .define("HAVE_CONFIG_H")
            ]
        ),
        
        .target(
            name: "SwiftLAME",
            dependencies: ["LAME"]
        ),
        
        // Tests
        
        .testTarget(
            name: "SwiftLAMETests",
            dependencies: ["SwiftLAME"]
        )
    ]
)
