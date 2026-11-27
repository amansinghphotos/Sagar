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

    /// The lines to show now, if this build opens for the first time and has any. Each build is remembered as
    /// seen either way, so a card is never owed later.
    static func due(_ info: [String: Any], _ settings: UserDefaults) -> [Line]? {
        let new = NewBuild(settings).isNew(info["CFBundleVersion"] as? String ?? "")
        let lines = lines(in: info)
        return new && !lines.isEmpty ? lines : nil
    }

    /// Shows the app's card for what is new, if it is owed. The card is handed the build's version, its lines, and
    /// what closes it.
    package static func showIfNew(
        @ViewBuilder _ card: (_ version: String, _ lines: [Line], _ close: @escaping () -> Void) -> some View
    ) {
        let info = Bundle.main.infoDictionary ?? [:]
        guard window == nil, let lines = due(info, .standard) else { return }
        let panel = NSPanel(contentRect: .zero, styleMask: [.nonactivatingPanel], backing: .buffered, defer: true)
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        let host = NSHostingView(rootView: card(version, lines) { [weak panel] in panel?.close() })
        panel.contentView = host
        panel.setContentSize(host.fittingSize)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false  // a panel hides while its app is not the active one, unless told not to
        panel.becomesKeyOnlyIfNeeded = true
        panel.center()
        window = panel
        NotificationCenter.default.addObserver(
            Closer.shared, selector: #selector(Closer.closed), name: NSWindow.willCloseNotification, object: panel)
        panel.orderFrontRegardless()  // in front, though the app was opened behind: the keyboard stays where it was
    }

    /// The card's window, while it is up.
    private static var window: NSPanel?

    /// Lets the card's window go once it closes.
    private final class Closer: NSObject {
        static let shared = Closer()
        @objc func closed() {
            MainActor.assumeIsolated {
                NotificationCenter.default.removeObserver(self)
                WhatIsNew.window = nil
            }
        }
    }
}
