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
        #expect(lit.count == 8, "\(key) lit \(lit.sorted())")
        #expect(lit.isSubset(of: Keyboard.drawn), "\(key) is not drawn")
        #expect(lit.isSuperset(of: ["command", "right command", "shift", "right shift", "option", "right option"]))
        #expect(lit.contains("control"))
    }
}

@Test func aShortcutLightsItsKeyAndOnlyItsModifiers() {
    #expect(Keyboard.lit(by: KeyCombo("c", shift: true)) == ["c", "shift", "right shift", "command", "right command"])
    #expect(Keyboard.lit(by: KeyCombo("+")) == ["=", "command", "right command"])
    #expect(Keyboard.lit(by: KeyCombo("", command: false, control: true)) == ["control"])
}
