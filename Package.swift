// swift-tools-version: 6.4
import PackageDescription

/// Every module in Sagar and its tests. A module is added when the first app needs it,
/// together with its line budget in CONSTRAINTS.md.
/// Every target is held to no warnings. Screens and their tests run on the main actor unless they say
/// otherwise; Keep does not, because files have no business there.
let noWarnings: [SwiftSetting] = [.treatAllWarnings(as: .error)]
let strict: [SwiftSetting] = noWarnings + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "Sagar",
    platforms: [.macOS(.v27)],
    // Each app's Kit, which its thin target in Sagar.xcodeproj links.
    products: [.library(name: "CheteKit", targets: ["CheteKit"])],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.1")
    ],
    targets: [
        .target(name: "Keep", swiftSettings: noWarnings),
        .testTarget(name: "KeepTests", dependencies: ["Keep"], swiftSettings: strict),
        .target(name: "Shell", dependencies: [.product(name: "Sparkle", package: "Sparkle")], swiftSettings: strict),
        .testTarget(name: "ShellTests", dependencies: ["Shell"], swiftSettings: strict),
        .target(name: "CheteKit", dependencies: ["Shell"], swiftSettings: strict),
        .target(name: "Look", swiftSettings: strict),
        .testTarget(name: "LookTests", dependencies: ["Look"], swiftSettings: strict),
        // Every part of the look on its own pages, where the agents test it against Search. Never shipped.
        .executableTarget(name: "Gallery", dependencies: ["Look"], swiftSettings: strict),
        .testTarget(
            name: "GalleryTests", dependencies: ["Gallery", "Look", "Pictures"], exclude: ["Pictures"],
            swiftSettings: strict),
        .testTarget(name: "ScriptsTests", exclude: ["Fixtures"], swiftSettings: strict),
        // Test support: pictures a screen from a window that is never shown.
        .target(name: "Pictures", path: "Tests/Pictures", swiftSettings: strict),
        .testTarget(name: "PicturesTests", dependencies: ["Pictures"], exclude: ["Pictures"], swiftSettings: strict),
    ],
    swiftLanguageModes: [.v6]
)
