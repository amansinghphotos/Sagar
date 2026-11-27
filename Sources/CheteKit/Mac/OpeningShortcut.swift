import AppKit
import Look
import Shell
import SwiftUI

/// The keys that open Chete from any app, held for as long as Chete runs.
@MainActor
final class OpeningShortcut {
    static let shared = OpeningShortcut()

    /// What a press does: brings Chete's window in front of whatever app is.
    var open: () -> Void = {}
    private var holding: HotKey?

    /// Holds these keys in place of any held before, or says why it cannot.
    @discardableResult
    func hold(_ shortcut: KeyCombo) -> HotKey.Refusal? {
        holding?.letGo()
        holding = nil
        guard let keys = shortcut.held else { return .macOSRefused(0) }
        do {
            holding = try HotKey(keys) { [weak self] in self?.open() }
            return nil
        } catch {
            return error
        }
    }
}

extension View {
    /// Lets the shortcut open Chete's window, once this view is on screen.
    func openedByShortcut() -> some View {
        modifier(OpenedByShortcut())
    }
}

private struct OpenedByShortcut: ViewModifier {
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content.onAppear {
            OpeningShortcut.shared.open = {
                openWindow(id: "chete")
                NSApplication.shared.activate()
            }
        }
    }
}
