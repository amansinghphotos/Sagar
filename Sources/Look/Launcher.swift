// The launcher: a large floating field to type into, the floating list of what it found, and the shiver of a refusal.
import SwiftUI

/// A large floating field. Each time `refusals` goes up, its edge turns red and it shivers; the red stays until
/// the person types again.
package struct LaunchField: View {
    @Environment(\.motion) private var motion
    @Binding private var text: String
    @State private var shake: CGFloat = 0
    @State private var refused: Bool
    private let prompt: String
    private let refusals: Int

    package init(text: Binding<String>, prompt: String, refusals: Int, refused: Bool = false) {
        _text = text
        _refused = State(initialValue: refused)
        self.prompt = prompt
        self.refusals = refusals
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.floating.rawValue, style: .continuous)
        TextField(text: $text, prompt: Text(verbatim: "")) { Text(prompt) }
            .textFieldStyle(.plain)
            .foregroundStyle(Role.ink)
            .background(alignment: .leading) {
                // The field itself carries the prompt for VoiceOver, so the drawn one is not read twice.
                if text.isEmpty { Text(prompt).foregroundStyle(Role.ink.opacity(0.3)).accessibilityHidden(true) }
            }
            .font(.system(size: 15.5))
            .padding(.horizontal, 22)
            .frame(height: 50)
            .background(shape.fill(Role.ground))
            .overlay(shape.strokeBorder(edge, lineWidth: 1).allowsHitTesting(false))
            .elevation(.floating)
            .modifier(Shake(travel: shake, reduced: motion.reduced))
            .onChange(of: refusals) { refuse() }
            .onChange(of: text) { withAnimation(motion.quick) { refused = false } }
    }

    /// The field's edge: a hairline, or the Mac's red, softened, while refused.
    private var edge: AnyShapeStyle {
        refused ? AnyShapeStyle(Color.red.opacity(0.35)) : AnyShapeStyle(Role.hairline)
    }

    /// Reddens the edge and shivers from the start.
    private func refuse() {
        shake = 0
        refused = true
        withAnimation(.easeOut(duration: 0.5)) { shake = 1 }
    }
}

/// The floating list under a launcher's field, which grows in from the field's edge when it appears.
package struct LaunchList<Content: View>: View {
    private let content: () -> Content

    package init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.floating.rawValue, style: .continuous)
        VStack(spacing: 0, content: content)
            .padding(Space.snug.rawValue)
            .background(shape.fill(Role.ground))
            .overlay(shape.strokeBorder(Role.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(0.14), radius: 20, y: 6)
            .transition(.scale(scale: 0.98, anchor: .top).combined(with: .opacity))
    }
}

/// A sideways shiver: as `travel` runs from 0 to 1, three swings there and back, each smaller than the last,
/// coming to rest at 1. Still under reduced motion.
package struct Shake: GeometryEffect {
    private var travel: CGFloat
    private let reduced: Bool

    package init(travel: CGFloat, reduced: Bool = false) {
        self.travel = travel
        self.reduced = reduced
    }

    package var animatableData: CGFloat {
        get { travel }
        set { travel = newValue }
    }

    /// How far sideways the shiver has the field now, in points.
    var offset: CGFloat {
        guard !reduced else { return 0 }
        let swing = Self.widest * (1 - travel)
        return swing * sin(travel * Self.swings * 2 * .pi)
    }

    package func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }

    /// The first swing's reach, in points, and how many there-and-backs the shiver makes.
    private static let widest: CGFloat = 6.9
    private static let swings: CGFloat = 3
}
