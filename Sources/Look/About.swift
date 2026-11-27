// What is new in a version, as a panel of switches, and the About box with the app's icon, name and version.
import SwiftUI

/// A panel that tells what a version brings, each new thing with a switch to turn it on, and a way to read
/// everything that is new.
package struct NewCard: View {
    private let title: String
    private let rows: [(String, String, Binding<Bool>)]
    private let close: () -> Void
    private let notes: () -> Void

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
            // A long list scrolls rather than growing the panel past the screen.
            ScrollView {
                Card {
                    ForEach(rows.indices, id: \.self) { index in
                        if index > 0 { Rule() }
                        row(rows[index])
                    }
                }
            }
            .frame(maxHeight: 470)
            .fixedSize(horizontal: false, vertical: true)
        } foot: {
            HStack {
                Button(action: notes) {
                    Text(verbatim: "Everything that's new…").type(.row).foregroundStyle(Role.muted)
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                Pill("Close", filled: true, action: close)
            }
        }
    }

    /// One new thing: what it is, a line on how it works, and its switch.
    private func row(_ row: (String, String, Binding<Bool>)) -> some View {
        HStack(spacing: Space.apart.rawValue) {
            VStack(alignment: .leading, spacing: 3) {
                Text(row.0).type(.body).foregroundStyle(Role.ink)
                Text(row.1).type(.detail).foregroundStyle(Role.muted).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Switch(on: row.2)
        }
        .padding(.horizontal, Space.wide.rawValue)
        .padding(.vertical, Space.gap.rawValue)
    }
}

/// The About box: the app's icon, its name and version (which can be selected and copied), a button for what is
/// new when the app has notes to show, the copyright, and any credit it owes.
package struct AboutBox: View {
    private let icon: Image
    private let name: String
    private let version: String
    private let copyright: String
    private let credit: String?
    private let whatsNew: (() -> Void)?

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
            icon.resizable().frame(width: 72, height: 72).foregroundStyle(Role.ink)
            Text(name).type(.heading).foregroundStyle(Role.ink).padding(.top, Space.gap.rawValue)
            Text(version).font(.system(size: 11)).foregroundStyle(Role.muted).textSelection(.enabled).padding(.top, 3)
            if let whatsNew { Pill("What's New", action: whatsNew).padding(.top, Space.apart.rawValue) }
            Text(copyright).type(.small).foregroundStyle(Role.faint).padding(.top, Space.page.rawValue)
            if let credit {
                Text(credit).type(.small).foregroundStyle(Role.faint).multilineTextAlignment(.center)
                    .padding(.top, Space.tight.rawValue)
            }
        }
        .padding(.top, 34)
        .padding(.bottom, 20)
        .padding(.horizontal, 28)
        .frame(width: 320)
        .background(Role.ground)
    }
}
