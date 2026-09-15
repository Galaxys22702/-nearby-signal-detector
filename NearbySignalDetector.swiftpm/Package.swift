// swift-tools-version: 6.0

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Nearby Signal Detector",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Nearby Signal Detector",
            targets: ["AppModule"],
            bundleIdentifier: "com.robtheproducer.nearbysignaldetector",
            displayVersion: "0.3.0",
            bundleVersion: "3",
            appIcon: .placeholder(icon: .lightningBolt),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .phone,
                .pad
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            additionalInfoPlistContentFilePath: "AdditionalInfo.plist"
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            exclude: [
                "Package.swift",
                "AdditionalInfo.plist",
                "project.yml",
                "Build",
                "README.md"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
