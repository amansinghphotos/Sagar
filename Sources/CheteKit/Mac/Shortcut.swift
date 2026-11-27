import Carbon.HIToolbox
import Look
import Shell

/// Chete's shortcut, held in any app. The welcome and Settings both change it here, so one set of keys is held.
package final class Shortcut {
    /// The one Chete holds while it runs.
    package static let chete = Shortcut()
    /// The three shortcuts Chete offers, in the welcome and in Settings. Picking any keys comes in 1.1.
    package static let suggestions = [
        KeyCombo("c", shift: true), KeyCombo("v", control: true), KeyCombo("c", control: true),
    ]

    /// One of the three as it is offered: in words, and whether it can be chosen.
    package struct Choice: Hashable {
        package let keys: KeyCombo
        package let words: String
        package let free: Bool
    }

    /// The three as they are offered. One that is `taken` says it is in use, and cannot be chosen.
    package static func choices(taken: (KeyCombo) -> Bool) -> [Choice] {
        suggestions.map { keys in
            let free = !taken(keys)
            return Choice(keys: keys, words: free ? keys.inWords : "\(keys.inWords), in use", free: free)
        }
    }

    /// What Chete does when the keys are pressed.
    package var pressed: () -> Void = {}
    private var held: HotKey?
    /// The keys held now, if any.
    package private(set) var keys: KeyCombo?

    package init() {}

    /// Holds these keys, or none, in place of the ones held before, and says why in words if they can't be held.
    /// If they can't, the old ones stay held.
    package func change(to combo: KeyCombo?) -> String? {
        guard combo != keys else { return nil }
        var new: HotKey?
        if let combo {
            guard let found = Self.keys(of: combo) else { return Self.unknown }
            do {
                new = try HotKey(found) { [weak self] in self?.pressed() }
            } catch {
                return Self.words(error)
            }
        }
        held?.letGo()
        (held, keys) = (new, combo)
        return nil
    }

    /// Why these keys can't be Chete's shortcut, in words, or nothing if they can. The keys held now can.
    package func warning(for combo: KeyCombo) -> String? {
        guard combo != keys else { return nil }
        guard let found = Self.keys(of: combo) else { return Self.unknown }
        return HotKey.refusal(of: found).map(Self.words)
    }

    /// A key Chete doesn't know where to find on the keyboard, as on one not set out as in the US.
    private static let unknown = "Chete can’t use that key. Try another."

    /// A refusal as the person reads it.
    package static func words(_ refusal: HotKey.Refusal) -> String {
        switch refusal {
        case .needsCommandOrControl: "Add ⌘ or ⌃, so typing still works."
        case .macOSHasIt: "Your Mac already uses these keys."
        case .heldAlready: "Chete already uses these keys."
        case .macOSRefused: "Your Mac won’t let Chete use these keys."
        }
    }

    /// The keys as macOS numbers them, by their place on a US keyboard, or nothing for a key not on one.
    static func keys(of combo: KeyCombo) -> HotKey.Keys? {
        codes[combo.key == "+" ? "=" : combo.key].map {
            HotKey.Keys(
                key: $0, command: combo.command, shift: combo.shift, option: combo.option, control: combo.control)
        }
    }

    private static let codes: [String: Int] = [
        "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D, "e": kVK_ANSI_E, "f": kVK_ANSI_F,
        "g": kVK_ANSI_G, "h": kVK_ANSI_H, "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
        "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P, "q": kVK_ANSI_Q, "r": kVK_ANSI_R,
        "s": kVK_ANSI_S, "t": kVK_ANSI_T, "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
        "y": kVK_ANSI_Y, "z": kVK_ANSI_Z, "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
        "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7, "8": kVK_ANSI_8, "9": kVK_ANSI_9,
        "`": kVK_ANSI_Grave, "-": kVK_ANSI_Minus, "=": kVK_ANSI_Equal, "[": kVK_ANSI_LeftBracket,
        "]": kVK_ANSI_RightBracket, "\\": kVK_ANSI_Backslash, ";": kVK_ANSI_Semicolon, "'": kVK_ANSI_Quote,
        ",": kVK_ANSI_Comma, ".": kVK_ANSI_Period, "/": kVK_ANSI_Slash, "up": kVK_UpArrow, "down": kVK_DownArrow,
        "left": kVK_LeftArrow, "right": kVK_RightArrow, "return": kVK_Return, "tab": kVK_Tab, "space": kVK_Space,
        "delete": kVK_Delete, "escape": kVK_Escape, "f1": kVK_F1, "f2": kVK_F2, "f3": kVK_F3, "f4": kVK_F4,
        "f5": kVK_F5, "f6": kVK_F6, "f7": kVK_F7, "f8": kVK_F8, "f9": kVK_F9, "f10": kVK_F10, "f11": kVK_F11,
        "f12": kVK_F12,
    ]
}

extension KeyCombo {
    /// The shortcut in words, as Apple writes one: Shift-Command-C.
    package var inWords: String {
        let held = [(control, "Control"), (option, "Option"), (shift, "Shift"), (command, "Command")]
        return (held.filter(\.0).map(\.1) + [key.count == 1 ? key.uppercased() : key.capitalized])
            .joined(separator: "-")
    }
}
