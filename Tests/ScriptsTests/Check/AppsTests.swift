import Foundation
import Testing

/// Asks the real rules script whether a change to these files needs the apps built on the Mac that wrote it.
/// GitHub's Mac builds every app for every change to the code, so here it is only worth it for what nothing
/// else on this Mac compiles.
private func appsAreBuiltHere(_ files: [String]) throws -> Bool {
    try Script.run(Script.check, ["apps"] + files).words == "yes\n"
}

@Test(arguments: [
    ["Apps/Chete/Main.swift"], ["Apps/Chete/Tour.swift", "Sources/CheteKit/Clips.swift"], ["Config/Shared.xcconfig"],
    ["Sagar.xcodeproj/project.xcproj"], ["Package.swift"],
])
func whatOnlyTheAppBuildCoversIsBuiltHere(files: [String]) throws {
    #expect(try appsAreBuiltHere(files))
}

@Test(arguments: [
    ["Sources/CheteKit/Clips.swift"], ["Tests/KeepTests/StoreTests.swift"], ["Scripts/check"], ["README.md"],
    ["Sources/Look/Tokens.swift", "Tests/LookTests/Pictures/button.png"],
])
func whatTheTestsAlreadyCompileIsLeftToGitHub(files: [String]) throws {
    #expect(try !appsAreBuiltHere(files))
}
