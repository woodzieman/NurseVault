// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NurseVaultCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "NurseVaultCore", targets: ["NurseVaultCore"])
    ],
    targets: [
        .target(name: "NurseVaultCore")
    ]
)
