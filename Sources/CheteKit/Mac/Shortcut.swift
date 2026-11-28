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

    /// The three as they are offered. One that is `taken` says so, and cannot be chosen.
    package static func choices(taken: (KeyCombo) -> Bool) -> [Choice] {
        suggestions.map { keys in
            let free = !taken(keys)
            return Choice(keys: keys, words: free ? keys.inWords : "\(keys.inWords), taken", free: free)
        }
    }

    package var pressed: () -> Void = {}
    private var held: HotKey?
    package private(set) var keys: KeyCombo?

    package init() {}

    /// Holds these keys, or none, in place of the ones before; if it can't, it says why and keeps the old ones.
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
        HotKey.Keys(
            named: combo.key == "+" ? "=" : combo.key, command: combo.command, shift: combo.shift,
            option: combo.option, control: combo.control)
    }
}
