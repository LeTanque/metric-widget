// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MetricsWidget",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MetricsWidget", targets: ["MetricsWidget"])
    ],
    targets: [
        .executableTarget(
            name: "MetricsWidget",
            path: "MetricsWidget",
            exclude: [
                "Info.plist",
                "MetricsWidget.entitlements",
                "Assets.xcassets"
            ],
            resources: [
                .copy("Resources/Fonts/PressStart2P-Regular.ttf"),
                .copy("Resources/Fonts/OFL.txt"),
                .copy("Resources/Graffiti/chinox-2016.jpg")
            ]
        )
    ]
)
