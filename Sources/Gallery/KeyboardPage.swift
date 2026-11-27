import Look
import SwiftUI

/// The Keyboard page: the drawn keyboard at rest with a shortcut chosen, with keys held, and with a warning.
struct KeyboardPage: View {
    var body: some View {
        Grid(
            alignment: .topLeading, horizontalSpacing: Space.page.rawValue * 2, verticalSpacing: Space.page.rawValue * 2
        ) {
            GridRow {
                Keyboard(shortcut: KeyCombo("c", shift: true))
                Keyboard(shortcut: KeyCombo("c", shift: true), held: KeyCombo("", shift: true))
            }
            GridRow {
                Keyboard(
                    shortcut: KeyCombo("3", shift: true), warning: "Your Mac uses these keys for screenshots.")
            }
        }
        .padding(Space.page.rawValue * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
