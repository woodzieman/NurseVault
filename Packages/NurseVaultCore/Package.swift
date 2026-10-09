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
        .target(
            name: "NurseVaultCore",
            resources: [
                // Compact, watch-sized drug index (name + brand names + the
                // auto-generated nursing quick-reference summary) generated
                // from the iOS app's full DrugInfo dataset. Loaded on every
                // platform but only surfaced in the watch app's UI. See the
                // handoff: the full 352 MB prescribing text cannot ship on
                // the watch, but this ~3 MB summary can.
                // C5 test: pipe-delimited text file, 29% smaller than JSON
                .copy("Resources/WatchDrugIndex.txt"),
                // Compact watch index for Merck Manual topics (title, specialty, short summary)
                // Keeps watch search fast without bundling the full 2,834 text files.
                // Compressed pipe-delimited text, zlib decompressed at runtime
                .copy("Resources/WatchMerckIndex.txt.zlib"),
            ]
        )
    ]
)
