// The command palette: things to pick from by typing, how typed words rank them, and how each shows in the list.
import SwiftUI

/// One thing a palette offers.
nonisolated package struct PaletteItem: Identifiable, Sendable, Equatable {
    package let id: String
    /// The words it is found by, and shows first.
    package let key: String
    /// Quieter words beside them, also found by.
    package let title: String
    /// A letter on a small tile before it.
    package var letter: String? = nil
    /// Or a symbol before it, by its system name. With neither, a magnifying glass.
    package var symbol: String? = nil
    /// The keys that take it, shown at the end.
    package var keyLabel: String? = nil

    package init(
        id: String, key: String, title: String, letter: String? = nil, symbol: String? = nil, keyLabel: String? = nil
    ) {
        self.id = id
        self.key = key
        self.title = title
        self.letter = letter
        self.symbol = symbol
        self.keyLabel = keyLabel
    }
}

/// How a palette chooses what to offer.
nonisolated package enum Palette {
    /// The items whose words hold every typed word, those typed exactly before those that needed a typo forgiven,
    /// and otherwise in their own order. Nothing typed offers them all.
    package static func rank(_ items: [PaletteItem], for typed: String) -> [PaletteItem] {
        let words = typed.lowercased().split(separator: " ").map { Array($0.utf8) }
        guard !words.isEmpty else { return items }
        let found = items.compactMap { item in
            Fuzzy.match(words, in: "\(item.key) \(item.title)".lowercased()).map { (item: item, score: $0) }
        }
        let exact = found.filter { $0.score == 1 }.map(\.item)
        let forgiven = found.filter { $0.score == 0 }.map(\.item)
        return exact + forgiven
    }
}

/// One line of a palette: its tile or symbol, its words, and the keys that take it.
package struct PaletteRow: View {
    @Environment(\.motion) private var motion
    @State private var hovering = false
    private let item: PaletteItem
    private let picked: Bool

    package init(item: PaletteItem, picked: Bool) {
        self.item = item
        self.picked = picked
    }

    package var body: some View {
        HStack(spacing: Space.gap.rawValue) {
            mark.frame(width: Self.mark, height: Self.mark)
            Text(item.key).type(.body).foregroundStyle(Role.ink)
            if !item.title.isEmpty {
                Text(item.title).type(.row).foregroundStyle(Role.muted)
            }
            Spacer(minLength: 0)
            if let keys = item.keyLabel {
                Text(keys).type(.row).foregroundStyle(Role.muted)
            }
        }
        .lineLimit(1)
        .padding(.horizontal, Space.apart.rawValue)
        .frame(height: 34)
        .background {
            RoundedRectangle(cornerRadius: Radius.row.rawValue, style: .continuous)
                .fill(picked ? Role.wash : Role.hover)
                .opacity(picked || hovering ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(motion.quick, value: hovering)
    }

    /// The tile with a letter, or the symbol, before the words.
    @ViewBuilder private var mark: some View {
        if let letter = item.letter {
            Mark(icon: nil, letter: letter, size: Self.mark)
        } else {
            Image(systemName: item.symbol ?? "magnifyingglass")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Role.muted)
        }
    }

    /// The side of the tile, in points.
    private static let mark: CGFloat = 14
}

/// A launcher field over the items it offers: typing narrows them, the arrows move the pick, Return takes it and
/// Escape lets the palette go. Return with nothing offered is left to whatever holds the palette.
package struct CommandPalette: View {
    @Environment(\.motion) private var motion
    @Binding private var text: String
    @State private var pick = 0
    private let prompt: String
    private let items: [PaletteItem]
    private let take: (PaletteItem) -> Void
    private let dismiss: () -> Void

    package init(
        text: Binding<String>, prompt: String, items: [PaletteItem], take: @escaping (PaletteItem) -> Void,
        dismiss: @escaping () -> Void
    ) {
        _text = text
        self.prompt = prompt
        self.items = items
        self.take = take
        self.dismiss = dismiss
    }

    package var body: some View {
        let offers = Palette.rank(items, for: text)
        VStack(spacing: Space.near.rawValue) {
            LaunchField(text: $text, prompt: prompt, refusals: 0)
            if !offers.isEmpty {
                LaunchList {
                    ForEach(Array(offers.enumerated()), id: \.element.id) { index, item in
                        PaletteRow(item: item, picked: index == pick)
                            .onTapGesture { take(item) }
                    }
                }
            }
        }
        .animation(motion.quick, value: offers.isEmpty)
        .onChange(of: text) { pick = 0 }
        .onKeyPress(.upArrow) {
            pick = max(pick - 1, 0)
            return .handled
        }
        .onKeyPress(.downArrow) {
            pick = min(pick + 1, max(offers.count - 1, 0))
            return .handled
        }
        .onKeyPress(.return) {
            guard offers.indices.contains(pick) else { return .ignored }
            take(offers[pick])
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }
}
