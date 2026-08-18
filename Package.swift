// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BeeAutomata",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "BeeAutomata",
            path: "BeeAutomata",
            exclude: ["Info.plist"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
    ]
)
