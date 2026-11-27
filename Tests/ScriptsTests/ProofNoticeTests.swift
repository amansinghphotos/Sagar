import Foundation
import Testing

/// Gives the real release script a release pull request's comments, as GitHub lists them, and how the proof on
/// GitHub's Mac ended. Returns the note it would post there for the owner, which is nothing when he needs none.
private func notice(_ ended: String, after comments: Data) throws -> String {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let list = folder.appending(path: "comments.json")
    try comments.write(to: list)
    let process = Process()
    let answer = Pipe()
    process.executableURL = URL(filePath: #filePath).appending(path: "../../../Scripts/release").standardizedFileURL
    process.arguments = ["notice", "Chete", "1.1", ended, "the-owner", "Chete 1.0 did not take the update."]
    process.standardInput = try FileHandle(forReadingFrom: list)
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

/// The recorded comments of a real pull request. No release has shipped yet, so none of them is a note about a proof.
private func recorded() throws -> Data {
    let fixtures = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Fixtures")
    return try Data(contentsOf: fixtures.appending(path: "A Reply That Names Its Commit.json"))
}

/// The same list once GitHub also holds a note the script wrote: what the next run of the proof would be given.
private func adding(_ note: String, to comments: Data) throws -> Data {
    let list = try #require(try JSONSerialization.jsonObject(with: comments) as? [[String: Any]])
    return try JSONSerialization.data(withJSONObject: list + [["body": note]])
}

private nonisolated let failed = """
    @the-owner **Chete 1.1 failed its last check, after you approved it.**
    GitHub's Mac couldn't get it the way people will.
    Say "the Chete check failed" in any chat, and we'll mend it.

    <details><summary>For the Agents</summary>

    Chete 1.0 did not take the update.

    </details>
    <!-- proof failed -->

    """

private nonisolated let passed = """
    @the-owner **Chete 1.1 has now passed its last check.**
    A second try worked. There's nothing for you to do.
    <!-- proof passed -->

    """

@Test func aFailedProofIsSaidToTheOwnerInPlainWords() throws {
    #expect(try notice("failed", after: recorded()) == failed)
}

@Test func aProofThatFailsAgainIsNotSaidTwice() throws {
    #expect(try notice("failed", after: adding(failed, to: recorded())) == "")
}

@Test func aProofThatPassesFirstTimeSaysNothing() throws {
    #expect(try notice("passed", after: recorded()) == "")
}

@Test func aSecondTryThatPassesIsSaidOnce() throws {
    let told = try adding(failed, to: recorded())
    #expect(try notice("passed", after: told) == passed)
    #expect(try notice("passed", after: adding(passed, to: told)) == "")
}
