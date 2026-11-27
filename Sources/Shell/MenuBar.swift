import AppKit
import SwiftUI

/// An app's item in the menu bar, for an app that lives there and has no Dock icon, and so shows no
/// menus of its own. Its menu opens the app's window over whatever app is in front, offers Check for
/// Updates…, and quits.
package struct MenuBarItem: Scene {
    let app: String
    let symbol: String
    let window: String

    /// The item for an app, drawn as an SF Symbol, whose Open item opens the window with that id.
    package init(app: String, symbol: String, window: String) {
        self.app = app
        self.symbol = symbol
        self.window = window
    }

    package var body: some Scene {
        MenuBarExtra(app, systemImage: symbol) {
            MenuBarMenu(app: app, window: window)
        }
    }
}

private struct MenuBarMenu: View {
    let app: String
    let window: String
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open \(app)") {
            openWindow(id: window)
            NSApplication.shared.activate()
        }
        Divider()
        Button("Check for Updates…") { Updates.shared?.check() }
            .disabled(Updates.shared == nil)
        Divider()
        Button("Quit \(app)") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
