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

/// What words are for. Each is a size and weight Search uses for the same kind of words, at commit c92ea7c.
nonisolated package enum TypeRole: String, CaseIterable, Sendable {
    /// A greeting that leads an app's welcome. Search has none this large.
    case hero
    /// The one big line of a first-open page: Search's welcome.
    case display
    /// A panel's title: Search's `Plate`.
    case title
    /// A heading inside a page: Search's About window.
    case heading
    /// Words to read.
    case body
    /// A row in a list.
    case row
    /// The line under a row's words.
    case detail
    /// A small heading over a group: Search's `Caption`.
    case caption
    /// A control's own words.
    case label
    /// The smallest words, such as a count.
    case small
    /// Code and keys.
    case code

    /// The size in points.
    package var size: Double {
        switch self {
        case .hero: 46
        case .display: 26
        case .title: 17
        case .heading: 15
        case .body, .code: 13
        case .row: 12
        case .detail, .caption: 11.5
        case .label: 11
        case .small: 10.5
        }
    }

    /// The weight, by Apple's name for it.
    package var weightName: String {
        switch self {
        case .hero, .display, .caption, .label: "medium"
        case .title, .heading: "semibold"
        case .body, .row, .detail, .small, .code: "regular"
        }
    }

    /// The design, by Apple's name for it.
    package var designName: String { self == .code ? "monospaced" : "default" }
}

/// Room between and around things, in points: the spaces Search uses most.
nonisolated package enum Space: Double, CaseIterable, Sendable {
    case hair = 2
    case tight = 4
    case snug = 6
    case near = 8
    case gap = 10
    case apart = 12
    case wide = 14
    case page = 16
}

/// How round a corner is, in points, by what it rounds in Search.
nonisolated package enum Radius: Double, CaseIterable, Sendable {
    /// A small mark, such as a badge.
    case small = 6
    /// A control.
    case control = 7
    /// A row under the pointer.
    case row = 9
    /// A card: Search's `Card`.
    case card = 11
    /// A floating field: Search's launcher.
    case floating = 14
    /// A panel: Search's `Plate`.
    case panel = 16
}

/// How far a thing seems to lift off the page, as Search's shadows.
nonisolated package enum Elevation: CaseIterable, Sendable {
    /// A line along the foot of the window: Search's status line.
    case status
    /// A banner over the page.
    case banner
    /// A floating panel: Search's launcher.
    case floating
    /// A panel: Search's `Plate`.
    case panel

    /// How dark the shadow is, from 0 to 1.
    package var opacity: Double {
        switch self {
        case .status: 0.08
        case .banner: 0.12
        case .floating, .panel: 0.16
        }
    }

    /// How soft its edge is, in points.
    package var radius: Double {
        switch self {
        case .status: 12
        case .banner: 20
        case .floating: 24
        case .panel: 34
        }
    }

    /// How far below it falls, in points.
    package var y: Double {
        switch self {
        case .status: 3
        case .banner: 6
        case .floating: 8
        case .panel: 12
        }
    }
}
