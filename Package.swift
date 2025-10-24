// swift-tools-version: 5.9
// Package.swift - SPM Dependencies für StarTune

import PackageDescription

let package = Package(
    name: "StarTune",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "StarTune",
            targets: ["StarTune"]
        )
    ],
    dependencies: [
        // MusadoraKit - MusicKit Companion Library
        .package(
            url: "https://github.com/rryam/MusadoraKit",
            from: "4.0.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "StarTune",
            dependencies: [
                "MusadoraKit"
            ]
        )
    ]
)
