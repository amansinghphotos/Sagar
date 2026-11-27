import Foundation
import Testing

/// A small real package that holds the real Keep and the real rules script, as GitHub has it on main.
private struct Phone {
    let folder = FileManager.default.temporaryDirectory.appending(path: "iphone-\(UUID().uuidString)")

    init() throws {
        let root = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL
        for part in ["Scripts/check", "Sources/Keep"] {
            try FileManager.default.createDirectory(
                at: folder.appending(path: part).deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: root.appending(path: part), to: folder.appending(path: part))
        }
        try write(
            """
            // swift-tools-version: 6.4
            import PackageDescription

            let package = Package(name: "Sagar", platforms: [.macOS(.v27)], targets: [.target(name: "Keep")])

            """, to: "Package.swift")
        try write("Chete\n", to: "NOW")
        try write(".build/\n", to: ".gitignore")
        try run("/usr/bin/env", ["git", "init", "-q", "-b", "main"])
        try run("/usr/bin/env", ["git", "add", "-A"])
        try run(
            "/usr/bin/env",
            ["git", "-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-qm", "Keep"])
        try run("/usr/bin/env", ["git", "update-ref", "refs/remotes/origin/main", "HEAD"])
    }

    func write(_ words: String, to name: String) throws {
        try Data(words.utf8).write(to: folder.appending(path: name))
    }

    /// What the iphone rule says, alone, of the modules named.
    func iphone(_ modules: String...) throws -> String {
        try run(folder.appending(path: "Scripts/check").path, ["iphone"] + modules)
    }

    @discardableResult private func run(_ tool: String, _ arguments: [String]) throws -> String {
        let process = Process()
        let answer = Pipe()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        process.currentDirectoryURL = folder
        process.environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        process.standardOutput = answer
        try process.run()
        process.waitUntilExit()
        return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    }
}

/// Keep builds for iPhone as it is. One line that only a Mac understands, which no rule that reads for a
/// word would catch, stops it: Foundation gives the user's home folder on a Mac alone.
@Test func aLineOnlyAMacUnderstandsStopsAModuleBuildingForIPhone() throws {
    let phone = try Phone()
    defer { try? FileManager.default.removeItem(at: phone.folder) }
    #expect(try phone.iphone("Keep").hasPrefix("ok    iphone"))

    let keep = try String(contentsOf: phone.folder.appending(path: "Sources/Keep/Keep.swift"), encoding: .utf8)
    try phone.write(
        keep + "\nlet home = FileManager.default.homeDirectoryForCurrentUser\n", to: "Sources/Keep/Keep.swift")
    let said = try phone.iphone("Keep")
    #expect(said.hasPrefix("FAIL  iphone"))
    #expect(said.contains("unavailable in iOS"))
}

/// A name that is no module here must fail, never pass by building nothing.
@Test func aModuleThatIsNotThereFails() throws {
    let phone = try Phone()
    defer { try? FileManager.default.removeItem(at: phone.folder) }
    let said = try phone.iphone("Look")
    #expect(said.hasPrefix("FAIL  iphone"))
    #expect(said.contains("Look"))
}
