// Taken from Search at commit c92ea7c: its launcher's field and list (Launcher.swift, LauncherView) and Shake
// (Design.swift). Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only where this
// repository's rules require: Search's colours and motion are read from Look; the field's words are SwiftUI's,
// set as Search sets its AppKit field (15.5-point type in ink, the prompt in ink at 30%); the shiver is told
// whether motion is reduced, which Search reads from AppKit. The window that holds them is Shell's.
import SwiftUI

/// The field of the panel that stands over another app: what you type, on the
/// ground, rounded, its shadow deeper than over a page. It shivers when what
/// was typed is refused.
package struct LaunchField: View {
    @Binding var text: String
    let prompt: String
    /// How many times what was typed has been refused: each one shivers the field.
    let refusals: Int
    @Environment(\.motion) private var motion
    @State private var shake: CGFloat = 0
    @State private var refused: Bool

    package init(text: Binding<String>, prompt: String, refusals: Int, refused: Bool = false) {
        _text = text
        self.prompt = prompt
        self.refusals = refusals
        _refused = State(initialValue: refused)
    }

    package var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(prompt).font(.system(size: 15.5)).foregroundStyle(Role.ink.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15.5))
                .foregroundStyle(Role.ink)
        }
        .frame(height: 22)
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(Role.ground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    refused ? AnyShapeStyle(Color.red.opacity(0.35)) : AnyShapeStyle(Role.hairline), lineWidth: 1
                )
                .allowsHitTesting(false)
        )
        // Deeper than over a page: it stands over another app's window.
        .shadow(color: .black.opacity(0.16), radius: 24, y: 8)
        .modifier(Shake(travel: shake, reduced: motion.reduced))
        .onChange(of: refusals) { _, _ in
            shake = 0
            refused = true
            withAnimation(.easeOut(duration: 0.5)) { shake = 1 }
        }
        .onChange(of: text) { _, _ in
            withAnimation(motion.quick) { refused = false }
        }
    }
}

/// The list under the panel's field: what is offered, on the ground, rounded.
package struct LaunchList<Content: View>: View {
    @ViewBuilder let content: () -> Content

    package init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    package var body: some View {
        VStack(spacing: 0) { content() }
            .padding(6)
            .background(Role.ground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Role.hairline, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 20, y: 6)
            .transition(.scale(scale: 0.98, anchor: .top).combined(with: .opacity))
    }
}

/// Wrong address, said without a dialog: the field shivers and stops.
package struct Shake: GeometryEffect {
    var travel: CGFloat
    /// Reduce Motion: no shiver.
    var reduced = false

    package init(travel: CGFloat, reduced: Bool = false) {
        self.travel = travel
        self.reduced = reduced
    }

    package var animatableData: CGFloat {
        get { travel }
        set { travel = newValue }
    }

    package func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }

    /// How far across the field is. Three there-and-backs, tapering to nothing, so it settles rather than
    /// stopping mid-swing.
    var offset: CGFloat {
        guard !reduced else { return 0 }
        let decay = 1 - travel
        return sin(travel * .pi * 6) * 7 * decay
    }
}
