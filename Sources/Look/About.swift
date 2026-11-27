// What is new in a version, as a panel of switches, and the About box with the app's icon, name and version.
import SwiftUI

/// A panel that tells what a version brings, each new thing with a switch to turn it on, and a way to read
/// everything that is new.
package struct NewCard: View {
    private let title: String
    private let rows: [(String, String, Binding<Bool>)]
    private let close: () -> Void
    private let notes: () -> Void

    /// How tall the list grows before it scrolls, so a long one never pushes the panel past the screen.
    private static let tallest: CGFloat = 470

    package init(
        title: String, rows: [(String, String, Binding<Bool>)],
        close: @escaping () -> Void, notes: @escaping () -> Void
    ) {
        (self.title, self.rows) = (title, rows)
        (self.close, self.notes) = (close, notes)
    }

    package var body: some View {
        Plate(title, width: 460, close: close) {
            ScrollView {
                Card {
                    ForEach(rows.indices, id: \.self) { index in
                        if index > 0 { Rule() }
                        row(rows[index])
                    }
                }
            }
            .frame(maxHeight: Self.tallest)
            .fixedSize(horizontal: false, vertical: true)
        } foot: {
            HStack {
                Button(action: notes) {
                    Text(verbatim: "Everything that's new…").type(.row).foregroundStyle(Role.muted)
                }
                .buttonStyle(.plain)
                Spacer()
                Pill("Close", filled: true, action: close)
            }
        }
    }

    /// One new thing: what it is, a line on how it works, and its switch.
    private func row(_ row: (String, String, Binding<Bool>)) -> some View {
        HStack(spacing: Space.page.rawValue) {
            VStack(alignment: .leading, spacing: 3) {
                Text(row.0).type(.body).foregroundStyle(Role.ink)
                Text(row.1).type(.detail).foregroundStyle(Role.muted).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Space.near.rawValue)
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
        icon: Image, name: String, version: String, copyright: String,
        credit: String? = nil, whatsNew: (() -> Void)? = nil
    ) {
        (self.icon, self.name, self.version) = (icon, name, version)
        (self.copyright, self.credit, self.whatsNew) = (copyright, credit, whatsNew)
    }

    package var body: some View {
        VStack(spacing: 0) {
            icon.resizable().frame(width: 72, height: 72)
            Text(name).type(.heading).foregroundStyle(Role.ink).padding(.top, Space.gap.rawValue)
            Text(version).font(.system(size: 11)).foregroundStyle(Role.muted).textSelection(.enabled).padding(.top, 3)
            if let whatsNew { Pill("What's New", action: whatsNew).padding(.top, Space.apart.rawValue) }
            Text(copyright).type(.small).foregroundStyle(Role.faint).padding(.top, Space.page.rawValue)
            if let credit {
                Text(credit).type(.small).foregroundStyle(Role.faint).multilineTextAlignment(.center)
                    .padding(.top, Space.tight.rawValue)
            }
        }
        .padding(EdgeInsets(top: 34, leading: 28, bottom: 20, trailing: 28))
        .frame(width: 320)
        .background(Role.ground)
    }
}
