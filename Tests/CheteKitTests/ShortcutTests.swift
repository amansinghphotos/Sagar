import Foundation
import Keep
import Look
import Testing

@testable import CheteKit

/// Keys no person presses: every modifier with F11 or F12. A test holds them for a moment and lets them go.
private let one = KeyCombo("f11", command: true, shift: true, option: true, control: true)
private let other = KeyCombo("f12", command: true, shift: true, option: true, control: true)

@Test func aChangedShortcutIsHeldAndTheOldOneLetGo() {
    let shortcut = Shortcut()
    defer { _ = shortcut.change(to: nil) }
    #expect(shortcut.change(to: one) == nil)
    #expect(Shortcut().warning(for: one) == "Chete already uses these keys.")
    #expect(shortcut.change(to: other) == nil)
    #expect(Shortcut().warning(for: one) == nil)
    #expect(Shortcut().warning(for: other) == "Chete already uses these keys.")
    #expect(shortcut.warning(for: other) == nil, "The keys it holds are not a clash with itself.")
}

@Test func aChangedShortcutIsKept() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    #expect(try Settings.read(in: folder).shortcut == KeyCombo("c", shift: true))
    var settings = try Settings.read(in: folder)
    settings.shortcut = other
    try settings.write(in: folder)
    #expect(try Settings.read(in: folder).shortcut == other)
    settings.shortcut = nil
    try settings.write(in: folder)
    #expect(try Settings.read(in: folder).shortcut == nil, "No shortcut, once chosen, is kept.")
}

@Test func keysWithoutCommandOrControlAreRefusedInWords() {
    #expect(
        Shortcut().warning(for: KeyCombo("c", command: false, option: true)) == "Add ⌘ or ⌃, so typing still works.")
    #expect(Shortcut.words(.macOSHasIt) == "Your Mac already uses these keys.")
    #expect(Shortcut.words(.macOSRefused(-9878)) == "Your Mac won’t let Chete use these keys.")
}

@Test func aKeyChetesTableLacksIsRefusedRatherThanTakenForAnother() {
    let shortcut = Shortcut()
    defer { _ = shortcut.change(to: nil) }
    let foreign = KeyCombo("é", control: true)
    #expect(shortcut.warning(for: foreign) == "Chete can’t use that key. Try another.")
    #expect(shortcut.change(to: foreign) == "Chete can’t use that key. Try another.")
    #expect(shortcut.keys == nil)
}
