// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GeminiChat",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/google/generative-ai-swift", from: "0.5.4"),
        .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0")
    ],
    targets: [
        .executableTarget(
            name: "GeminiChat",
            dependencies: [
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift"),
                "Splash"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
