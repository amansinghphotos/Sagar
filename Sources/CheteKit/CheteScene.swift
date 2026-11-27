import Look
import Shell
import SwiftUI
import os

/// Chete's one window, which its Main.swift opens: the clips you copied, to find and pick.
public struct CheteScene: Scene {
    /// The scene, ready for the app to open. Chete starts keeping what you copy as it opens.
    public init() {
        Self.startWatching()
    }

    /// One window, with Check for Updates… in the app's menu.
    public var body: some Scene {
        SwiftUI.Settings { CheteSettings() }.restorationBehavior(.disabled)
        Window("Chete", id: "chete") {
            ClipList(clips: Self.shelf.clips) { clip, plainText in
                _ = Pasting.paste(clip, plainText: plainText, mayPaste: false)
            }
            .frame(minWidth: WindowSize.narrow.width, minHeight: WindowSize.narrow.height)
            .windowName("Your clips")
        }
        .defaultSize(width: WindowSize.standard.width, height: WindowSize.standard.height)
        .commands { UpdateCommands() }
        MenuBarItem(app: "Chete", symbol: "list.clipboard") { CheteMenuCard(shelf: Self.shelf) }
    }

    /// The clips the window shows. Picking one copies it, until pasting for you comes with the panel.
    private static let shelf = Shelf()
    /// Watches what you copy for as long as Chete is open.
    private static var watcher: Watcher?
    private static var started = false

    /// Starts watching, once. The history is opened away from the screen, so opening Chete never waits for the keychain.
    private static func startWatching() {
        guard !started else { return }
        started = true
        Task {
            do {
                let copies = try await Task.detached { try Copies.onThisMac() }.value
                shelf.clips = try await copies.all()
                watcher = Watcher(copies: copies)
                watcher?.kept = { shelf.add($0) }
                watcher?.start()
                copies.trimDaily { shelf.remove($0) }
            } catch {
                Logger(subsystem: "com.amansingh.chete", category: "Copies").error("Chete keeps no copies: \(error)")
            }
        }
    }
}
