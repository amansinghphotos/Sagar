import AppKit
import SwiftUI
import Testing

@testable import Shell

/// SwiftUI puts a window's content in a group of its own, which VoiceOver can only call "group".
@Test func aNamedScreenNamesTheGroupThatHoldsItsWindow() throws {
    _ = NSApplication.shared
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 400, height: 300), styleMask: [.titled], backing: .buffered,
        defer: false)
    window.isReleasedWhenClosed = false
    let host = NSHostingView(rootView: Text("Words").windowName("Your clips"))
    window.contentView = host
    host.layoutSubtreeIfNeeded()
    #expect(host.accessibilityLabel() == "Your clips")
}
