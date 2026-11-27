import Foundation
import Testing

/// Asks the real release script how the update tour opens an app made up in a temporary folder: from its
/// item in the menu bar if the app keeps out of the Dock, as Chete does, else from its own menu.
private func opens(keepingOutOfTheDock: Bool?) throws -> String {
    let app = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString)/Made Up.app")
    let contents = app.appending(path: "Contents")
    try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: app.deletingLastPathComponent()) }
    var info: [String: Any] = ["CFBundleIdentifier": "app.made.up"]
    if let keepingOutOfTheDock { info["LSUIElement"] = keepingOutOfTheDock }
    try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        .write(to: contents.appending(path: "Info.plist"))

    let process = Process()
    let answer = Pipe()
    process.executableURL = URL(filePath: #filePath).appending(path: "../../../Scripts/release").standardizedFileURL
    process.arguments = ["opens", app.path]
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

@Test func anAppOutOfTheDockOpensFromItsItem() throws {
    #expect(try opens(keepingOutOfTheDock: true) == "item\n")
}

@Test func anAppInTheDockOpensFromItsMenu() throws {
    #expect(try opens(keepingOutOfTheDock: nil) == "menu\n")
    #expect(try opens(keepingOutOfTheDock: false) == "menu\n")
}
