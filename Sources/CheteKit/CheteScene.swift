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

    /// Its settings, one window, and its item in the menu bar, whose card holds Check for Updates.
    public var body: some Scene {
        SwiftUI.Settings { CheteSettings(changed: Self.reread) }.restorationBehavior(.disabled)
            .defaultLaunchBehavior(.suppressed)
        Window("Chete", id: "chete") {
            ClipList(clips: Self.shelf.clips) { clip, plainText in
                _ = Pasting.paste(clip, plainText: plainText, mayPaste: false)
            }
            .frame(minWidth: WindowSize.narrow.width, minHeight: WindowSize.narrow.height)
            .windowName("Your clips")
            .openedByShortcut()
        }
        .defaultSize(width: WindowSize.standard.width, height: WindowSize.standard.height)
        // Chete opens on its list, never on its settings, which SwiftUI otherwise may show first.
        .defaultLaunchBehavior(.presented)
        MenuBarItem(app: "Chete", symbol: "list.clipboard") { CheteMenuCard(shelf: Self.shelf) }
    }

    /// The clips the window shows. Picking one copies it, until pasting for you comes with the panel.
    private static let shelf = Shelf()
    /// Where what you copy is kept, once it is open.
    private static var copies: Copies?
    /// Watches what you copy for as long as Chete is open.
    private static var watcher: Watcher?
    private static var started = false

    /// Starts watching, once. The history is opened away from the screen, so opening Chete never waits for the keychain.
    private static func startWatching() {
        guard !started else { return }
        started = true
        let shortcut = ((try? Settings.read(in: Copies.folderOnThisMac)) ?? Settings()).shortcut
        if !OpeningShortcut.shared.hold(shortcut) {
            Logger(subsystem: "com.amansingh.chete", category: "Shortcut").error("Chete holds no shortcut")
        }
        Task {
            do {
                let copies = try await Task.detached { try Copies.atOpen() }.value
                shelf.clips = try await copies.all()
                Self.copies = copies
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

extension CheteScene {
    /// Shows what is kept now, after Settings deleted or brought back clips.
    fileprivate static func reread() {
        Task {
            guard let copies else { return }
            do {
                shelf.clips = try await copies.reread()
            } catch {
                Logger(subsystem: "com.amansingh.chete", category: "Copies").error("Chete could not reread: \(error)")
            }
        }
    }
}
