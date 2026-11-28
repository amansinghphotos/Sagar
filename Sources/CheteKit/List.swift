import ImageIO
import Look
import SwiftUI

/// Your clips under a field to find them: newest first, the arrow keys move, Return picks, and Shift-Return
/// picks it as plain text. Built from Look's search field, rows and marks.
package struct ClipList: View {
    let clips: [Clip]
    let now: Date
    let pick: (Clip, _ plainText: Bool) -> Void
    @State private var typed: String
    @State private var choice = Choice(nil)
    @FocusState private var finding: Bool
    @Environment(\.appearsActive) private var active

    package init(
        clips: [Clip], now: Date = .now, typed: String = "", pick: @escaping (Clip, _ plainText: Bool) -> Void
    ) {
        self.clips = clips
        self.now = now
        self.pick = pick
        _typed = State(initialValue: typed)
    }

    package var body: some View {
        let found = clips.found(by: typed)
        let chosen = choice.id(in: found)
        VStack(spacing: 0) {
            Hunt(text: $typed, prompt: "Find a clip", focus: $finding)
                .padding(Space.page.rawValue)
            if clips.isEmpty {
                Key("⌘ C", "Copy something, and it shows up here.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if found.isEmpty {
                Text("No clips match “\(typed)”.")
                    .type(.body)
                    .foregroundStyle(Role.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { scroller in
                    ScrollView {
                        LazyVStack(spacing: Space.hair.rawValue) {
                            ForEach(found) { clip in
                                ClipRow(row: Row(clip, now: now), chosen: clip.id == chosen)
                                    .id(clip.id)
                                    .onTapGesture(count: 2) { pick(clip, false) }
                                    .onTapGesture { choice = Choice(clip.id) }
                            }
                        }
                        .padding(.horizontal, Space.page.rawValue)
                        .padding(.bottom, Space.page.rawValue)
                    }
                    .onChange(of: chosen) { scroller.scrollTo(chosen) }
                }
            }
        }
        // In a wide window the list keeps to a column that is easy to read, as wide as the default window.
        .frame(maxWidth: WindowSize.standard.width)
        .frame(maxWidth: .infinity)
        .background(Role.ground)
        .onKeyPress(.downArrow) {
            choice.move(1, in: found)
            return .handled
        }
        .onKeyPress(.upArrow) {
            choice.move(-1, in: found)
            return .handled
        }
        .onKeyPress(.return, phases: .down) { press in
            guard let clip = found.first(where: { $0.id == chosen }) else { return .ignored }
            pick(clip, press.modifiers.contains(.shift))
            return .handled
        }
        // Each time the window comes forward, typing goes to the field, so a person only types. The focus is set
        // once the window is ready for it: set as the list appears, macOS drops it.
        .onChange(of: active, initial: true) {
            if active { Task { finding = true } }
        }
    }
}

/// One clip in the list: a mark for what it is, its first line and what it is, on Look's live grey when
/// chosen. The mark sits under the field's glass, and the words start where the field's words do.
private struct ClipRow: View {
    @Environment(\.greys) private var greys
    let row: Row
    let chosen: Bool

    var body: some View {
        HStack(spacing: Space.near.rawValue) {
            Mark(icon: Image(systemName: row.symbol), template: true, letter: "")
            VStack(alignment: .leading, spacing: Space.hair.rawValue) {
                Text(row.title).type(.body).foregroundStyle(Role.ink)
                Text(row.detail).type(.detail).foregroundStyle(Role.muted)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
            if chosen {
                Key("↩", "Copy").padding(.trailing, Space.apart.rawValue)
            }
        }
        .padding(.leading, Space.gap.rawValue)
        .padding(.vertical, Space.near.rawValue)
        .background {
            if chosen { RoundedRectangle(cornerRadius: Radius.row.rawValue, style: .continuous).fill(greys.pinLive) }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }
}

/// Which clip the arrow keys have chosen. When typing hides it, the newest clip found is chosen.
package struct Choice: Equatable {
    private var chosen: Clip.ID?

    package init(_ chosen: Clip.ID?) {
        self.chosen = chosen
    }

    package func id(in found: [Clip]) -> Clip.ID? {
        found.contains { $0.id == chosen } ? chosen : found.first?.id
    }

    /// Moves the choice by a number of rows, stopping at either end.
    package mutating func move(_ rows: Int, in found: [Clip]) {
        guard let index = found.firstIndex(where: { $0.id == id(in: found) }) else { return }
        chosen = found[min(max(index + rows, 0), found.count - 1)].id
    }
}

/// How a clip reads in its row: its first line, and what it is and when it was copied.
package struct Row: Equatable {
    package let title: String
    package let detail: String
    /// The symbol for what it is.
    package let symbol: String

    package init(_ clip: Clip, now: Date) {
        let files = clip.kinds.compactMap { if case .file(let file) = $0 { file } else { nil } }
        let (title, what, symbol): (String, String, String) =
            if let file = files.first {
                (
                    files.count == 1 ? file.lastPathComponent : "\(file.lastPathComponent) and \(files.count - 1) more",
                    files.count == 1 ? "File" : "Files", "doc"
                )
            } else if let link = clip.kinds.lazy.compactMap({ if case .link(let link) = $0 { link } else { nil } })
                .first
            {
                (link.absoluteString, "Link", "link")
            } else if let data = clip.kinds.lazy.compactMap({ if case .picture(let data, _) = $0 { data } else { nil } }
            ).first {
                (pixels(of: data) ?? "Picture", "Picture", "photo")
            } else {
                (clip.firstLine, "Text", "text.alignleft")
            }
        let when = RelativeDateTimeFormatter()
        when.dateTimeStyle = .named
        self.title = title
        detail = "\(what) · \(when.localizedString(for: clip.copied, relativeTo: now))"
        self.symbol = symbol
    }
}

/// A picture's size, as "1200 × 800", if its bytes can be read.
private func pixels(of picture: Data) -> String? {
    guard let source = CGImageSourceCreateWithData(picture as CFData, nil),
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
        let width = properties[kCGImagePropertyPixelWidth] as? Int,
        let height = properties[kCGImagePropertyPixelHeight] as? Int
    else { return nil }
    return "\(width) × \(height)"
}

extension Clip {
    /// The first line of its text that holds anything.
    fileprivate var firstLine: String {
        let text = kinds.lazy.compactMap { if case .text(let text) = $0 { text } else { nil } }.first ?? ""
        return text.split(whereSeparator: \.isNewline).first { !$0.allSatisfy(\.isWhitespace) }
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
    }
}

/// The clips the list shows, kept up to date as you copy.
@Observable
package final class Shelf {
    /// Newest first.
    package var clips: [Clip]

    package init(_ clips: [Clip] = []) {
        self.clips = clips
    }

    /// Puts a clip just kept on top, in place of the one it was if it was copied before.
    package func add(_ clip: Clip) {
        clips.removeAll { $0.id == clip.id }
        clips.insert(clip, at: 0)
    }

    /// Takes away clips just deleted. One copied again since is a newer clip, and stays.
    package func remove(_ deleted: [Clip]) {
        let copied = Dictionary(deleted.map { ($0.id, $0.copied) }) { first, _ in first }
        clips.removeAll { copied[$0.id] == $0.copied }
    }
}
