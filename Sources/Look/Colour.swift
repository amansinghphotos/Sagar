import SwiftUI

/// A colour as its red, green and blue, each 0 to 1, in sRGB.
nonisolated package struct RGB: Equatable, Sendable {
    package let red: Double
    package let green: Double
    package let blue: Double

    package init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// A grey, as much white as `white`.
    package init(white: Double) {
        self.init(red: white, green: white, blue: white)
    }

    /// How bright it looks, by the Web's accessibility guidelines.
    package var luminance: Double {
        func linear(_ part: Double) -> Double {
            part <= 0.039_28 ? part / 12.92 : pow((part + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// How far apart two colours are to the eye, from 1 to 1 (the same) to 21 to 1 (black and white).
    package func contrast(with other: RGB) -> Double {
        let (light, dark) = (max(luminance, other.luminance), min(luminance, other.luminance))
        return (light + 0.05) / (dark + 0.05)
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue) }
}

/// A role's colour in the light look and in the dark one.
nonisolated package struct Pair: Equatable, Sendable {
    package let light: RGB
    package let dark: RGB

    /// A grey in each look.
    package init(white light: Double, _ dark: Double) {
        self.init(light: RGB(white: light), dark: RGB(white: dark))
    }

    package init(light: RGB, dark: RGB) {
        self.light = light
        self.dark = dark
    }
}

/// What a colour is for. Screens name a role, never a colour: the theme and the look, light or dark, choose it.
nonisolated package enum Role: String, CaseIterable, Sendable, ShapeStyle {
    /// The page itself.
    case ground
    /// Words and marks.
    case ink
    /// Quieter words.
    case muted
    /// The quietest words, and marks that rest.
    case faint
    /// Thin lines that divide.
    case hairline
    /// What is chosen.
    case wash
    /// What is under the pointer.
    case hover
    /// Around a page laid as a card.
    case frame
    /// All is well.
    case safe
    /// Take care.
    case unsafe

    package func resolve(in environment: EnvironmentValues) -> Color {
        let pair = environment.theme.colour(self)
        return (environment.colorScheme == .dark ? pair.dark : pair.light).color
    }
}

nonisolated extension EnvironmentValues {
    /// The theme an app chose, set once at its root.
    @Entry package var theme = Theme.modern
}
