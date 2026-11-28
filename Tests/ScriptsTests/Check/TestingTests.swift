import Foundation
import Testing

/// A small real package holding the real rules script and one test target whose test fails, then prints 60 lines,
/// as a long test run does after its failures: the last lines alone would not say which test failed.
@Test func aFailingTestIsNamedWithItsMessage() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: "named-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: folder) }
    func write(_ words: String, to name: String) throws {
        let url = folder.appending(path: name)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(words.utf8).write(to: url)
    }
    try FileManager.default.createDirectory(at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
    try FileManager.default.copyItem(at: Script.check, to: folder.appending(path: "Scripts/check"))
    try write(
        """
        // swift-tools-version: 6.4
        import PackageDescription

        let package = Package(
            name: "Broken", platforms: [.macOS(.v27)], targets: [.testTarget(name: "BrokenTests")])

        """, to: "Package.swift")
    try write(
        """
        import Testing

        @Test func theSumIsWrong() {
            #expect(1 + 1 == 3, "one and one")
            for line in 1...60 { print("line \\(line)") }
        }

        """, to: "Tests/BrokenTests/Broken.swift")
    try write("Chete\n", to: "NOW")
    let environment = Script.withoutGit.filter { $0.key != "CI" }
    let said = try Script.run(folder.appending(path: "Scripts/check"), in: folder, environment: environment).words
    let tests = try #require(said.components(separatedBy: "FAIL  tests").last)
    #expect(tests.contains("theSumIsWrong()"))
    #expect(tests.contains("one and one"))
}
