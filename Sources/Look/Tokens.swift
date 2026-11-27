import SwiftUI

/// The looks an app can choose, once, at its root. Lexicon joins Modern once Modern's pictures are approved.
nonisolated package enum Theme: String, CaseIterable, Sendable {
    case modern = "Modern"
}

nonisolated extension Theme {
    /// Each role's colour, light and dark. Modern's are Search's own, exactly: its `Palette` at commit c92ea7c.
    package func colour(_ role: Role) -> Pair {
        switch role {
        case .ground: Pair(white: 1.0, 0.11)
        case .ink: Pair(white: 0.09, 0.93)
        case .muted: Pair(white: 0.55, 0.58)
        case .faint: Pair(white: 0.83, 0.32)
        case .hairline: Pair(white: 0.91, 0.20)
        case .wash: Pair(white: 0.937, 0.175)
        case .hover: Pair(white: 0.965, 0.15)
        case .frame: Pair(white: 0.955, 0.075)
        case .safe: Pair(light: RGB(red: 0.08, green: 0.50, blue: 0.24), dark: RGB(red: 0.29, green: 0.87, blue: 0.50))
        case .unsafe:
            Pair(light: RGB(red: 0.71, green: 0.33, blue: 0.04), dark: RGB(red: 0.98, green: 0.75, blue: 0.14))
        }
    }
}

/// The window sizes every screen is pictured at. The narrowest is the smallest a window may be, as in Search.
package enum WindowSize: String, CaseIterable, Sendable {
    case narrow = "Narrow"
    case standard = "Default"
    case wide = "Wide"

    /// The window's width in points.
    package var width: CGFloat {
        switch self {
        case .narrow: 640
        case .standard: 900
        case .wide: 1200
        }
    }

    /// The window's height in points.
    package var height: CGFloat {
        switch self {
        case .narrow: 420
        case .standard: 600
        case .wide: 760
        }
    }
}
