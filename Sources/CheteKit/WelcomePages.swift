import Look
import SwiftUI

/// The pages of Chete's welcome, in the order a person meets them.
package enum WelcomePage: String, CaseIterable, Codable, Sendable {
    case greeting, shortcut, keeping, pasting, oldClips, last
}

/// What the Mac already gives Chete, and what the person has chosen, when the welcome opens.
package struct WelcomeGiven: Equatable, Sendable {
    /// The shortcuts the welcome suggests, the earlier Chete's first, each in words, with how it sits under the hand.
    package static let presets = [
        (KeyCombo("c", shift: true), "Shift-Command-C", "Like Copy, with Shift held as well."),
        (KeyCombo("v", control: true), "Control-Command-V", "Like Paste, with Control held as well."),
        (KeyCombo("c", control: true), "Control-Command-C", "Like Copy, with Control held as well."),
    ]
    package static var suggestions: [KeyCombo] { presets.map(\.0) }

    package var shortcut = suggestions[0]
    /// The suggestions macOS already uses on this Mac, which are shown as taken and cannot be chosen.
    package var taken: Set<KeyCombo> = []

    /// Marks the presets macOS uses as taken, and starts on the shortcut kept, or else the first free one.
    package mutating func start(kept: KeyCombo?, taken: Set<KeyCombo>) {
        self.taken = taken
        shortcut = ([kept].compactMap(\.self) + Self.suggestions).first { !taken.contains($0) } ?? shortcut
    }

    /// Chooses a suggestion, unless it is taken.
    package mutating func choose(_ keys: KeyCombo) {
        if !taken.contains(keys) { shortcut = keys }
    }

    package var keeping = false
    package var pasting = false
    /// Whether this Mac has clips the earlier Chete kept, which the welcome offers to bring in.
    package var hasOldClips = false
    /// Whether macOS asks about keeping what is copied on this Mac. Where it does not, the welcome leaves that page out.
    package var asksKeeping = true
    /// What came in from the earlier Chete, in words, once it has.
    package var broughtIn: String?
    package var opensAtLogin = false
}

/// What the welcome's switches and buttons do. A picture is given ones that do nothing.
package struct WelcomeActs {
    /// Opens System Settings where Chete is allowed to keep what is copied.
    package var allowKeeping: () -> Void
    /// Opens System Settings where Chete is allowed to paste.
    package var allowPasting: () -> Void
    /// Brings in the earlier Chete's clips, for which macOS asks for the password once, and says what came in.
    package var bringInOldClips: () -> String?
    package var openAtLogin: (Bool) -> Void
    /// Lets the person choose an exported file, and says what came back, or nothing if they chose none.
    package var bringBack: () -> String?
}

