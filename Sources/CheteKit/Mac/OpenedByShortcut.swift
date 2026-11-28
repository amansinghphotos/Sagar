import AppKit
import SwiftUI

extension View {
    /// Lets Chete's shortcut open this window, once it is on screen, and bring Chete in front of any app.
    func openedByShortcut() -> some View {
        modifier(OpenedByShortcut())
    }
}

private struct OpenedByShortcut: ViewModifier {
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content.onAppear {
            Shortcut.chete.pressed = {
                openWindow(id: "chete")
                NSApplication.shared.activate()
            }
        }
    }
}
