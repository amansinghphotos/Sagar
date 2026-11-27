import AppKit
import SwiftUI
import Testing

@testable import Shell

// Screens as Apple sells them, in points, with a made-up menu bar of 37 points and Dock of 64.
// The card is never shown here: that would put a window on this Mac. The welcome's tour shows it.

@Test(arguments: [
    // A 13-inch MacBook Air, the Dock along the bottom.
    (CGRect(x: 0, y: 64, width: 1470, height: 855), CGPoint(x: 1150, y: 401)),
    // A 14-inch MacBook Pro, the Dock on the right.
    (CGRect(x: 0, y: 0, width: 1448, height: 945), CGPoint(x: 1128, y: 382)),
    // A 27-inch Studio Display to the left of the main screen, with no Dock on it.
    (CGRect(x: -2560, y: 0, width: 2560, height: 1415), CGPoint(x: -320, y: 617)),
])
func theCardSitsAtTheRightOfTheScreenHalfwayUp(screen: CGRect, place: CGPoint) {
    #expect(SettingsCard.place(CGSize(width: 300, height: 180), on: screen) == place)
}

@Test @MainActor func theCardHoldsTheViewTheAppGivesIt() {
    _ = NSApplication.shared
    let card = SettingsCard(steppingAside: nil) { Color.clear.frame(width: 300, height: 180) }
    #expect(card.panel.contentLayoutRect.size == CGSize(width: 300, height: 180))
}

/// It floats above other apps' windows, stays when System Settings is in front, and never takes the keys.
@Test @MainActor func theCardStaysInFrontWithoutTakingTheKeyboard() {
    _ = NSApplication.shared
    let panel = SettingsCard(steppingAside: nil) { Text("Accessibility") }.panel
    #expect(panel.level == .floating)
    #expect(!panel.hidesOnDeactivate)
    #expect(panel.styleMask.contains(.nonactivatingPanel))
    #expect(panel.becomesKeyOnlyIfNeeded)
    #expect(panel.collectionBehavior.contains(.canJoinAllSpaces))
}

@Test @MainActor func theCardLeavesWhenTheSwitchIsOn() {
    _ = NSApplication.shared
    let card = SettingsCard(steppingAside: nil) { Text("Accessibility") }
    let watch = Watch()
    NotificationCenter.default.addObserver(
        watch, selector: #selector(Watch.closing), name: NSWindow.willCloseNotification, object: card.panel)
    defer { NotificationCenter.default.removeObserver(watch) }
    card.switchIsOn()
    #expect(watch.closed)
}

/// Told when a window closes. AppKit tells it on the main thread, as it closes.
@MainActor private final class Watch: NSObject {
    var closed = false
    @objc func closing() { closed = true }
}
