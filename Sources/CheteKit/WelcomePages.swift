import Look
import SwiftUI

/// The pages of Chete's welcome, in the order a person meets them.
package enum WelcomePage: String, CaseIterable, Sendable {
    case greeting, keeping, pasting, last
}

/// What the Mac already gives Chete, and what the person has chosen, when the welcome opens.
package struct WelcomeGiven: Equatable, Sendable {
    package var keeping = false
    package var pasting = false
    package var opensAtLogin = false
}

/// What the welcome's switches and buttons do. A picture is given ones that do nothing.
package struct WelcomeActs {
    /// Opens System Settings where Chete is allowed to keep what is copied.
    package var allowKeeping: () -> Void
    /// Opens System Settings where Chete is allowed to paste.
    package var allowPasting: () -> Void
    package var openAtLogin: (Bool) -> Void
    /// Lets the person choose an exported file, and says what came back, or nothing if they chose none.
    package var bringBack: () -> String?
}

/// Chete's welcome: a greeting, one page for each thing the Mac must allow, and a last page of offers.
package struct WelcomePages: View {
    /// The window's size, which does not change.
    package static let size = CGSize(width: WindowSize.narrow.width, height: 480)

    private let startPage: WelcomePage
    private let act: WelcomeActs
    private let finish: () -> Void
    @State private var given: WelcomeGiven
    @State private var broughtBack: String?

    package init(
        startPage: WelcomePage = .greeting, given: WelcomeGiven, act: WelcomeActs, finish: @escaping () -> Void
    ) {
        (self.startPage, self.act, self.finish) = (startPage, act, finish)
        _given = State(initialValue: given)
    }

    package var body: some View {
        let pages = WelcomePage.allCases
        Welcome(pages: pages.count, last: "Start", startPage: pages.firstIndex(of: startPage) ?? 0, finish: finish) {
            switch pages[$0] {
            case .greeting: greeting
            case .keeping:
                step(
                    "Let Chete keep what you copy.",
                    "Chete saves each thing you copy. Your Mac wants your OK first.",
                    done: "Chete keeps what you copy.", on: given.keeping, ask: act.allowKeeping)
            case .pasting:
                step(
                    "Let Chete paste for you.",
                    "Pick a clip, and Chete pastes it for you. Your Mac wants your OK first.",
                    done: "Chete pastes it where you were.", on: given.pasting, ask: act.allowPasting)
            case .last: last
            }
        }
        .onChange(of: given.opensAtLogin) { _, on in act.openAtLogin(on) }
    }

    /// The greeting in Gurmukhi, which leads, over the same in English, then what Chete is and how to open it.
    private var greeting: some View {
        VStack(alignment: .leading, spacing: Space.page.rawValue) {
            Image(systemName: "list.clipboard").type(.display).foregroundStyle(Role.ink).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Space.gap.rawValue) {
                // VoiceOver reads the English under it, which says the same.
                Text("ਜੀ ਆਇਆਂ ਨੂੰ").type(.display).foregroundStyle(Role.ink).accessibilityHidden(true)
                Text("Welcome to Chete.").type(.title).foregroundStyle(Role.ink)
            }
            Text(
                "Chete, ਚੇਤੇ, means remembered. It keeps what you copy.\nFind it in the menu bar, or open it quicker with a shortcut."
            )
            .type(.body).lineSpacing(Space.tight.rawValue).foregroundStyle(Role.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A page for one thing the Mac must allow: why, and a button that opens System Settings at its place.
    /// Once macOS allows it, the row says so in the button's place.
    private func step(
        _ title: String, _ line: String, done: String, on: Bool, ask: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Space.wide.rawValue + Space.near.rawValue) {
            WelcomeHeading(title, line)
            rows {
                if on {
                    offer("Allowed", done) { Image(systemName: "checkmark").type(.title).foregroundStyle(Role.ink) }
                } else {
                    offer("Allow it in System Settings", "A small card shows you where to click.") {
                        Pill("Open System Settings", filled: true, action: ask)
                    }
                }
            }
        }
    }

    private var last: some View {
        VStack(alignment: .leading, spacing: Space.wide.rawValue + Space.near.rawValue) {
            WelcomeHeading("You're ready.", "Two more things, if you like.")
            rows {
                Look.Choice("Open at login", "Chete starts when you log in.", on: $given.opensAtLogin, plain: true)
                Rule(inset: 0)
                offer("Bring back clips", broughtBack ?? "Have a file you exported? Your clips come back.") {
                    Pill("Choose File…") { broughtBack = act.bringBack() ?? broughtBack }
                }
            }
        }
    }

    /// A row that offers one thing: what it is, a line about it, and what to press at its end.
    private func offer(_ title: String, _ detail: String, @ViewBuilder end: () -> some View) -> some View {
        HStack(spacing: Space.apart.rawValue) {
            VStack(alignment: .leading, spacing: Space.hair.rawValue) {
                Text(title).type(.body).foregroundStyle(Role.ink)
                Text(detail).type(.detail).foregroundStyle(Role.muted)
            }
            Spacer()
            end()
        }
    }
}

/// Rows on a soft filled ground, as the welcome and its card both lay them.
@MainActor private func rows(@ViewBuilder _ content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: Space.wide.rawValue, content: content)
        .padding(.horizontal, Space.page.rawValue)
        .padding(.vertical, Space.wide.rawValue)
        .background(Role.wash, in: RoundedRectangle(cornerRadius: Radius.card.rawValue, style: .continuous))
}

/// The small card that stays in front of System Settings: where to go there, and what to look for.
package struct WelcomeCard: View, Sendable {
    package static let size = CGSize(width: 340, height: 150)
    /// For keeping what is copied: Chete's row there has a menu, and Allow is the one to choose.
    package static let keeping = WelcomeCard(
        name: "keeping", ask: "Choose Allow for Chete.", place: "Privacy & Security, then Paste from Other Apps.",
        menu: "Allow")
    /// For pasting: Chete's row there has a switch.
    package static let pasting = WelcomeCard(
        name: "pasting", ask: "Turn on Chete.", place: "Privacy & Security, then Accessibility.", menu: nil)

    package let name: String
    let ask: String
    let place: String
    /// The word to choose on the row's menu, or nothing where the row has a switch.
    let menu: String?

    package var body: some View {
        VStack(alignment: .leading, spacing: Space.apart.rawValue) {
            VStack(alignment: .leading, spacing: Space.hair.rawValue) {
                Text(ask).type(.heading).foregroundStyle(Role.ink)
                Text(place).type(.detail).foregroundStyle(Role.muted)
            }
            rows {
                // A picture of the row to look for. It is not the real one, so it takes no clicks.
                HStack(spacing: Space.near.rawValue) {
                    Image(systemName: "list.clipboard").foregroundStyle(Role.ink)
                    Text("Chete").type(.body).foregroundStyle(Role.ink)
                    Spacer()
                    // The ring marks the one thing to click.
                    Group {
                        if let menu {
                            Text("\(menu) \(Image(systemName: "chevron.up.chevron.down"))").type(.label)
                                .foregroundStyle(Role.ink)
                        } else {
                            Switch(on: .constant(true))
                        }
                    }
                    .padding(.horizontal, Space.gap.rawValue).padding(.vertical, Space.snug.rawValue)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.row.rawValue, style: .continuous).strokeBorder(Role.ink)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            Text("Once that's done, Chete moves on by itself.").type(.detail).foregroundStyle(Role.muted)
        }
        .padding(Space.page.rawValue)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .background(Role.ground)
    }
}
