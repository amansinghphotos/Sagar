import Foundation
import Testing

/// Asks the real rules script, in this real package, which test targets a change to these files can reach: those
/// the tests before a commit run on this Mac. GitHub's Mac runs every one of them, whatever this says.
private func reached(_ files: [String]) throws -> String {
    let root = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL
    let process = Process()
    let answer = Pipe()
    process.executableURL = root.appending(path: "Scripts/check")
    process.arguments = ["reached"] + files
    process.currentDirectoryURL = root
    process.environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

@Test(arguments: [
    (["Sources/CheteKit/Clips.swift"], "CheteKitTests"),
    (["Sources/Look/Tokens.swift"], "CheteKitTests|GalleryTests|LookTests"),
    (["Sources/Shell/Updates.swift"], "CheteKitTests|ShellTests"),
    (["Sources/Keep/Keep.swift"], "CheteKitTests|KeepTests|ScriptsTests"),
    (["Sources/Gallery/Main.swift"], "GalleryTests"),
    (["Tests/KeepTests/StoreTests.swift"], "KeepTests"),
    (["Tests/Pictures/Pictures.swift"], "CheteKitTests|GalleryTests|LookTests|PicturesTests"),
    (["Tests/LookTests/Pictures/button.png"], "LookTests|PicturesTests"),
    (["Scripts/check", ".claude/hooks/start", "Tests/ScriptsTests/Fixtures/a.json"], "ScriptsTests"),
    (["Apps/Chete/Tour.swift"], ""),
])
func aChangeReachesTheTestsThatDependOnIt(files: [String], tests: String) throws {
    #expect(try reached(files) == tests + "\n")
}

/// Anything the package's own dependencies do not account for reaches every test.
@Test(arguments: [
    ["Package.swift"], ["Package.resolved"], ["Config/Info.plist"], ["CONSTRAINTS.md"], [".swift-format"],
    ["Sources/CheteKit/Clips.swift", "docs/New Mac.md"], ["Sources/Taps/Taps.swift"],
    ["Tests/UpdateTour/UpdateTour.swift"], ["NOW"],
])
func anythingElseReachesEveryTest(files: [String]) throws {
    #expect(try reached(files) == "all\n")
}
