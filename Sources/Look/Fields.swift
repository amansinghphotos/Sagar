// Taken from Search at commit c92ea7c: Hunt (Plate.swift), and the Passwords panel's field and password
// field (Passwords.swift), lifted out of that panel as Field and Secret. Copyright (c) 2026 Office Commun,
// MIT licence (ACKNOWLEDGEMENTS.md). Changed only where this repository's rules require: Search's colours are
// read from Look, the panel's focus and Return, which belong to the panel, are left to whoever uses them, and each
// field is named for VoiceOver, as Apple's accessibility audit requires.
import SwiftUI

/// The field for narrowing a list. The wash, the glass, the caret.
package struct Hunt: View {
    @Binding var text: String
    var prompt = "Search"
    var focus: FocusState<Bool>.Binding

    package init(text: Binding<String>, prompt: String = "Search", focus: FocusState<Bool>.Binding) {
        _text = text
        self.prompt = prompt
        self.focus = focus
    }

    package var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Role.muted)
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(prompt).foregroundStyle(Role.muted.opacity(0.7))
                }
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Role.ink)
                    .focused(focus)
                    .accessibilityLabel(prompt)
            }
            .font(.system(size: 13))
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Role.faint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Role.wash, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// A field for words, its name shown in it while it is empty: Search's Passwords panel's.
package struct Field: View {
    let name: String
    @Binding var text: String

    package init(_ name: String, text: Binding<String>) {
        self.name = name
        _text = text
    }

    package var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(name).foregroundStyle(Role.ink.opacity(0.3)).padding(.leading, 10)
            }
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(Role.ink)
                .accessibilityLabel(name)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
        }
        .font(.system(size: 12.5))
        .background(Role.wash, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

/// A field for a password, shown as dots: Search's Passwords panel's.
package struct Secret: View {
    let name: String
    @Binding var text: String

    package init(_ name: String, text: Binding<String>) {
        self.name = name
        _text = text
    }

    package var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(name).foregroundStyle(Role.ink.opacity(0.3))
                    .padding(.leading, 10)
            }
            SecureField("", text: $text)
                .textFieldStyle(.plain)
                .accessibilityLabel(name)
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundStyle(Role.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
        }
        .background(Role.wash, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
