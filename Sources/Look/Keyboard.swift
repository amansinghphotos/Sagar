import SwiftUI

/// A Mac keyboard, drawn, that lights the keys of a shortcut: outlined at rest, filled while they are held, and in the
/// warning colour when the shortcut will not do. Under it, the shortcut as a menu shows it, or the warning in words.
package struct Keyboard: View {
    @Environment(\.motion) private var motion
    let shortcut: KeyCombo?
    let held: KeyCombo?
    let warning: String?

    /// A keyboard showing `shortcut` at rest, or the keys `held` while they are pressed: a shortcut with no key, ""
    /// for its key, lights its modifiers alone. A `warning` says why the keys will not do.
    package init(shortcut: KeyCombo?, held: KeyCombo? = nil, warning: String? = nil) {
        self.shortcut = shortcut
        self.held = held
        self.warning = warning
    }

    package var body: some View {
        let shown = held ?? shortcut
        let lit = shown.map(Self.lit) ?? []
        VStack(spacing: Space.apart.rawValue) {
            VStack(spacing: Self.gap) {
                ForEach(Self.rows.indices, id: \.self) { row in
                    HStack(spacing: Self.gap) {
                        ForEach(Self.rows[row]) { key in
                            KeyCap(key: key, lit: lit, light: light, short: row == 0)
                        }
                    }
                }
            }
            .padding(Space.near.rawValue)
            .background(Role.wash, in: RoundedRectangle(cornerRadius: Radius.card.rawValue, style: .continuous))
            .animation(motion.quick, value: lit)
            .animation(motion.quick, value: held != nil)
            Text(warning ?? shown.map(\.display) ?? " ")
                .type(warning == nil ? .heading : .body)
                .foregroundStyle(warning == nil ? Role.ink : Role.unsafe)
                .lineLimit(1)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Keyboard")
        .accessibilityValue(warning ?? shown.map(\.display) ?? "No keys")
    }

    private var light: Light { warning != nil ? .warning : held != nil ? .held : .rest }

    /// The keys a shortcut lights: its key and its modifiers, which are drawn on the left alone.
    package static func lit(by shortcut: KeyCombo) -> Set<String> {
        var lit: Set<String> = []
        if !shortcut.key.isEmpty { lit.insert(shortcut.key == "+" ? "=" : shortcut.key) }
        if shortcut.command { lit.insert("command") }
        if shortcut.shift { lit.insert("shift") }
        if shortcut.option { lit.insert("option") }
        if shortcut.control { lit.insert("control") }
        return lit
    }

    /// The name of every key drawn.
    package static var drawn: Set<String> {
        Set(rows.joined().map(\.id)).subtracting(["arrows", "blank"]).union(["left", "up", "down", "right"])
    }

    /// The width of a key one unit wide, and the gap between keys.
    private static let unit: CGFloat = 26
    private static let gap: CGFloat = Space.hair.rawValue + 1

    /// A Mac's keys in their rows, each named as `KeyCombo` names it, each row 14½ units wide. The modifiers are drawn
    /// on the left alone, so a shortcut reads at a glance: the space bar takes the place of the right ones, and the
    /// right Shift's place is left empty.
    private static let rows: [[Cap]] = [
        [Cap("escape", "esc", 1.5)] + (1...12).map { Cap("f\($0)", "F\($0)", 13 / 12) },
        "`1234567890-=".map { Cap(String($0)) } + [Cap("delete", "⌫", 1.5)],
        [Cap("tab", "⇥", 1.5)] + "qwertyuiop[]\\".map { Cap(String($0)) },
        [Cap("caps lock", "⇪", 1.75)] + "asdfghjkl;'".map { Cap(String($0)) } + [Cap("return", "↩", 1.75)],
        [Cap("shift", "⇧", 2.25)] + "zxcvbnm,./".map { Cap(String($0)) } + [Cap("blank", "", 2.25)],
        [
            Cap("fn", "fn"), Cap("control", "⌃"), Cap("option", "⌥"), Cap("command", "⌘", 1.25),
            Cap("space", "", 7.25),
            Cap("arrows", "", 3, arrows: true),
        ],
    ]

    /// One key: its name, what is printed on it, and how many units wide it is.
    fileprivate struct Cap: Identifiable {
        let id: String
        let label: String
        let units: CGFloat
        let arrows: Bool

        init(_ id: String, _ label: String? = nil, _ units: CGFloat = 1, arrows: Bool = false) {
            self.id = id
            self.label = label ?? id.uppercased()
            self.units = units
            self.arrows = arrows
        }

        /// Its width, so that every row comes out the same width with its gaps.
        var width: CGFloat { units * Keyboard.unit - Keyboard.gap }
    }

    fileprivate enum Light { case rest, held, warning }

    /// One key, lit or not. The arrows are four half keys in the space of three.
    private struct KeyCap: View {
        let key: Cap
        let lit: Set<String>
        let light: Light
        let short: Bool

        var body: some View {
            if key.id == "blank" {
                Color.clear.frame(width: key.width, height: Keyboard.unit - Keyboard.gap)
            } else if key.arrows {
                HStack(alignment: .bottom, spacing: Keyboard.gap) {
                    half("left", "←")
                    VStack(spacing: Keyboard.gap) {
                        half("up", "↑")
                        half("down", "↓")
                    }
                    half("right", "→")
                }
            } else {
                face(key.id, key.label)
                    .frame(width: key.width, height: short ? Keyboard.unit * 0.6 : Keyboard.unit - Keyboard.gap)
            }
        }

        /// An arrow key, half as tall as a key.
        private func half(_ id: String, _ label: String) -> some View {
            face(id, label)
                .frame(width: Keyboard.unit - Keyboard.gap, height: (Keyboard.unit - Keyboard.gap * 2) / 2)
        }

        private func face(_ id: String, _ label: String) -> some View {
            let light = lit.contains(id) ? light : nil
            let shape = RoundedRectangle(cornerRadius: Radius.small.rawValue - 1, style: .continuous)
            return Text(label)
                .type(.small)
                .foregroundStyle(ink(light))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(fill(light), in: shape)
                .overlay(shape.strokeBorder(edge(light), lineWidth: light == nil ? 0.5 : 1.5))
                .scaleEffect(light == .held ? Motion.give : 1)
        }

        private func ink(_ light: Light?) -> Role {
            switch light {
            case nil: .muted
            case .rest: .ink
            case .held: .ground
            case .warning: .unsafe
            }
        }

        private func fill(_ light: Light?) -> Role {
            light == .held ? .ink : .ground
        }

        private func edge(_ light: Light?) -> Role {
            switch light {
            case nil: .hairline
            case .rest, .held: .ink
            case .warning: .unsafe
            }
        }
    }
}
