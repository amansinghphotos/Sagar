import Foundation
import Testing

private let here = URL(filePath: #filePath).deletingLastPathComponent()

/// What the real rules script's order rule says, alone, of a package file and a line budget, in a small folder.
private func order(package: String, budget: String) throws -> String {
    let folder = FileManager.default.temporaryDirectory.appending(path: "order-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
    try FileManager.default.copyItem(
        at: here.appending(path: "../../Scripts/check").standardizedFileURL,
        to: folder.appending(path: "Scripts/check"))
    try Data(package.utf8).write(to: folder.appending(path: "Package.swift"))
    try Data(budget.utf8).write(to: folder.appending(path: "CONSTRAINTS.md"))
    try Data("Chete\n".utf8).write(to: folder.appending(path: "NOW"))
    // A real repository with main as GitHub has it: on GitHub's Mac the script judges nothing without one.
    try run("/usr/bin/env", ["git", "init", "-q", "-b", "main"], in: folder)
    try run("/usr/bin/env", ["git", "add", "-A"], in: folder)
    try run(
        "/usr/bin/env",
        [
            "git", "-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m",
            "Lists",
        ],
        in: folder)
    try run("/usr/bin/env", ["git", "update-ref", "refs/remotes/origin/main", "HEAD"], in: folder)
    return try run(folder.appending(path: "Scripts/check").path, ["order"], in: folder)
}

@discardableResult private func run(_ tool: String, _ arguments: [String], in folder: URL) throws -> String {
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

private func package(_ targets: String) -> String {
    """
    let package = Package(
        name: "Sagar",
        products: [.library(name: "CheteKit", targets: ["CheteKit"])],
        targets: [
    \(targets)
        ],
        swiftLanguageModes: [.v6]
    )

    """
}

private let inOrder = package(
    """
            .target(name: "CheteKit", dependencies: ["Keep"]),
            .testTarget(name: "CheteKitTests", dependencies: ["CheteKit"]),

            .target(name: "Keep"),
            .testTarget(
                name: "KeepTests", dependencies: ["Keep"], exclude: ["Fixtures"]),

            // A comment between parts is kept with the part below it.
            .target(name: "Look"),
    """)

private func budget(_ rows: String) -> String {
    """
    ## Line Budget

    | Module | Lines at most |
    |---|--:|
    | Each app's Main.swift, which only starts its Kit | 30 |
    \(rows)

    ## Every Pull Request

    | Rule | Number | Held by |
    |---|--:|---|
    | Changed lines, added plus deleted | 400 | `Scripts/check` size |

    """
}

private let rowsInOrder = budget("| CheteKit | 1500 |\n| Keep | 300 |\n| Look | 6000 |")

@Test func listsInAlphabeticalOrderPass() throws {
    #expect(try order(package: inOrder, budget: rowsInOrder).hasPrefix("ok    order"))
}

/// A part added at the end of the list, as every piece of work did before, clashes with the next one to do so.
@Test func aPartAddedAtTheEndOfThePackageFileFails() throws {
    let added = inOrder.replacingOccurrences(
        of: "        .target(name: \"Look\"),\n",
        with: "        .target(name: \"Look\"),\n\n        .target(name: \"Gallery\"),\n")
    let said = try order(package: added, budget: rowsInOrder)
    #expect(said.hasPrefix("FAIL  order"))
    #expect(said.contains("Package.swift"))
}

/// Two changes either side of one blank line merge cleanly; with none between them, they clash.
@Test func twoPartsWithNoBlankLineBetweenThemFail() throws {
    let joined = inOrder.replacingOccurrences(
        of: "\n\n        .target(name: \"Keep\")", with: "\n        .target(name: \"Keep\")")
    let said = try order(package: joined, budget: rowsInOrder)
    #expect(said.hasPrefix("FAIL  order"))
    #expect(said.contains("blank line"))
}

@Test func aRowAddedAtTheEndOfTheLineBudgetFails() throws {
    let said = try order(package: inOrder, budget: budget("| Keep | 300 |\n| Look | 6000 |\n| CheteKit | 1500 |"))
    #expect(said.hasPrefix("FAIL  order"))
    #expect(said.contains("CONSTRAINTS.md"))
}

@Test func theRepositorysOwnListsAreInOrder() throws {
    let root = here.appending(path: "../..").standardizedFileURL
    let said = try order(
        package: String(decoding: try Data(contentsOf: root.appending(path: "Package.swift")), as: UTF8.self),
        budget: String(decoding: try Data(contentsOf: root.appending(path: "CONSTRAINTS.md")), as: UTF8.self))
    #expect(said.hasPrefix("ok    order"))
}
