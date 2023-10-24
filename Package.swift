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
//        .library(
//            name: "LAME",
//            targets: ["LAME"]
//        ),
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
                .unsafeFlags(["-w"])
            ]
        ),
        
        // Tests
        
        .testTarget(
            name: "SwiftLAMETests",
            dependencies: ["SwiftLAME"]
        )
    ]
)
