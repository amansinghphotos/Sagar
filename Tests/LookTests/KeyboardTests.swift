import Testing

@testable import Look

/// Every key a shortcut can name, as `KeyCombo` names it, but for +, which drops Shift and is tested below.
private let everyKey =
    "abcdefghijklmnopqrstuvwxyz0123456789`-[]\\;',./".map(String.init)
    + ["up", "down", "left", "right", "return", "tab", "space", "delete", "escape"]
    + (1...12).map { "f\($0)" }

@Test func everyKeyOfAShortcutLights() {
    for key in everyKey {
        let lit = Keyboard.lit(by: KeyCombo(key, command: true, shift: true, option: true, control: true))
        #expect(lit.count == 5, "\(key) lit \(lit.sorted())")
        #expect(lit.isSubset(of: Keyboard.drawn), "\(key) is not drawn")
        #expect(lit.isSuperset(of: ["command", "shift", "option", "control"]))
    }
}

@Test func aShortcutLightsItsKeyAndOnlyItsModifiers() {
    #expect(Keyboard.lit(by: KeyCombo("c", shift: true)) == ["c", "shift", "command"])
    #expect(Keyboard.lit(by: KeyCombo("+")) == ["=", "command"])
    #expect(Keyboard.lit(by: KeyCombo("", command: false, control: true)) == ["control"])
}

/// He asked for the left-hand modifiers alone, so a shortcut reads at a glance: none is drawn on the right.
@Test func noModifierIsDrawnOnTheRight() {
    #expect(Keyboard.drawn.isDisjoint(with: ["right command", "right option", "right shift"]))
}
