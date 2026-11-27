import AppKit
import ApplicationServices

/// What a person allows an app in System Settings, under Privacy & Security.
package enum Permission: CaseIterable, Sendable {
    /// Paste from Other Apps: the app reads what you copy without macOS asking each time.
    case pasteFromOtherApps
    /// Accessibility: the app can press keys for you, as pasting needs.
    case accessibility

    /// Whether it is given, read without asking anything.
    @MainActor package var isGiven: Bool {
        switch self {
        case .pasteFromOtherApps: NSPasteboard.general.accessBehavior == .alwaysAllow
        case .accessibility: AXIsProcessTrusted()
        }
    }

    /// Where System Settings shows it.
    package var place: URL? {
        let pane =
            switch self {
            case .pasteFromOtherApps: "Privacy_Pasteboard"
            case .accessibility: "Privacy_Accessibility"
            }
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")
    }

    /// Opens System Settings there. Only the person can turn it on.
    @MainActor package func openSettings() {
        if let place { NSWorkspace.shared.open(place) }
    }
}
