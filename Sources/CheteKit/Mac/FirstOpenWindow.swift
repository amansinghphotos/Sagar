import AppKit
import ApplicationServices
import Shell
import SwiftUI

/// The first-open pages in a window of their own, opened at launch over Chete's own window until they are
/// finished or skipped.
struct FirstOpenWindow: Scene {
    var body: some Scene {
        Window("Welcome to Chete", id: "first-open") {
            FirstOpenContent()
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(FirstOpen.isDue(in: Copies.folderOnThisMac) ? .presented : .suppressed)
    }
}

private struct FirstOpenContent: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        FirstOpenPages(
            allowed: Allowed.now, opensAtLogin: LoginItem.isOn,
            act: .onThisMac(folder: Copies.folderOnThisMac, keyName: Clips.keyName),
            finish: {
                try? FirstOpen.done(in: Copies.folderOnThisMac)
                // Chete's own window comes forward, or opens again if it was closed meanwhile.
                openWindow(id: "chete")
                dismissWindow(id: "first-open")
            }
        )
        .frame(width: FirstOpenPages.size.width, height: FirstOpenPages.size.height)
        .windowName("Welcome to Chete")
        // Chete has no Dock icon, so its window is brought in front of the app you were in.
        .onAppear { NSApplication.shared.activate() }
    }
}

extension Allowed {
    /// What macOS lets Chete do now. Finding out asks nothing.
    static func now() -> Allowed {
        Allowed(keepingCopies: NSPasteboard.general.accessBehavior == .alwaysAllow, pasting: AXIsProcessTrusted())
    }
}

extension FirstOpenActs {
    /// What the buttons do in Chete: ask macOS, choose a file, set Chete to open at login.
    static func onThisMac(folder: URL, keyName: String) -> FirstOpenActs {
        FirstOpenActs(
            allowKeeping: {
                // Chete is listed in System Settings only once macOS has asked about it. Reading what was
                // copied makes macOS ask, then the pane opens where Always Allow can be chosen.
                if NSPasteboard.general.accessBehavior == .default {
                    _ = NSPasteboard.general.string(forType: .string)
                }
                PrivacyPane.pasteFromOtherApps.open()
            },
            allowPasting: {
                // macOS's own question, which lists Chete under Accessibility and offers to open the pane.
                _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
            },
            bringBack: {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.json]
                panel.message = "Choose a history you exported from Chete."
                guard panel.runModal() == .OK, let file = panel.url else { return nil }
                return (try? FirstOpen.bringBack(from: file, into: folder, keyName: keyName))
                    ?? "That file is not a history from Chete."
            },
            openAtLogin: { on in try? LoginItem.set(on) })
    }
}
