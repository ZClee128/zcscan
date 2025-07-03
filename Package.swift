// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "zcscan",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "zcscan",
            targets: ["zcscan"]
        ),
    ],
    targets: [
        .target(
            name: "zcscan",
            path: "zcscan/Classes",
            resources: [
                .process("../Assets")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
) 