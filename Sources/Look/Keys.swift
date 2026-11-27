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
        // Zoom In's key is = with Shift on some keyboards and a + key of its own on others. Both are kept as +, with
        // no Shift, so the two are one shortcut.
        let zoom = key == "=" || key == "+"
        self.key = zoom ? "+" : key.lowercased()
        self.command = command
        self.shift = zoom ? false : shift
        self.option = option
        self.control = control
    }

    /// The shortcut a key press makes, read as the key itself rather than what it types, so ⇧⌘] is ] with Shift; nil
    /// for a press with no key.
    package init?(key equivalent: KeyEquivalent, modifiers: EventModifiers) {
        let character = equivalent.character
        let name: String
        if let named = Self.names[equivalent] {
            name = named
        } else if let scalar = character.unicodeScalars.first, (0xF704...0xF71B).contains(scalar.value) {
            name = "f\(scalar.value - 0xF704 + 1)"
        } else {
            name = String(character)
        }
        guard !name.isEmpty else { return nil }
        self.init(
            name, command: modifiers.contains(.command), shift: modifiers.contains(.shift),
            option: modifiers.contains(.option), control: modifiers.contains(.control))
    }

    /// Keys that are known by a name rather than by the character they type.
    private static let names: [KeyEquivalent: String] = [
        .upArrow: "up", .downArrow: "down", .leftArrow: "left", .rightArrow: "right", .return: "return", .tab: "tab",
        .space: "space", .delete: "delete", .deleteForward: "delete", .escape: "escape", .home: "home",
        .end: "end", .pageUp: "pageup", .pageDown: "pagedown", .clear: "clear",
    ]

    /// How a menu shows each named key.
    private static let symbols: [String: String] = [
        "up": "↑", "down": "↓", "left": "←", "right": "→", "return": "↩", "tab": "⇥", "space": "Space",
        "delete": "⌫", "escape": "⎋", "home": "↖", "end": "↘", "pageup": "⇞",
        "pagedown": "⇟", "clear": "⌧",
    ]

    /// The shortcut as a menu shows it: its modifiers in the Mac's order, then its key.
    package var display: String {
        var shown = ""
        if control { shown += "⌃" }
        if option { shown += "⌥" }
        if shift { shown += "⇧" }
        if command { shown += "⌘" }
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
            .lineLimit(1)
            .padding(.horizontal, 10)
            .frame(minWidth: 64, minHeight: 24)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control.rawValue, style: .continuous).strokeBorder(Role.hairline)
            )
            .help(help)
    }
}

/// A box that shows a shortcut and records a new one: click it, then press the keys. Delete alone clears it, Escape
/// alone leaves it as it was. A shortcut changed from its default is shown in heavier type. A key `refusal` names a
/// reason for is refused for a moment; one that `owner` says another command has is taken only when pressed twice.
package struct KeyBox: View {
    @Binding private var key: KeyCombo?
    private let changed: Bool
    private let refusal: (KeyCombo) -> String?
    private let owner: (KeyCombo) -> String?
    @State private var listening: Bool
    @State private var hovering = false
    /// Why the last key will not do, shown for a moment in place of the shortcut.
    @State private var note: String?
    /// A shortcut another command has, pressed once and waiting to be pressed again.
    @State private var taking: KeyCombo?
    @FocusState private var heard: Bool

    package init(
        key: Binding<KeyCombo?>, changed: Bool = false, refusal: @escaping (KeyCombo) -> String? = { _ in nil },
        owner: @escaping (KeyCombo) -> String? = { _ in nil }, listening: Bool = false
    ) {
        _key = key
        self.changed = changed
        self.refusal = refusal
        self.owner = owner
        _listening = State(initialValue: listening)
    }

    private var words: String {
        if let taking, let other = owner(taking) { return "Used by \(other). Press again to take it." }
        if let note { return note }
        return listening ? "Type a shortcut" : key?.display ?? "None"
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.control.rawValue, style: .continuous)
        Button(action: listenOrStop) {
            Text(words)
                .font(.system(size: 12, weight: changed ? .semibold : .regular))
                .foregroundStyle(listening || key != nil ? Role.ink : Role.muted)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(minWidth: 64, minHeight: 24)
                .background(listening || hovering ? Role.hover : Role.ground, in: shape)
                .overlay(
                    shape.strokeBorder(listening ? AnyShapeStyle(Role.ink.opacity(0.4)) : AnyShapeStyle(Role.hairline))
                )
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .help("Click, then press the new shortcut")
        .onHover { hovering = $0 }
        .focusable(listening)
        .focused($heard)
        .onKeyPress(phases: .down) { press in
            guard listening else { return .ignored }
            hear(KeyCombo(key: press.key, modifiers: press.modifiers))
            return .handled
        }
        .onChange(of: heard) { if !heard, listening { stop() } }
        .onDisappear(perform: stop)
    }

    private func listenOrStop() {
        if listening { return stop() }
        note = nil
        taking = nil
        listening = true
        heard = true
    }

    private func hear(_ combo: KeyCombo?) {
        guard let combo else { return }
        let bare = !(combo.command || combo.option || combo.control || combo.shift)
        if bare, combo.key == "escape" { return stop() }
        if bare, combo.key == "delete" {
            key = nil
            return stop()
        }
        guard combo.isUsable else { return refuse("Add ⌘, ⌥ or ⌃") }
        if let reason = refusal(combo) { return refuse(reason) }
        if owner(combo) != nil, taking != combo {
            taking = combo
            return
        }
        key = combo
        stop()
    }

    /// Says why a key will not do, for a moment, and goes on listening.
    private func refuse(_ reason: String) {
        note = reason
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            if note == reason { note = nil }
        }
    }

    private func stop() {
        listening = false
        note = nil
        taking = nil
        heard = false
    }
}
