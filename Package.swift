// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Punaise",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Punaise", targets: ["Punaise"])
    ],
    targets: [
        .executableTarget(
            name: "Punaise",
            path: ".",
            exclude: [
                ".codex",
                ".git",
                ".build",
                "dist",
                "landing",
                "landing-assets",
                "script",
                "README.md",
                "LICENSE",
                "ChatGPT Image 14 mai 2026, 07_49_11 (1).png",
                "ChatGPT Image 14 mai 2026, 07_49_11 (2).png"
            ],
            sources: [
                "App",
                "Models",
                "Stores",
                "Services",
                "Views",
                "Support"
            ],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
