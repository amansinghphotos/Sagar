// Taken from Search at commit c92ea7c: PictureChoices (Pictures in Settings.swift), Swatches (the solid row in
// ThemesPage.swift, with its six colours and the colour well beside them) and Writing (the box in SiteStyles.swift).
// Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed where this repository's rules require:
// Search's colours and motion are read from Look, Pictures is renamed because the picture tests' module holds that
// name, and given values replace Search's settings. Two things are added so an app can use the row: the colour well
// is optional, and Search's six colours are a list here, because a screen may not name a colour.
import SwiftUI

/// A choice of a few, each a small picture with its name below, the chosen one ringed.
package struct PictureChoices<Option: Hashable>: View {
    let options: [(Option, String, AnyView)]
    @Binding var selection: Option

    @Environment(\.motion) private var motion

    package init(options: [(Option, String, AnyView)], selection: Binding<Option>) {
        self.options = options
        _selection = selection
    }

    package var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ForEach(options, id: \.0) { option, title, picture in
                let on = option == selection
                Button {
                    withAnimation(motion.settle) { selection = option }
                } label: {
                    VStack(spacing: 6) {
                        picture
                            .frame(width: 76, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .strokeBorder(Role.hairline, lineWidth: 1)
                            )
                            .padding(3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9.5, style: .continuous)
                                    .strokeBorder(on ? AnyShapeStyle(Role.ink) : AnyShapeStyle(.clear), lineWidth: 2)
                            )
                        Text(title)
                            .font(.system(size: 11.5, weight: on ? .medium : .regular))
                            .foregroundStyle(on ? Role.ink : Role.muted)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// A row of colours to choose from, the chosen one ringed in ink; with `well`, Apple's colour well
/// follows, for any other colour.
package struct Swatches: View {
    let colours: [(Color, String)]
    @Binding var selection: Color
    var well: String?

    package init(colours: [(Color, String)], selection: Binding<Color>, well: String? = nil) {
        self.colours = colours
        _selection = selection
        self.well = well
    }

    /// Search's own six, each named by its hex as Search names them aloud.
    package static let search: [(Color, String)] = ["#E8DFD0", "#F3D9CF", "#D9E4D3", "#D3DFEA", "#E4D8EC", "#2B2B2E"]
        .map { hex in
            let n = UInt32(hex.dropFirst(), radix: 16) ?? 0
            return (
                Color(
                    red: Double((n >> 16) & 255) / 255, green: Double((n >> 8) & 255) / 255, blue: Double(n & 255) / 255
                ),
                hex
            )
        }

    package var body: some View {
        HStack(spacing: 10) {
            ForEach(colours, id: \.1) { colour, name in
                Button {
                    selection = colour
                } label: {
                    Circle().fill(colour).frame(width: 24, height: 24)
                        .overlay(
                            Circle().strokeBorder(
                                selection == colour
                                    ? Role.ink : Role.hairline, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Colour \(name)")
            }
            if let well {
                ColorPicker(well, selection: $selection, supportsOpacity: false)
            }
        }
    }
}

/// A box for text over several lines, in Search's monospaced type, on the wash.
package struct Writing: View {
    @Binding var text: String
    let height: CGFloat

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
            .padding(8)
            .frame(height: height)
            .background(Role.wash, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