/// Chete's welcome. Everything Chete will ever ask is asked here, so nothing asks once it is done.
package struct WelcomePages: View {
    private let startPage: WelcomePage
    private let act: WelcomeActs
    private let finish: () -> Void
    /// Held by whoever shows the welcome: what the Mac allows shows here live, and the shortcut is theirs to keep.
    @Binding private var given: WelcomeGiven
    @State private var broughtBack: String?

    package init(
        startPage: WelcomePage = .greeting, given: Binding<WelcomeGiven>, act: WelcomeActs,
        finish: @escaping () -> Void
    ) {
        (self.startPage, self.act, self.finish) = (startPage, act, finish)
        _given = given
    }

    /// The pages a person meets. The one for old clips is there only on a Mac that has some, and the one for
    /// keeping what is copied only where macOS asks about it.
    package static func pages(for given: WelcomeGiven) -> [WelcomePage] {
        WelcomePage.allCases.filter {
            ($0 != .oldClips || given.hasOldClips) && ($0 != .keeping || given.asksKeeping)
        }
    }

    package var body: some View {
        let pages = Self.pages(for: given)
        Welcome(pages: pages.count, last: "Start", startPage: pages.firstIndex(of: startPage) ?? 0, finish: finish) {
            switch pages[$0] {
            case .greeting: greeting
            case .shortcut: shortcut
            case .keeping:
                step(
                    "Let Chete keep what you copy.",
                    "Chete saves each thing you copy. You allow that once, in System Settings.",
                    ask: allow, done: given.keeping ? ("Allowed", "Chete keeps what you copy.") : nil,
                    act: act.allowKeeping)
            case .pasting:
                step(
                    "Let Chete paste for you.",
                    "Pick a clip, and Chete pastes it for you. You allow that once, in System Settings.",
                    ask: allow, done: given.pasting ? ("Allowed", "Chete pastes it where you were.") : nil,
                    act: act.allowPasting)
            case .oldClips:
                step(
                    "Bring in your old clips.",
                    "Chete found your older clips. Your Mac asks for your password once.",
                    ask: ("Bring them in", "Choose Always Allow when your Mac asks.", "Bring In Clips"),
                    done: given.broughtIn.map { ("Brought in", $0) },
                    act: { given.broughtIn = act.bringInOldClips() ?? given.broughtIn })
            case .last: last
            }
        }
        .onChange(of: given.opensAtLogin) { _, on in act.openAtLogin(on) }
    }

    /// The greeting in Gurmukhi leads as the hero, with the same in English under it. Then Chete's name on a
    /// soft chip, like its card in the menu bar, with its Gurmukhi and what it means, and how to open it.
    private var greeting: some View {
        VStack(alignment: .leading, spacing: Space.page.rawValue + Space.near.rawValue) {
            VStack(alignment: .leading, spacing: Space.tight.rawValue) {
                // VoiceOver reads the English under it, which says the same.
                Text("ਜੀ ਆਇਆਂ ਨੂੰ").type(.hero).foregroundStyle(Role.ink).accessibilityHidden(true)
                Text("Welcome to Chete.").type(.display).foregroundStyle(Role.muted)
            }
            HStack(spacing: Space.near.rawValue) {
                Image(systemName: "list.clipboard").type(.title).foregroundStyle(Role.ink).accessibilityHidden(true)
                Text("Chete").type(.title).foregroundStyle(Role.ink)
                Text("ਚੇਤੇ").type(.title).foregroundStyle(Role.muted)
                Text("remembered").type(.detail).foregroundStyle(Role.muted)
            }
            .padding(.horizontal, Space.wide.rawValue).padding(.vertical, Space.near.rawValue)
            .background(Role.wash, in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Chete means remembered")
            Text("It keeps what you copy, and lives in the menu bar.\nA shortcut opens it quicker.")
                .type(.body).lineSpacing(Space.tight.rawValue).foregroundStyle(Role.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The three suggestions, one to a row: its keys in words, how it sits under the hand, and a tick on the
    /// one chosen. One that macOS already uses is shown as taken and takes no click.
    private var shortcut: some View {
        VStack(alignment: .leading, spacing: Space.wide.rawValue + Space.near.rawValue) {
            WelcomeHeading("Choose your shortcut.", "Press it in any app, and Chete opens.")
            rows {
                ForEach(Array(WelcomeGiven.presets.enumerated()), id: \.offset) { place, preset in
                    let (keys, name, hint) = preset
                    let taken = given.taken.contains(keys)
                    if place > 0 { Rule(inset: 0) }
                    Button {
                        given.choose(keys)
                    } label: {
                        offer(name, taken ? "macOS already uses this one." : hint) {
                            Image(systemName: given.shortcut == keys ? "checkmark.circle.fill" : "circle")
                                .type(.title).foregroundStyle(given.shortcut == keys ? Role.ink : Role.faint)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).disabled(taken).opacity(taken ? 0.5 : 1)
                    .accessibilityAddTraits(given.shortcut == keys ? .isSelected : [])
                }
            }
        }
    }

    /// A page for one thing macOS asks about: why, what the Mac will show, and the button that starts it.
    /// Once it is done, the row says so in the button's place.
    private func step(
        _ title: String, _ line: String, ask: (row: String, detail: String, button: String),
        done: (row: String, detail: String)?, act: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Space.wide.rawValue + Space.near.rawValue) {
            WelcomeHeading(title, line)
            rows {
                if let done {
                    offer(done.row, done.detail) {
                        Image(systemName: "checkmark").type(.title).foregroundStyle(Role.ink)
                    }
                } else {
                    offer(ask.row, ask.detail) { Pill(ask.button, filled: true, action: act) }
                }
            }
        }
    }

    /// What both pages that open System Settings say on their row, word for word alike.
    private var allow: (row: String, detail: String, button: String) {
        ("Allow Chete", "Your Mac may ask first. Then a small card shows where to click.", "Open System Settings")
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
    /// For keeping what is copied. macOS gives each app a menu there: Ask, Allow or Deny.
    package static let keeping = WelcomeCard(
        place: "Paste from Other Apps", menu: "Allow",
        how: "Choose Allow in its menu. Chete only reads what you copy.")
    /// For pasting. macOS gives each app a switch there. macOS 27 names the place Device Control and Data Access;
    /// earlier versions called it Accessibility.
    package static let pasting = WelcomeCard(
        place: "Device Control and Data Access", menu: nil,
        how: "Turn its switch on. Chete only uses it to paste.")

    /// The section of Privacy & Security, in Apple's own words for it.
    let place: String
    /// The word to choose on the row's menu, or nothing where the row has a switch.
    let menu: String?
    /// The one line that differs: what macOS shows there, and that Chete does no more with it.
    let how: String

    package var body: some View {
        VStack(alignment: .leading, spacing: Space.apart.rawValue) {
            VStack(alignment: .leading, spacing: Space.hair.rawValue) {
                Text("Find Chete, and allow it.").type(.heading).foregroundStyle(Role.ink)
                Text("In Privacy & Security, under:").type(.detail).foregroundStyle(Role.muted)
                Text(place).type(.body).foregroundStyle(Role.ink)
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
            Text(how).type(.detail).foregroundStyle(Role.muted)
        }
        .padding(Space.page.rawValue)
        .frame(width: WelcomeSize.card.width, height: WelcomeSize.card.height, alignment: .topLeading)
        .background(Role.ground)
    }
}
