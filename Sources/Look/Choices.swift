// Choosing by looking: a row of small pictures with names, a row of colour dots, and a box to write in.
import SwiftUI

/// A few choices, each a small picture with its name below. The chosen one is ringed in ink and named in ink;
/// the rest are named quietly.
package struct PictureChoices<Option: Hashable>: View {
    @Environment(\.motion) private var motion
    private let options: [(Option, String, AnyView)]
    @Binding private var selection: Option

    package init(options: [(Option, String, AnyView)], selection: Binding<Option>) {
        self.options = options
        _selection = selection
    }

    package var body: some View {
        HStack(alignment: .top, spacing: Space.wide.rawValue) {
            ForEach(options.indices, id: \.self) { index in
                let (option, name, picture) = options[index]
                let chosen = option == selection
                VStack(spacing: Space.snug.rawValue) {
                    picture
                        .frame(width: 76, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.control.rawValue, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.control.rawValue, style: .continuous)
                                .strokeBorder(Role.hairline, lineWidth: 1)
                        }
                        .padding(3)
                        .overlay {
                            // The ring stands a point clear of the picture, its corner measured from Search's.
                            if chosen {
                                RoundedRectangle(cornerRadius: 9.5, style: .continuous)
                                    .strokeBorder(Role.ink, lineWidth: 2)
                            }
                        }
                    Text(name)
                        .type(.detail)
                        .fontWeight(chosen ? .medium : .regular)
                        .foregroundStyle(chosen ? Role.ink : Role.muted)
                }
                .contentShape(Rectangle())
                .pressed { withAnimation(motion.settle) { selection = option } }
                .accessibilityLabel(Text(name))
                .accessibilityAddTraits(chosen ? .isSelected : [])
            }
        }
    }
}

/// A row of colour dots to choose from, the chosen one ringed in ink. With `well`, the Mac's own colour well
/// follows under that name, for any other colour.
package struct Swatches: View {
    private let colours: [(Color, String)]
    @Binding private var selection: Color
    private let well: String?

    package init(colours: [(Color, String)], selection: Binding<Color>, well: String? = nil) {
        self.colours = colours
        _selection = selection
        self.well = well
    }

    /// Search's own colours for a page, named by their hex.
    package static let search: [(Color, String)] = ["#E8DFD0", "#F3D9CF", "#D9E4D3", "#D3DFEA", "#E4D8EC", "#2B2B2E"]
        .map { (colour(hex: $0), $0) }

    package var body: some View {
        HStack(spacing: Space.gap.rawValue) {
            ForEach(colours.indices, id: \.self) { index in
                let (colour, name) = colours[index]
                let chosen = colour == selection
                Circle()
                    .fill(colour)
                    .overlay {
                        Circle().strokeBorder(
                            chosen ? AnyShapeStyle(Role.ink) : AnyShapeStyle(Role.hairline), lineWidth: 1.5)
                    }
                    .frame(width: 24, height: 24)
                    .contentShape(Circle())
                    .pressed { selection = colour }
                    .accessibilityLabel(Text(verbatim: "Colour \(name)"))
                    .accessibilityAddTraits(chosen ? .isSelected : [])
            }
            if let well {
                HStack(spacing: Space.near.rawValue) {
                    Text(well)
                        .foregroundStyle(Role.ink)
                    ColorPicker(well, selection: $selection, supportsOpacity: false)
                        .labelsHidden()
                }
            }
        }
    }

    /// The colour a hex such as "#E8DFD0" names.
    private static func colour(hex: String) -> Color {
        let value = UInt32(hex.dropFirst(), radix: 16) ?? 0
        func part(_ shift: UInt32) -> Double { Double((value >> shift) & 0xFF) / 255 }
        return Color(.sRGB, red: part(16), green: part(8), blue: part(0))
    }
}

/// A box to write several lines in, such as code, in the monospaced face.
package struct Writing: View {
    @Binding private var text: String
    private let height: CGFloat

    package init(text: Binding<String>, height: CGFloat) {
        _text = text
        self.height = height
    }

    package var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(Role.ink)
            .scrollContentBackground(.hidden)
            .autocorrectionDisabled()
            .padding(Space.near.rawValue)
            .frame(height: height)
            .background(Role.wash, in: RoundedRectangle(cornerRadius: Radius.card.rawValue, style: .continuous))
    }
}

extension View {
    /// Makes a drawn choice a real button, so it is reached with Tab and pressed with Space.
    fileprivate func pressed(_ action: @escaping () -> Void) -> some View {
        Button(action: action) { self }.buttonStyle(.plain)
    }
}
