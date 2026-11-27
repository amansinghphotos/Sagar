import Foundation
import Testing

/// Asks the real rules script whether a change to these files needs the apps built on the Mac that wrote it.
/// GitHub's Mac builds every app for every change to the code, so here it is only worth it for what nothing
/// else on this Mac compiles.
private func appsAreBuiltHere(_ files: [String]) throws -> Bool {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    let process = Process()
    let answer = Pipe()
    process.executableURL = script
    process.arguments = ["apps"] + files
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self) == "yes\n"
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
