import Look
import SwiftUI

/// What the menu-bar card's buttons do. Chete's own are in its Mac folder; a test brings ones that do nothing.
package struct MenuCardActs {
    let copy: (Clip) -> Void
    let open: () -> Void
    let settings: () -> Void
    /// Nil when there is nothing to check for updates with, as in a build from Xcode: the button is then dimmed.
    let checkForUpdates: (() -> Void)?
    let quit: () -> Void
    /// Opens the welcome at the step that allows keeping what is copied.
    var allowKeeping: () -> Void = {}

    package init(
        copy: @escaping (Clip) -> Void, open: @escaping () -> Void, settings: @escaping () -> Void,
        checkForUpdates: (() -> Void)?,
        quit: @escaping () -> Void
    ) {
        self.copy = copy
        self.open = open
        self.settings = settings
        self.checkForUpdates = checkForUpdates
        self.quit = quit
    }
}

/// The card that drops from Chete's item in the menu bar: your newest clips, each copied again with a click,
/// then Chete's window, its settings, updates and quitting. Laid out as Search's panel: a title, its rows, and a foot
/// below a hairline.
package struct MenuCard: View {
    package static let width: CGFloat = 340
    /// How many of the newest clips it shows.
    package static let shown = 5

    let clips: [Clip]
    let now: Date
    let act: MenuCardActs
    /// The clip under the pointer as the card opens: none, but for a picture of one lit.
    let lit: Clip.ID?
    /// Whether macOS lets Chete keep what is copied. Until it does, Chete keeps nothing, and the card says so.
    let keeping: Bool

    package init(clips: [Clip], now: Date, lit: Clip.ID? = nil, keeping: Bool = true, act: MenuCardActs) {
        self.clips = clips
        self.now = now
        self.lit = lit
        self.keeping = keeping
        self.act = act
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Chete").type(.title).foregroundStyle(Role.ink)
                .padding(.horizontal, Space.page.rawValue)
                .padding(.top, Space.page.rawValue)
                .padding(.bottom, Space.apart.rawValue)
            if !keeping {
                HStack(spacing: Space.apart.rawValue) {
                    VStack(alignment: .leading, spacing: Space.hair.rawValue) {
                        Text("Chete keeps nothing yet.").type(.body).foregroundStyle(Role.ink)
                        Text("Allow it once to start.").type(.detail).foregroundStyle(Role.muted)
                    }
                    Spacer(minLength: 0)
                    Pill("Allow…", filled: true, action: act.allowKeeping)
                }
                .padding(.horizontal, Space.page.rawValue)
                .padding(.vertical, Space.apart.rawValue)
                .background(Role.wash, in: RoundedRectangle(cornerRadius: Radius.card.rawValue, style: .continuous))
                .padding(.horizontal, Space.snug.rawValue)
                .padding(.bottom, Space.near.rawValue)
            }
            if clips.isEmpty, keeping {
                Key("⌘ C", "Copy something. It shows up here.")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Space.page.rawValue * 2)
            } else {
                VStack(spacing: 0) {
                    ForEach(clips.prefix(Self.shown)) { clip in
                        RecentRow(row: Row(clip, now: now), under: clip.id == lit) { act.copy(clip) }
                    }
                }
                .padding(.horizontal, Space.snug.rawValue)
                .padding(.bottom, Space.snug.rawValue)
            }
            Rule(inset: 0)
            HStack(spacing: Space.tight.rawValue) {
                Pill("Open Chete", filled: true, action: act.open)
                Spacer(minLength: 0)
                Door(icon: "gearshape", help: "Settings…", act: act.settings).accessibilityLabel("Settings")
                Door(icon: "arrow.triangle.2.circlepath", help: "Check for Updates…") { act.checkForUpdates?() }
                    .disabled(act.checkForUpdates == nil)
                    .accessibilityLabel("Check for Updates")
                Door(icon: "power", help: "Quit Chete", act: act.quit).accessibilityLabel("Quit Chete")
            }
            .padding(.horizontal, Space.page.rawValue)
            .padding(.vertical, Space.wide.rawValue)
        }
        .frame(width: Self.width)
        .background(Role.ground)
    }
}

/// One of the newest clips: what it is, its first line and when, lit under the pointer with Copy beside it.
private struct RecentRow: View {
    @Environment(\.greys) private var greys
    let row: Row
    let copy: () -> Void
    @State private var under: Bool

    init(row: Row, under: Bool, copy: @escaping () -> Void) {
        self.row = row
        self.copy = copy
        _under = State(initialValue: under)
    }

    var body: some View {
        HStack(spacing: Space.near.rawValue) {
            Mark(icon: Image(systemName: row.symbol), template: true, letter: "")
            VStack(alignment: .leading, spacing: Space.hair.rawValue) {
                Text(row.title).type(.body).foregroundStyle(Role.ink)
                Text(row.detail).type(.detail).foregroundStyle(Role.muted)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
            if under { Quick("Copy", act: copy) }
        }
        .padding(.horizontal, Space.gap.rawValue)
        .padding(.vertical, Space.snug.rawValue)
        .background {
            if under { RoundedRectangle(cornerRadius: Radius.row.rawValue, style: .continuous).fill(greys.hover) }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: copy)
        .onHover { under = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.title)
        .accessibilityValue(row.detail)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { copy() }
    }
}
