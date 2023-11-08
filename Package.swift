// swift-tools-version: 5.9

import PackageDescription


let package = Package(
    name: "SwiftLAME",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "SwiftLAME",
            targets: [
                "SwiftLAME"
            ]
        )
    ],
    targets: [
        
        // Targets
        
        .target(
            name: "SwiftLAME",
            dependencies: ["LAME"]
        ),
        .target(
            name: "LAME",
            publicHeadersPath: "include",
            cSettings: [
                .define("HAVE_CONFIG_H"),
                .unsafeFlags(["-w", "-Xanalyzer", "-analyzer-disable-all-checks"])
            ]
        ),
        
        // Tests
        
        .testTarget(
            name: "SwiftLAMETests",
            dependencies: ["SwiftLAME"]
        )
    ]
)
