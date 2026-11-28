import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's card for what is new and its About view, side by side, with made-up rows, name and version.
private struct Showcase: View {
    @State var a = true
    @State var b = false

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            NewCard(
                title: "New in Chete 1.1",
                rows: [
                    ("Paste as plain text", "Hold Shift as you pick.", $a),
                    ("Pictures too", "Copied pictures are kept.", $b),
                ],
                close: {}, notes: {})
            AboutBox(
                icon: Image(systemName: "doc.on.clipboard"), name: "Chete", version: "Version 1.1 (202611270600)",
                copyright: "© Sagar", whatsNew: {})
        }
        .padding(40)
        .frame(width: 920, height: 460)
        .background(Role.ground)
    }
}

@Test(arguments: [false, true])
func theCardAndAboutLookAsSearchsDo(dark: Bool) throws {
    try expectSearchPicture(of: Showcase(), width: 920, height: 460, named: "About", dark: dark)
}
