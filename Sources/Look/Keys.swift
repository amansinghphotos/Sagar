// Keyboard shortcuts: a shortcut as a value and as a menu shows it, a box that records one, and a fixed key.
import SwiftUI

/// A keyboard shortcut: a key, by its name, and the modifiers held with it.
nonisolated package struct KeyCombo: Codable, Hashable, Sendable {
    /// The key: a character in lower case, such as `t` or `]`, or a name, such as `left`, `return` or `f5`.
    package var key: String
    package var command = false
    package var shift = false
    package var option = false
    package var control = false

    package init(_ key: String, command: Bool = true, shift: Bool = false, option: Bool = false, control: Bool = false)
    {
        self.key = key
        self.command = command
        self.shift = shift
        self.option = option
        self.control = control
    }

    /// The shortcut a key press makes, or nil for a key that cannot be part of one.
    package init?(key equivalent: KeyEquivalent, modifiers: EventModifiers) {
        let character = equivalent.character
        let name: String
        if let named = Self.names[equivalent] {
            name = named
        } else if let scalar = character.unicodeScalars.first, (0xF704...0xF71B).contains(scalar.value) {
            name = "f\(scalar.value - 0xF704 + 1)"
        } else if character.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) {
            name = String(character).lowercased()
        } else {
            return nil
        }
        self.init(
            name, command: modifiers.contains(.command), shift: modifiers.contains(.shift),
            option: modifiers.contains(.option), control: modifiers.contains(.control))
    }

    /// Keys that are known by a name rather than by the character they type.
    private static let names: [KeyEquivalent: String] = [
        .upArrow: "up", .downArrow: "down", .leftArrow: "left", .rightArrow: "right", .return: "return", .tab: "tab",
        .space: "space", .delete: "delete", .deleteForward: "forwarddelete", .escape: "escape", .home: "home",
        .end: "end", .pageUp: "pageup", .pageDown: "pagedown", .clear: "clear",
    ]

    /// How a menu shows each named key.
    private static let symbols: [String: String] = [
        "up": "↑", "down": "↓", "left": "←", "right": "→", "return": "↩", "tab": "⇥", "space": "Space",
        "delete": "⌫", "forwarddelete": "⌦", "escape": "⎋", "home": "↖", "end": "↘", "pageup": "⇞",
        "pagedown": "⇟", "clear": "⌧",
    ]

    /// The shortcut as a menu shows it: its modifiers in the Mac's order, then its key. Shift with = is shown as +,
    /// as menus show Zoom In.
    package var display: String {
        let plus = shift && key == "="
        var shown = ""
        if control { shown += "⌃" }
        if option { shown += "⌥" }
        if shift && !plus { shown += "⇧" }
        if command { shown += "⌘" }
        if plus { return shown + "+" }
        return shown + (Self.symbols[key] ?? key.uppercased())
    }

    /// Whether the shortcut can be one: a key alone or with only Shift is typing, but for a function key.
    package var isUsable: Bool { command || option || control || isFunctionKey }

    private var isFunctionKey: Bool {
        key.count > 1 && key.first == "f" && key.dropFirst().allSatisfy(\.isNumber)
    }
}

/// A shortcut that cannot be changed, shown quietly in a box like the ones that can.
package struct FixedKey: View {
    private let text: String
    private let help: String

    package init(_ text: String, help: String = "") {
        self.text = text
        self.help = help
    }

    package var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Role.muted)
            .padding(.horizontal, 10)
            .frame(minWidth: 64, minHeight: 24)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control.rawValue, style: .continuous).strokeBorder(Role.hairline)
            )
            .help(help)
    }
}

/// A box that shows a shortcut and records a new one: click it, then press the keys. Delete clears it, Escape
/// leaves it as it was. A shortcut changed from its default is shown in heavier type.
package struct KeyBox: View {
    @Binding private var key: KeyCombo?
    private let changed: Bool
    @State private var listening: Bool
    @FocusState private var heard: Bool

    package init(key: Binding<KeyCombo?>, changed: Bool = false, listening: Bool = false) {
        _key = key
        self.changed = changed
        _listening = State(initialValue: listening)
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.control.rawValue, style: .continuous)
        Text(listening ? "Type a shortcut" : key?.display ?? "None")
            .font(.system(size: 12, weight: changed ? .semibold : .regular))
            .foregroundStyle(listening || key != nil ? Role.ink : Role.muted)
            .padding(.horizontal, 10)
            .frame(minWidth: 64, minHeight: 24)
            .background(Role.hover.opacity(listening ? 1 : 0), in: shape)
            .overlay(
                shape.strokeBorder(listening ? AnyShapeStyle(Role.ink.opacity(0.4)) : AnyShapeStyle(Role.hairline))
            )
            .contentShape(shape)
            .focusable()
            .focused($heard)
            .focusEffectDisabled()
            .onTapGesture {
                listening = true
                heard = true
            }
            .onChange(of: heard) { if !heard { listening = false } }
            .onKeyPress(phases: .down) { press in
                guard listening else { return .ignored }
                switch press.key {
                case .escape:
                    listening = false
                case .delete, .deleteForward:
                    key = nil
                    listening = false
                default:
                    guard let combo = KeyCombo(key: press.key, modifiers: press.modifiers), combo.isUsable else {
                        return .handled
                    }
                    key = combo
                    listening = false
                }
                return .handled
            }
            .accessibilityElement()
            .accessibilityLabel(listening ? "Type a shortcut" : "Shortcut, \(key?.display ?? "none")")
            .accessibilityAddTraits(.isButton)
    }
}
