import Look
import SwiftUI

/// The Tokens page: each colour role as a swatch, with how far it stands from the ground, as a number.
struct Tokens: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], alignment: .leading) {
                ForEach(Role.allCases, id: \.self) { role in
                    HStack {
                        Rectangle().fill(role).frame(width: 28, height: 28)
                            .overlay(Rectangle().stroke(Role.hairline))
                        VStack(alignment: .leading) {
                            Text(role.rawValue)
                            Text(contrast(of: role)).foregroundStyle(Role.muted)
                        }
                    }
                }
            }
            .padding()
        }
    }

    /// The role's contrast with the ground, as the guidelines write it: 4.5 : 1.
    private func contrast(of role: Role) -> String {
        let pick = { (pair: Pair) in scheme == .dark ? pair.dark : pair.light }
        let ratio = pick(theme.colour(role)).contrast(with: pick(theme.colour(.ground)))
        return ratio.formatted(.number.precision(.fractionLength(1))) + " : 1"
    }
}
