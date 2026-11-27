// The row is taken from Search at commit c92ea7c: Omnibox.Row (Omnibox.swift). Copyright (c) 2026 Office Commun,
// MIT licence (ACKNOWLEDGEMENTS.md). Changed only where this repository's rules require: Search's colours and
// motion are read from Look, and what a row shows is given as an item rather than read from Search's own
// suggestions. Search keeps its arrows and Return in its AppKit field; here they are SwiftUI's, written fresh.
import SwiftUI

/// One thing the palette offers: what it is, a quieter word on it, and what leads its row.
nonisolated package struct PaletteItem: Identifiable, Sendable, Equatable {
    package let id: String
    package let key: String
    package let title: String
    /// A letter in a mark, as Search's places wear one.
    package var letter: String? = nil
    /// A symbol, as Search's commands wear one.
    package var symbol: String? = nil
    /// A command's key, shown at the end of its row.
    package var keyLabel: String? = nil

    package init(
        id: String, key: String, title: String, letter: String? = nil, symbol: String? = nil,
        keyLabel: String? = nil
    ) {
        self.id = id
        self.key = key
        self.title = title
        self.letter = letter
        self.symbol = symbol
        self.keyLabel = keyLabel
    }
}

/// How the palette narrows what it offers as you type.
nonisolated package enum Palette {
    /// Every item whose words hold each word typed, in its own order; those that
    /// needed a typo forgiven come after those that did not, as in Search.
    package static func rank(_ items: [PaletteItem], for typed: String) -> [PaletteItem] {
        let words = typed.lowercased().split(separator: " ").map { Array($0.utf8) }
        guard !words.isEmpty else { return items }
        let scored = items.compactMap { item in
            Fuzzy.match(words, in: (item.key + " " + item.title).lowercased()).map { (item, $0) }
        }
        return scored.filter { $0.1 == 1 }.map(\.0) + scored.filter { $0.1 == 0 }.map(\.0)
    }
}

/// A row of the palette: what leads it, its words, and a command's key.
package struct PaletteRow: View {
    let item: PaletteItem
    /// Where the arrow keys have walked to. The pointer gets its own,
    /// quieter mark, and changes nothing but the look of the row.
    let picked: Bool

    @Environment(\.motion) private var motion
    @State private var hovering = false

    package init(item: PaletteItem, picked: Bool) {
        self.item = item
        self.picked = picked
    }

    package var body: some View {
        HStack(spacing: 10) {
            // Every row has the same column before its words, so the
            // words line up whatever stands in it.
            Group {
                if let letter = item.letter {
                    Mark(icon: nil, letter: letter, size: 14)
                } else {
                    symbol(item.symbol ?? "magnifyingglass")
                }
            }
            .frame(width: 14, height: 14)
            Text(item.key)
                .font(.system(size: 13))
                .foregroundStyle(Role.ink)
                .lineLimit(1)
            if !item.title.isEmpty {
                Text(item.title)
                    .font(.system(size: 12))
                    .foregroundStyle(Role.muted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
            if let key = item.keyLabel {
                Text(key)
                    .font(.system(size: 12))
                    .foregroundStyle(Role.muted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            if picked {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Role.wash)
            } else if hovering {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Role.hover)
            }
        }
        .onHover { hovering = $0 }
        .animation(motion.quick, value: hovering)
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Role.muted)
    }
}

/// The palette: a field that narrows a list as you type, the arrows to walk it,
/// Return to take the one picked, and Escape to put it away.
package struct CommandPalette: View {
    @Binding var text: String
    let prompt: String
    let items: [PaletteItem]
    let take: (PaletteItem) -> Void
    let dismiss: () -> Void

    @Environment(\.motion) private var motion
    @State private var picked = 0

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

    private var offers: [PaletteItem] { Palette.rank(items, for: text) }

    package var body: some View {
        VStack(spacing: 8) {
            LaunchField(text: $text, prompt: prompt, refusals: 0)
            if !offers.isEmpty {
                LaunchList {
                    ForEach(Array(offers.enumerated()), id: \.element.id) { index, offer in
                        PaletteRow(item: offer, picked: index == picked)
                            .contentShape(Rectangle())
                            .onTapGesture { take(offer) }
                    }
                }
            }
        }
        .animation(motion.quick, value: offers.isEmpty)
        .onChange(of: text) { _, _ in picked = 0 }
        .onKeyPress(.downArrow) {
            picked = min(picked + 1, max(offers.count - 1, 0))
            return .handled
        }
        .onKeyPress(.upArrow) {
            picked = max(picked - 1, 0)
            return .handled
        }
        .onKeyPress(.return) {
            guard offers.indices.contains(picked) else { return .ignored }
            take(offers[picked])
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }
}
