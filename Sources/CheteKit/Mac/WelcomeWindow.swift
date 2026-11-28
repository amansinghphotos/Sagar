import AppKit
import Keep
import Look
import Shell
import SwiftUI

/// Chete's welcome in a window of its own, shown at launch until it is done on this Mac. Everything Chete will ever
/// ask is asked here, on his click: each permission, and the earlier Chete's key.
struct WelcomeWindow: Scene {
    var body: some Scene {
        Window("Welcome to Chete", id: "welcome") {
            WelcomeOnThisMac()
                .frame(width: WelcomeSize.window.width, height: WelcomeSize.window.height)
                .windowName("Welcome to Chete")
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(FirstOpen.isDue(in: Copies.folderOnThisMac) ? .presented : .suppressed)
    }
}

struct WelcomeOnThisMac: View {
    /// The page the welcome opens at: the greeting, or a step the menu-bar card sends him back to.
    static var opensAt = WelcomePage.greeting

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    /// What this Mac gives Chete, and what he has chosen, kept up to date while the welcome is open.
    @State private var given = Self.now()

    private let folder = Copies.folderOnThisMac

    var body: some View {
        WelcomePages(startPage: Self.opensAt, given: $given, act: acts(), finish: finish)
            .task {
                // Reads what macOS allows twice a second, asking nothing, so a page says Allowed by itself.
                while !Task.isCancelled {
                    given.keeping = Permission.pasteFromOtherApps.isGiven
                    given.pasting = Permission.accessibility.isGiven
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
    }

    /// What this Mac gives Chete already, asking nothing.
    private static func now() -> WelcomeGiven {
        WelcomeGiven(
            keeping: Permission.pasteFromOtherApps.isGiven, pasting: Permission.accessibility.isGiven,
            hasOldClips: AnotherAppsKey.isHere(named: "History Key"), opensAtLogin: LoginItem.isOn)
    }

    private func acts() -> WelcomeActs {
        WelcomeActs(
            allowKeeping: { allow(.pasteFromOtherApps, shown: .keeping) },
            allowPasting: { allow(.accessibility, shown: .pasting) },
            bringInOldClips: bringInOldClips,
            openAtLogin: { try? LoginItem.set($0) },
            bringBack: bringBack)
    }

    /// Asks first, so macOS lists Chete in the pane, then opens System Settings there with the card in front.
    /// The welcome comes back once the switch is on, or once System Settings is closed without it.
    private func allow(_ permission: Permission, shown: WelcomeCard) {
        switch permission {
        case .pasteFromOtherApps: _ = NSPasteboard.general.string(forType: .string)
        case .accessibility: _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        }
        guard !permission.isGiven else { return }
        let card = SettingsCard(steppingAside: NSApplication.shared.keyWindow) { shown }
        permission.openSettings()
        card.show()
        Task {
            var waited = 0
            let settings = "com.apple.systempreferences"
            while !permission.isGiven,
                !NSRunningApplication.runningApplications(withBundleIdentifier: settings).isEmpty || waited < 20
            {
                waited += 1
                try? await Task.sleep(for: .milliseconds(500))
            }
            card.switchIsOn()
        }
    }

    /// Asks for the earlier Chete's folder, then its key, "History Key", for which macOS asks his password once.
    private func bringInOldClips() -> String? {
        guard let chosen = chosen("Choose your old Chete folder.", folder: true) else { return nil }
        guard
            let came = try? EarlierChete(folder: chosen, key: AnotherAppsKey.read(named: "History Key")).bringIn(
                to: folder, keyName: Clips.keyName)
        else { return "That folder has no old clips Chete can open." }
        CheteScene.reread()
        return came.broughtIn == 1 ? "Brought in 1 clip." : "Brought in \(came.broughtIn) clips."
    }

    /// Asks for an exported file and brings it back.
    private func bringBack() -> String? {
        guard let file = chosen("Choose a file you exported from Chete.", folder: false) else { return nil }
        guard let said = try? FirstOpen.bringBack(from: file, into: folder, keyName: Clips.keyName)
        else { return "That file isn't one Chete exported." }
        CheteScene.reread()
        return said
    }

    /// A folder or an exported file he chooses, or nothing.
    private func chosen(_ message: String, folder: Bool) -> URL? {
        let panel = NSOpenPanel()
        (panel.canChooseFiles, panel.canChooseDirectories, panel.message) = (!folder, folder, message)
        if !folder { panel.allowedContentTypes = [.json] }
        return panel.runModal() == .OK ? panel.url : nil
    }

    /// Notes what was skipped, so it waits in Settings, and shows Chete.
    private func finish() {
        if !Permission.pasteFromOtherApps.isGiven { try? FirstOpen.skip(.keeping, in: folder) }
        if !Permission.accessibility.isGiven { try? FirstOpen.skip(.pasting, in: folder) }
        try? FirstOpen.done(in: folder)
        openWindow(id: "chete")
        dismissWindow(id: "welcome")
    }
}
