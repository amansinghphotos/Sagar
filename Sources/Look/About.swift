// Taken from Search at commit c92ea7c: WhatsNewCard (WhatsNew.swift) and AboutView (About.swift). Copyright (c)
// 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only where this repository's rules require:
// Search's colours are read from Look; what the card lists, and the About view's icon, name, version and
// copyright, are given by the app, not read from Search's own; Search's email block and iPhone line are its
// own and left out; and the About view may carry a credit line, for the acknowledgements every app owes.
import SwiftUI

/// The card that says what is new in a version: its switches in a card, a link to
/// all the notes, and Close.
package struct NewCard: View {
    let title: String
    let rows: [(String, String, Binding<Bool>)]
    let close: () -> Void
    let notes: () -> Void

    package init(
        title: String, rows: [(String, String, Binding<Bool>)], close: @escaping () -> Void,
        notes: @escaping () -> Void
    ) {
        self.title = title
        self.rows = rows
        self.close = close
        self.notes = notes
    }

    package var body: some View {
        Plate(title, width: 460, close: close) {
            VStack(alignment: .leading, spacing: 14) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        card(rows)
                    }
                }
                .frame(maxHeight: 470)
                .fixedSize(horizontal: false, vertical: true)
            }
        } foot: {
            HStack {
                Button(action: notes) {
                    Text("Everything that's new…")
                        .font(.system(size: 12))
                        .foregroundStyle(Role.muted)
                }
                .buttonStyle(.plain)
                Spacer()
                Pill("Close", filled: true, action: close)
            }
        }
    }

    private func card(_ toggles: [(String, String, Binding<Bool>)]) -> some View {
        Card {
            ForEach(Array(toggles.enumerated()), id: \.offset) { index, toggle in
                if index > 0 { Rule() }
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(toggle.0)
                            .font(.system(size: 13))
                            .foregroundStyle(Role.ink)
                        Text(toggle.1)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Role.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Switch(on: toggle.2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
    }
}

/// What the About window holds: the app's icon, name and version, What's New,
/// its copyright and, under it, whatever it owes to others.
package struct AboutBox: View {
    let icon: Image
    let name: String
    let version: String
    let copyright: String
    var credit: String? = nil
    var whatsNew: (() -> Void)? = nil

    package init(
        icon: Image, name: String, version: String, copyright: String, credit: String? = nil,
        whatsNew: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.name = name
        self.version = version
        self.copyright = copyright
        self.credit = credit
        self.whatsNew = whatsNew
    }

    package var body: some View {
        VStack(spacing: 0) {
            icon
                .resizable()
                .frame(width: 72, height: 72)
                .padding(.bottom, 10)
            Text(verbatim: name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Role.ink)
            Text(verbatim: version)
                .font(.system(size: 11))
                .foregroundStyle(Role.muted)
                .textSelection(.enabled)
                .padding(.top, 3)
            if let whatsNew {
                Pill("What's New", action: whatsNew)
                    .padding(.top, 12)
            }
            Text(verbatim: copyright)
                .font(.system(size: 10.5))
                .foregroundStyle(Role.faint)
                .padding(.top, 16)
            if let credit {
                Text(verbatim: credit)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Role.faint)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 34)
        .padding(.bottom, 20)
        .padding(.horizontal, 28)
        .frame(width: 320)
        .background(Role.ground)
    }
}
