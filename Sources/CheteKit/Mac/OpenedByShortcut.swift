import AppKit
import SwiftUI
import os

extension View {
    /// Holds Chete's shortcut once this window is first on screen, as Chete starts, and lets the keys bring it in
    /// front of any app. One that cannot be held is logged.
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
            if let keys = ((try? Settings.read(in: Copies.folderOnThisMac)) ?? Settings()).shortcut,
                let why = Shortcut.chete.change(to: keys)
            {
                Logger(subsystem: "com.amansingh.chete", category: "Shortcut").error("Chete holds no shortcut: \(why)")
            }
        }
    }
}
