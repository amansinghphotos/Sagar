import Foundation
import Look
import Shell
import Testing

@testable import CheteKit

/// The shortcut chosen is held by its keys' places, as macOS numbers them on a US keyboard.
@Test func aShortcutIsHeldByItsKeysPlaces() {
    #expect(KeyCombo("c", command: true, shift: true).held == HotKey.Keys(key: 8, command: true, shift: true))
    #expect(KeyCombo("v", command: true, option: true).held == HotKey.Keys(key: 9, command: true, option: true))
    #expect(KeyCombo("space", command: false, control: true).held == HotKey.Keys(key: 49, control: true))
    #expect(KeyCombo("1", command: true).held == HotKey.Keys(key: 18, command: true))
    #expect(KeyCombo("left").held == nil)
}

/// Chete starts with Shift-Command-C, which the earlier Chete used, and keeps the one you choose.
@Test func theShortcutIsKeptWithTheSettings() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    #expect(try Settings.read(in: folder).shortcut == KeyCombo("c", command: true, shift: true))
    var settings = Settings()
    settings.shortcut = KeyCombo("v", command: true, option: true)
    try settings.write(in: folder)
    #expect(try Settings.read(in: folder).shortcut == KeyCombo("v", command: true, option: true))
}
