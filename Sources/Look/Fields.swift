// Boxes to type into: the search box with its glass and its clear button, a plain named field and a password.
import SwiftUI

/// A search box: a magnifying glass, the words, and a button that clears them once there are any.
package struct Hunt: View {
    @Binding private var text: String
    private let prompt: String
    private let focus: FocusState<Bool>.Binding

    package init(text: Binding<String>, prompt: String = "Search", focus: FocusState<Bool>.Binding) {
        _text = text
        self.prompt = prompt
        self.focus = focus
    }

    package var body: some View {
        HStack(spacing: Space.near.rawValue) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Role.muted)
            TextField(text: $text, prompt: Text(verbatim: "")) { Text(prompt) }
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Role.ink)
                .focused(focus)
                .overlay(alignment: .leading) {
                    if text.isEmpty {
                        Text(prompt)
                            .font(.system(size: 13))
                            .foregroundStyle(Role.muted.opacity(0.7))
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Role.faint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "Clear"))
            }
        }
        .padding(.horizontal, Space.apart.rawValue)
        .frame(height: 32)
        .background(Role.wash, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// A field for a name, a site or the like, its name standing in it until something is typed.
package struct Field: View {
    private let name: String
    @Binding private var text: String

    package init(_ name: String, text: Binding<String>) {
        self.name = name
        _text = text
    }

    package var body: some View {
        Tile(name: name, empty: text.isEmpty) {
            TextField(text: $text, prompt: Text(verbatim: "")) { Text(name) }
        }
    }
}

/// A field for a password, which shows a dot for each letter.
package struct Secret: View {
    private let name: String
    @Binding private var text: String

    package init(_ name: String, text: Binding<String>) {
        self.name = name
        _text = text
    }

    package var body: some View {
        Tile(name: name, empty: text.isEmpty, design: .monospaced) {
            SecureField(text: $text, prompt: Text(verbatim: "")) { Text(name) }
        }
    }
}

/// A field on its pale tile, with its name in faint ink while it is empty. A password's dots are set in the
/// monospaced face, so that each stands as far from the next.
private struct Tile<Box: View>: View {
    let name: String
    let empty: Bool
    var design: Font.Design = .default
    @ViewBuilder let box: Box

    var body: some View {
        box
            .textFieldStyle(.plain)
            .font(.system(size: 12.5, design: design))
            .foregroundStyle(Role.ink)
            .overlay(alignment: .leading) {
                if empty {
                    Text(name)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Role.ink.opacity(0.3))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Space.gap.rawValue)
            .frame(height: 29)
            .background(Role.wash, in: RoundedRectangle(cornerRadius: Radius.row.rawValue, style: .continuous))
    }
}
