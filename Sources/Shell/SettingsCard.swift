import AppKit
import SwiftUI

/// While a person turns a switch on in System Settings, the app's window steps aside and this small card
/// stays in front of System Settings, holding the view the app gives it. It never takes the keyboard, and
/// can be dragged out of the way. It sits by the screen, not by System Settings' window, which an app is
/// not told the place of in any way Apple documents for this.
@MainActor
package final class SettingsCard {
    let panel: NSPanel
    private weak var welcome: NSWindow?

    package init(steppingAside welcome: NSWindow?, @ViewBuilder _ content: () -> some View) {
        self.welcome = welcome
        let host = NSHostingView(rootView: content())
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: host.fittingSize), styleMask: [.nonactivatingPanel],
            backing: .buffered, defer: true)
        panel.contentView = host
        panel.isFloatingPanel = true  // above every app's ordinary windows
        panel.hidesOnDeactivate = false  // a panel hides once System Settings is in front, unless told not to
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
    }

    /// Once System Settings is open: the app's window steps aside, and the card comes up at the side of
    /// the screen that window was on.
    package func show() {
        let screen = welcome?.screen ?? NSScreen.main
        welcome?.orderOut(nil)
        if let visible = screen?.visibleFrame { panel.setFrameOrigin(Self.place(panel.frame.size, on: visible)) }
        panel.orderFrontRegardless()
    }

    /// The card leaves, and the app's window comes back in front, so the person carries on there.
    package func switchIsOn() {
        panel.close()
        guard let welcome else { return }
        NSApp.activate()
        welcome.makeKeyAndOrderFront(nil)
    }

    /// Where a card of this size sits on a screen's free part: at its right, a little in from the edge, halfway
    /// up, on whole points.
    static func place(_ size: CGSize, on visible: CGRect) -> CGPoint {
        CGPoint(
            x: visible.maxX - edge - size.width, y: visible.minY + ((visible.height - size.height) / 2).rounded(.down))
    }

    private static let edge: CGFloat = 20
}
