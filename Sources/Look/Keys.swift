// Taken from Search at commit c92ea7c: KeyCombo (Shortcuts.swift, its value and how a menu shows it), and FixedKey and
// KeyBox (ShortcutsPage.swift). Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only where
// this repository's rules require: Search's colours are read from Look; a key is heard through SwiftUI, as Look may not
// use AppKit's events; and given values replace Search's store of shortcuts.
import SwiftUI

/// A key and the modifiers held with it.
nonisolated package struct KeyCombo: Codable, Hashable, Sendable {
    /// A lowercased character, or the name of a key that has none:
    /// left, right, up, down, return, delete, space, f1…f12.
    package var key: String
    package var command = false
    package var shift = false
    package var option = false
    package var control = false

    package init(_ key: String, command: Bool = true, shift: Bool = false, option: Bool = false, control: Bool = false)
    {
        // ⌘+ is ⇧⌘= on some keyboards and a key of its own on others; both
        // mean the same thing, so both are kept as "+" with nothing about ⇧.
        let plus = key == "=" || key == "+"
        self.key = plus ? "+" : key.lowercased()
        self.shift = plus ? false : shift
        self.command = command
        self.option = option
        self.control = control
    }

    /// The key SwiftUI heard, with the modifiers held.
    package init?(key equivalent: KeyEquivalent, characters: String, modifiers: EventModifiers) {
        let key = KeyCombo.names[equivalent] ?? (characters.isEmpty ? String(equivalent.character) : characters)
        guard !key.isEmpty else { return nil }
        self.init(
            key, command: modifiers.contains(.command), shift: modifiers.contains(.shift),
            option: modifiers.contains(.option), control: modifiers.contains(.control))
    }

    private static let names: [KeyEquivalent: String] = [
        .leftArrow: "left", .rightArrow: "right", .downArrow: "down", .upArrow: "up", .return: "return",
        .delete: "delete", .deleteForward: "delete", .space: "space", .tab: "tab", .escape: "escape",
    ]

    private static let symbols: [String: String] = [
        "left": "←", "right": "→", "up": "↑", "down": "↓", "return": "↩", "delete": "⌫", "space": "Space",
        "tab": "⇥", "escape": "⎋",
    ]

    /// As a menu shows it: ⌃⌥⇧⌘ then the key.
    package var display: String {
        (control ? "⌃" : "") + (option ? "⌥" : "") + (shift ? "⇧" : "") + (command ? "⌘" : "")
            + (KeyCombo.symbols[key] ?? key.uppercased())
    }

    private var isFunctionKey: Bool { key.count > 1 && key.hasPrefix("f") && Int(key.dropFirst()) != nil }

    /// A key alone, or with only ⇧, is typing — never a shortcut.
    package var isUsable: Bool { command || option || control || isFunctionKey }
}

/// Keys that are listed but not moved here, drawn as a KeyBox at rest.
package struct FixedKey: View {
    let text: String

    package init(_ text: String) { self.text = text }

    package var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Role.muted)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .frame(minWidth: 64, minHeight: 24)
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Role.hairline, lineWidth: 1)
            )
    }
}

/// The key a command is on. Click it and press another: that key moves
/// here, from whichever command had it. Esc stops without changing it,
/// ⌫ takes it off. With `listening`, it starts out waiting for a key.
package struct KeyBox: View {
    @Binding var key: KeyCombo?
    /// True when the key is not the one the command came with.
    var changed = false
    /// Why a key will not do, said for a moment while still listening; nil when it will.
    var refusal: (KeyCombo) -> String? = { _ in nil }
    /// The command that has a key already, if another does.
    var owner: (KeyCombo) -> String? = { _ in nil }

    @State private var listening = false
    @State private var note: String?
    @State private var hovering = false
    /// A key another command has, pressed once: pressed again, it moves here.
    @State private var taking: KeyCombo?
    @FocusState private var heard: Bool

    package init(
        key: Binding<KeyCombo?>, changed: Bool = false, refusal: @escaping (KeyCombo) -> String? = { _ in nil },
        owner: @escaping (KeyCombo) -> String? = { _ in nil }, listening: Bool = false
    ) {
        _listening = State(initialValue: listening)
        _key = key
        self.changed = changed
        self.refusal = refusal
        self.owner = owner
    }

    package var body: some View {
        Button(action: listen) {
            Text(label)
                .font(.system(size: 12, weight: changed ? .semibold : .regular))
                .foregroundStyle(listening || key != nil ? Role.ink : Role.muted)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(minWidth: 64, minHeight: 24)
                .background(
                    listening ? Role.hover : (hovering ? Role.hover : Role.ground),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(
                            listening ? AnyShapeStyle(Role.ink.opacity(0.4)) : AnyShapeStyle(Role.hairline),
                            lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Click, then press the new shortcut")
        .onHover { hovering = $0 }
        .focusable(listening)
        .focused($heard)
        .onKeyPress(phases: .down) { press in
            guard listening else { return .ignored }
            take(KeyCombo(key: press.key, characters: press.characters, modifiers: press.modifiers))
            return .handled
        }
        .onDisappear(perform: stop)
    }

    private var label: String {
        if let taking, let other = owner(taking) {
            return "Used by \(other) — press again"
        }
        if let note { return note }
        if listening { return "Type a shortcut" }
        return key?.display ?? "None"
    }

    private func listen() {
        guard !listening else { return stop() }
        listening = true
        note = nil
        taking = nil
        heard = true
    }

    private func take(_ combo: KeyCombo?) {
        guard let combo else { return }
        let alone = !combo.command && !combo.option && !combo.control && !combo.shift
        if combo.key == "escape", alone { return stop() }
        if combo.key == "delete", alone {
            key = nil
            return stop()
        }
        guard combo.isUsable else { return say("Add ⌘, ⌥ or ⌃") }
        if let reason = refusal(combo) { return say(reason) }
        if owner(combo) != nil, taking != combo {
            taking = combo
            return
        }
        key = combo
        stop()
    }

    /// Why that key won't do, for a moment, still listening.
    private func say(_ text: String) {
        note = text
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            if note == text { note = nil }
        }
    }

    private func stop() {
        listening = false
        note = nil
        taking = nil
        heard = false
    }
}
