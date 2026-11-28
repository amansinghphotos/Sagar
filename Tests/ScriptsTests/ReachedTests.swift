import Foundation
import Testing

/// Asks the real rules script, in this real package, what a change to these files can reach: the tests, builds and
/// tours that run for it, before a commit here and, with `ci`, on GitHub.
private func reached(_ files: [String], asking command: String = "reached", ci: Bool = false) throws -> String {
    let root = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL
    let process = Process()
    let answer = Pipe()
    process.executableURL = root.appending(path: "Scripts/check")
    process.arguments = [command] + files
    process.currentDirectoryURL = root
    var environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") && $0.key != "CI" }
    if ci { environment["CI"] = "true" }
    process.environment = environment
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

/// On GitHub, as before a commit, a pull request builds and tours an app only when it reaches the app's own files or
/// a module its Kit uses, and builds for iPhone only when it reaches a module that builds there.
@Test(arguments: [
    (["Sources/CheteKit/Clips.swift"], "tests CheteKitTests\napp Chete"),
    (["Sources/Keep/Keep.swift"], "tests CheteKitTests|KeepTests|ScriptsTests\napp Chete\niphone"),
    (["Sources/Look/Tokens.swift"], "tests CheteKitTests|GalleryTests|LookTests\napp Chete"),
    (["Sources/Gallery/Main.swift"], "tests GalleryTests"),
    (["Tests/KeepTests/StoreTests.swift"], "tests KeepTests"),
    (["Tests/LookTests/Pictures/button.png"], "tests LookTests|PicturesTests"),
    (["Apps/Chete/Tour.swift"], "tests \napp Chete"),
])
func aPullRequestBuildsAndToursOnlyWhatItReaches(files: [String], reaches: String) throws {
    #expect(try reached(files, asking: "reaches", ci: true) == reaches + "\n")
}

/// The scripts and hooks are the rules themselves: on GitHub a change to them runs everything, though before a commit
/// only ScriptsTests reads them.
@Test func aChangeToTheRulesReachesEverythingOnGitHub() throws {
    #expect(try reached(["Scripts/check"], ci: true) == "all\n")
    #expect(try reached([".claude/hooks/start"], asking: "reaches", ci: true) == "all\n")
    #expect(try reached(["Tests/ScriptsTests/SizeTests.swift"], asking: "reaches", ci: true) == "all\n")
    #expect(try reached(["Tests/Pictures/Pictures.swift"], asking: "reaches", ci: true) == "all\n")
    #expect(try reached(["Scripts/check"]) == "ScriptsTests\n")
}
