import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's shortcut boxes: one set, one changed, one with none, one listening, and a fixed key, on Search's ground.
private struct Showcase: View {
    @State var set: KeyCombo? = KeyCombo("t")
    @State var changed: KeyCombo? = KeyCombo("k", shift: true)
    @State var none: KeyCombo?
    @State var listening: KeyCombo?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                KeyBox(key: $set)
                KeyBox(key: $changed, changed: true)
                KeyBox(key: $none)
            }
            HStack(spacing: 10) {
                KeyBox(key: $listening, listening: true)
                FixedKey("⌘1 – ⌘9")
            }
        }
        .padding(16)
        .frame(width: 340, height: 140)
        .background(Role.ground)
    }
}

@Test(arguments: [false, true])
func theShortcutBoxesLookAsSearchsDo(dark: Bool) throws {
    try expectSearchPicture(of: Showcase(), width: 340, height: 140, named: "Keys", dark: dark)
}

@Test func aShortcutIsShownAsAMenuShowsIt() {
    #expect(KeyCombo("k", shift: true).display == "⇧⌘K")
    #expect(KeyCombo("left", command: false, option: true, control: true).display == "⌃⌥←")
    #expect(KeyCombo("=", shift: true).display == "⌘+")
}

@Test func aKeyAloneOrWithShiftIsTypingNotAShortcut() {
    #expect(!KeyCombo("a", command: false).isUsable)
    #expect(!KeyCombo("a", command: false, shift: true).isUsable)
    #expect(KeyCombo("f5", command: false).isUsable)
    #expect(KeyCombo("a", command: false, option: true).isUsable)
}

@Test func aKeyHeardIsReadAsItsName() {
    #expect(KeyCombo(key: .leftArrow, modifiers: [.command]) == KeyCombo("left"))
    #expect(KeyCombo(key: KeyEquivalent("]"), modifiers: [.command, .shift]) == KeyCombo("]", shift: true))
    #expect(KeyCombo(key: KeyEquivalent("x"), modifiers: []) == KeyCombo("x", command: false))
}

@Test func aFunctionKeyHeardIsReadByItsNameAndIsAShortcutAlone() throws {
    let f5 = try #require(KeyCombo(key: KeyEquivalent(Character(UnicodeScalar(0xF708)!)), modifiers: []))
    #expect(f5 == KeyCombo("f5", command: false))
    #expect(f5.display == "F5")
    #expect(f5.isUsable)
}
