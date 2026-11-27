import SwiftUI

/// The looks an app can choose, once, at its root. Lexicon joins Modern once Modern's pictures are approved.
package enum Theme: String, CaseIterable, Sendable {
    case modern = "Modern"
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
