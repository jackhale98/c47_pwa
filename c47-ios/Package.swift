// swift-tools-version:5.9
// SPDX-License-Identifier: GPL-3.0-only
// Package.swift for C47 Calculator iOS

import PackageDescription

let package = Package(
    name: "C47Calculator",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "C47Calculator",
            targets: ["C47Calculator"]
        ),
    ],
    dependencies: [],
    targets: [
        // Main C47 Calculator library
        .target(
            name: "C47Calculator",
            dependencies: ["C47Core"],
            path: "C47",
            exclude: [
                "Core",
                "Tests",
                "Resources/Info.plist"
            ],
            sources: [
                "App",
                "Bridge",
                "Models",
                "ViewModels",
                "Views"
            ],
            resources: [
                .process("Resources/Fonts"),
                .process("Resources/Assets.xcassets")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),

        // C47 Core engine (C library)
        .target(
            name: "C47Core",
            dependencies: [],
            path: "C47/Core",
            sources: [
                "source",
                "mathematics"
            ],
            publicHeadersPath: "headers",
            cSettings: [
                .headerSearchPath("headers"),
                .define("IOS_BUILD"),
                .unsafeFlags(["-w"]) // Suppress warnings from C code
            ]
        ),

        // C47 iOS Bridge (C library)
        .target(
            name: "C47Bridge",
            dependencies: [],
            path: "C47/Bridge",
            sources: ["c47-ios-bridge.c"],
            publicHeadersPath: ".",
            cSettings: [
                .define("IOS_BUILD")
            ]
        ),

        // Unit tests
        .testTarget(
            name: "C47CalculatorTests",
            dependencies: ["C47Calculator"],
            path: "C47/Tests",
            sources: [
                "C47EngineTests",
                "ViewModelTests"
            ]
        ),
    ]
)
