import SwiftUI

extension View {
    /// Sets words in a type role, in the theme's typeface.
    package func type(_ role: TypeRole) -> some View {
        font(.system(size: role.size, weight: role.weight, design: role.design))
    }

    /// Lifts a thing off the page by one of the elevations.
    package func elevation(_ elevation: Elevation) -> some View {
        shadow(color: .black.opacity(elevation.opacity), radius: elevation.radius, y: elevation.y)
    }
}

extension TypeRole {
    var weight: Font.Weight {
        switch weightName {
        case "medium": .medium
        case "semibold": .semibold
        default: .regular
        }
    }

    var design: Font.Design { self == .code ? .monospaced : .default }
}
