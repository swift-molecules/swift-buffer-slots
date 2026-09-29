// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-buffer-slots",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(name: "Buffer Slots", targets: ["Buffer Slots"]),
        .library(
            name: "Buffer Slots Test Support",
            targets: ["Buffer Slots Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-store.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-buffer.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-atoms/swift-storage.git",
            branch: "main", traits: ["Generational", "Memory"]),
        .package(
            url: "https://github.com/swift-molecules/swift-memory-allocation.git",
            branch: "main", traits: ["MemorySmall", "MemoryAllocatorArena", "MemoryInline"]),
        .package(
            url: "https://github.com/swift-atoms/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-affine.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-ordinal.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-memory.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-cardinal.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-tagged.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-atoms/swift-carrier.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-property.git", branch: "main"),
    ],
    targets: [

        .target(
            name: "Buffer Slots",
            dependencies: [
                .product(name: "Buffer", package: "swift-buffer"),
                .product(name: "Store", package: "swift-store"),
                .product(name: "Storage", package: "swift-storage"),
                .product(
                    name: "Memory Allocator",
                    package: "swift-memory-allocation"
                ),
                .product(
                    name: "Memory Allocator Protocol",
                    package: "swift-memory-allocation"
                ),
                .product(name: "Index", package: "swift-index"),
                .product(name: "Memory", package: "swift-memory"),
                .product(name: "Affine", package: "swift-affine"),
                .product(
                    name: "Affine",
                    package: "swift-affine"
                ),
                .product(name: "Ordinal", package: "swift-ordinal"),
                .product(
                    name: "Ordinal",
                    package: "swift-ordinal"
                ),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Carrier", package: "swift-carrier"),
                .product(name: "Property", package: "swift-property"),
                .product(name: "Memory Small", package: "swift-memory-allocation"),
            ]
        ),

        .target(
            name: "Buffer Slots Test Support",
            dependencies: [
                "Buffer Slots",
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Buffer Slots Tests",
            dependencies: [
                .product(name: "Store", package: "swift-store"),
                .product(name: "Ordinal", package: "swift-ordinal"),
                "Buffer Slots",
                "Buffer Slots Test Support",
                .product(name: "Buffer", package: "swift-buffer"),
                .product(name: "Storage", package: "swift-storage"),
                .product(
                    name: "Memory Allocator",
                    package: "swift-memory-allocation"
                ),
                .product(name: "Memory", package: "swift-memory"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Property", package: "swift-property"),
                .product(name: "Memory Small", package: "swift-memory-allocation"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("BuiltinModule"),
        .enableExperimentalFeature("RawLayout"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
