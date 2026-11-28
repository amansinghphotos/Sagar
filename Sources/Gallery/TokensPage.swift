import Look
import SwiftUI

/// The Tokens page: every colour, with how far it stands from the ground as a number, then every type role,
/// space, corner and shadow.
struct Tokens: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.page.rawValue) {
                grid(Role.allCases) { role in
                    HStack {
                        Rectangle().fill(role).frame(width: 28, height: 28)
                            .overlay(Rectangle().stroke(Role.hairline))
                        VStack(alignment: .leading) {
                            Text(role.rawValue)
                            Text(contrast(of: role)).foregroundStyle(Role.muted)
                        }
                    }
                }
                grid(TypeRole.allCases) { role in
                    Text(verbatim: "\(role.rawValue) \(role.size.formatted())").type(role)
                }
                grid(Space.allCases) { space in
                    HStack {
                        Rectangle().fill(Role.ink).frame(width: space.rawValue, height: 12)
                        Text(verbatim: "\(space) \(space.rawValue.formatted())").foregroundStyle(Role.muted)
                    }
                }
                grid(Radius.allCases) { radius in
                    RoundedRectangle(cornerRadius: radius.rawValue, style: .continuous).fill(Role.wash)
                        .frame(width: 120, height: 44)
                        .overlay(Text(verbatim: "\(radius) \(radius.rawValue.formatted())"))
                }
                grid(Elevation.allCases) { elevation in
                    RoundedRectangle(cornerRadius: Radius.card.rawValue, style: .continuous).fill(Role.ground)
                        .elevation(elevation)
                        .frame(width: 120, height: 44)
                        .overlay(Text(verbatim: "\(elevation)"))
                }
            }
            .padding(Space.page.rawValue)
        }
    }

    private func grid<Item: Hashable>(_ items: [Item], @ViewBuilder _ cell: @escaping (Item) -> some View) -> some View
    {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], alignment: .leading) {
            ForEach(items, id: \.self, content: cell)
        }
    }

    /// The role's contrast with the ground, as the guidelines write it: 4.5 : 1.
    private func contrast(of role: Role) -> String {
        let pick = { (pair: Pair) in scheme == .dark ? pair.dark : pair.light }
        let ratio = pick(theme.colour(role)).contrast(with: pick(theme.colour(.ground)))
        return ratio.formatted(.number.precision(.fractionLength(1))) + " : 1"
    }
}
