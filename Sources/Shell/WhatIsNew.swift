import AppKit
import SwiftUI

/// What is new in a build, shown once, the first time a new build opens: the lines its release's notes gave it,
/// on the card the app hands over, in a window of its own raised in front without taking the keyboard.
@MainActor
package enum WhatIsNew {
    /// One line of a build's notes: whether it is New, Better or Fixed, and what it says.
    package struct Line: Equatable, Sendable {
        package let kind: String
        package let line: String
    }

    /// The build's lines, in the order New, Better, Fixed, leaving out any it was made without.
    package static func lines(in info: [String: Any]) -> [Line] {
        [("New", "SagarNew"), ("Better", "SagarBetter"), ("Fixed", "SagarFixed")].compactMap { kind, key in
            guard let line = info[key] as? String, !line.isEmpty else { return nil }
            return Line(kind: kind, line: line)
        }
    }

    /// The lines to show now, if this build opens for the first time and has any. Each build's date stamp is kept in
    /// the app's own settings as seen either way, so a card is never owed later. An app's very first open is not news:
    /// that is the welcome's to greet. A mended build under the same number has a new date stamp, so it is new again.
    static func due(_ info: [String: Any], _ settings: UserDefaults) -> [Line]? {
        let build = info["CFBundleVersion"] as? String ?? ""
        let last = settings.string(forKey: lastBuildSeen)
        settings.set(build, forKey: lastBuildSeen)
        let lines = lines(in: info)
        return last != nil && last != build && !lines.isEmpty ? lines : nil
    }

    private static let lastBuildSeen = "Shell.LastBuildSeen"

    /// Shows the app's card for what is new, if it is owed. The card is handed the build's version, its lines, and
    /// what closes it.
    package static func showIfNew(
        @ViewBuilder _ card: (_ version: String, _ lines: [Line], _ close: @escaping () -> Void) -> some View
    ) {
        let info = Bundle.main.infoDictionary ?? [:]
        guard window == nil, let lines = due(info, .standard) else { return }
        let panel = CardPanel(contentRect: .zero, styleMask: [.nonactivatingPanel], backing: .buffered, defer: true)
        panel.closing = { [weak panel] in
            panel?.close()
            window = nil
        }
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        let host = NSHostingView(rootView: card(version, lines, panel.closing))
        panel.contentView = host
        panel.setContentSize(host.fittingSize)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false  // a panel hides while its app is not the active one, unless told not to
        panel.level = .floating  // above the app's own window, which may open after it
        panel.center()
        window = panel
        panel.orderFrontRegardless()  // in front, though the app was opened behind: the keyboard stays where it was
    }

    private static var window: NSPanel?

    /// A window with no frame of its own, which takes the keyboard once clicked, so that Escape closes it.
    private final class CardPanel: NSPanel {
        var closing: () -> Void = {}
        override var canBecomeKey: Bool { true }  // a window with no title bar cannot, unless it says so
        override func cancelOperation(_ sender: Any?) { closing() }
    }
}
