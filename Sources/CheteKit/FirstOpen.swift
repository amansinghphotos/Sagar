import Foundation
import Keep
import Look
import SwiftUI

/// Chete's first open on a Mac: three pages, shown once, until they are finished or skipped.
nonisolated package enum FirstOpen {
    /// True until the first open was finished or skipped in this folder.
    package static func isDue(in folder: URL) -> Bool {
        (try? Store(folder: folder).read(Bool.self, named: "First Open")) != true
    }

    /// Notes that the first open is over, so it is never shown again on this Mac.
    package static func done(in folder: URL) throws {
        try Store(folder: folder).write(true, named: "First Open")
    }

    /// Brings back an exported history in place of what is here, and says what came back.
    /// A file that is not a history changes nothing.
    package static func bringBack(from file: URL, into folder: URL, keyName: String) throws -> String {
        let history = try History.bringBack(from: file)
        try history.replace(in: folder, keyName: keyName)
        return history.clips.count == 1 ? "1 clip brought back." : "\(history.clips.count) clips brought back."
    }
}

/// What macOS lets Chete do so far.
package struct Allowed: Equatable, Sendable {
    /// Paste from Other Apps: keeping each copy without macOS asking first.
    package var keepingCopies: Bool
    /// Accessibility: pasting into the app you were in.
    package var pasting: Bool

    package init(keepingCopies: Bool, pasting: Bool) {
        self.keepingCopies = keepingCopies
        self.pasting = pasting
    }
}

/// What the buttons on the first-open pages do. Chete's own are in its Mac folder; a test brings ones that do nothing.
package struct FirstOpenActs {
    let allowKeeping: () -> Void
    let allowPasting: () -> Void
    /// Asks for an exported file and brings it back, and says what came of it, or nil if none was chosen.
    let bringBack: () -> String?
    let openAtLogin: (Bool) -> Void

    package init(
        allowKeeping: @escaping () -> Void, allowPasting: @escaping () -> Void, bringBack: @escaping () -> String?,
        openAtLogin: @escaping (Bool) -> Void
    ) {
        self.allowKeeping = allowKeeping
        self.allowPasting = allowPasting
        self.bringBack = bringBack
        self.openAtLogin = openAtLogin
    }
}

/// The pages: what Chete does, the two things macOS must allow, and making it yours.
package struct FirstOpenPages: View {
    /// The window's size, which does not change: the pages are as wide as Search's welcome.
    package static let size = CGSize(width: WindowSize.narrow.width, height: 480)

    let startPage: Int
    let allowed: () -> Allowed
    let act: FirstOpenActs
    let finish: () -> Void
    @State private var now: Allowed
    @State private var opensAtLogin: Bool
    @State private var broughtBack: String?
    @Environment(\.controlActiveState) private var active

    package init(
        startPage: Int = 0, allowed: @escaping () -> Allowed, opensAtLogin: Bool, act: FirstOpenActs,
        finish: @escaping () -> Void
    ) {
        self.startPage = startPage
        self.allowed = allowed
        self.act = act
        self.finish = finish
        _now = State(initialValue: allowed())
        _opensAtLogin = State(initialValue: opensAtLogin)
    }

    package var body: some View {
        Welcome(pages: 3, last: "Start", startPage: startPage, finish: finish) { page in
            switch page {
            case 0:
                WelcomeHeading(
                    "Chete keeps what you copy.",
                    "Later, in any app, press one key and type a few letters of what you want. Return pastes it where you were, and nothing leaves this Mac."
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            case 1:
                VStack(alignment: .leading, spacing: Space.wide.rawValue + Space.near.rawValue) {
                    WelcomeHeading(
                        "Two things to allow.",
                        "Each turns on once you allow it in System Settings. macOS asks only once.")
                    card {
                        Look.Choice(
                            "Keep what you copy", "In Paste from Other Apps, so each copy is kept without a question.",
                            on: asking(now.keepingCopies, act.allowKeeping), plain: true)
                        Rule(inset: 0)
                        Look.Choice(
                            "Paste for you", "In Accessibility, so Chete can paste into the app you were in.",
                            on: asking(now.pasting, act.allowPasting), plain: true)
                    }
                }
            default:
                VStack(alignment: .leading, spacing: Space.wide.rawValue + Space.near.rawValue) {
                    WelcomeHeading(
                        "Make it yours.", "Choose when Chete opens, and bring back a history from another Mac.")
                    card {
                        Look.Choice(
                            "Open at login", "Chete waits in the menu bar from the moment you log in.",
                            on: $opensAtLogin, plain: true)
                        Rule(inset: 0)
                        HStack(spacing: Space.apart.rawValue) {
                            VStack(alignment: .leading, spacing: Space.hair.rawValue) {
                                Text("Bring back a history").type(.body).foregroundStyle(Role.ink)
                                Text(broughtBack ?? "A file you exported from Chete. It replaces what is here now.")
                                    .type(.detail).foregroundStyle(Role.muted)
                            }
                            Spacer()
                            Pill("Choose File…", filled: true) { broughtBack = act.bringBack() ?? broughtBack }
                        }
                    }
                }
            }
        }
        .onChange(of: opensAtLogin) { _, on in act.openAtLogin(on) }
        // Coming back from System Settings, what was allowed there shows here.
        .onChange(of: active) { _, _ in now = allowed() }
    }

    /// A switch that is on once macOS allows a thing. Turning it on asks; it cannot be taken back from here.
    private func asking(_ allowed: Bool, _ ask: @escaping () -> Void) -> Binding<Bool> {
        Binding(get: { allowed }, set: { on in if on { ask() } })
    }

    /// Rows in a filled card, as Search's welcome has them.
    private func card(@ViewBuilder _ rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Space.wide.rawValue, content: rows)
            .padding(.horizontal, Space.page.rawValue)
            .padding(.vertical, Space.wide.rawValue)
            .background(Role.wash, in: RoundedRectangle(cornerRadius: Radius.card.rawValue, style: .continuous))
    }
}
