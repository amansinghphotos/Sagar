import Look
import SwiftUI

/// The Choices page: choosing by picture, by colour, and writing over several lines, as Search has them.
struct Choices: View {
    @State private var look = 2
    @State private var colour = Swatches.search[2].0
    @State private var notes = "Clips from today\nand yesterday"

    var body: some View {
        let light = Swatches.search[0].0
        let dark = Swatches.search[5].0
        VStack(alignment: .leading, spacing: Space.page.rawValue) {
            PictureChoices(
                options: [
                    (0, "Light", AnyView(light)),
                    (1, "Dark", AnyView(dark)),
                    (
                        2, "Auto",
                        AnyView(
                            HStack(spacing: 0) {
                                light
                                dark
                            })
                    ),
                ], selection: $look)
            Swatches(colours: Swatches.search, selection: $colour, well: "Other")
            VStack(alignment: .leading, spacing: 6) {
                Caption("Notes")
                Writing(text: $notes, height: 120)
            }
            .frame(width: 420)
        }
        .padding(Space.page.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
