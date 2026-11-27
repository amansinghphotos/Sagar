import Shell
import SwiftUI
import os

/// Chete's one window, which its Main.swift opens. What you copy will appear here.
public struct CheteScene: Scene {
    /// The scene, ready for the app to open. Chete starts keeping what you copy as it opens.
    public init() {
        Self.startWatching()
    }

    /// One window, with Check for Updates… in the app's menu.
    public var body: some Scene {
        Window("Chete", id: "chete") {
            Text("What You Copy Appears Here")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .windowName("Your clips")
        }
        .commands { UpdateCommands() }
        MenuBarItem(app: "Chete", symbol: "list.clipboard", window: "chete")
    }

    /// Watches what you copy for as long as Chete is open.
    private static var watcher: Watcher?
    private static var started = false

    /// Starts watching, once. The history is opened away from the screen, so opening Chete never waits for the keychain.
    private static func startWatching() {
        guard !started else { return }
        started = true
        Task {
            do {
                watcher = Watcher(copies: try await Task.detached { try Copies.onThisMac() }.value)
                watcher?.start()
            } catch {
                Logger(subsystem: "com.amansingh.chete", category: "Copies").error("Chete keeps no copies: \(error)")
            }
        }
    }
}
