// The see-through greys a screen lays over its ground, a set for a white page and a set for a framed one.
import SwiftUI

/// The greys for one kind of ground. Each is black laid over the light look and white over the dark one, so
/// it darkens or lightens whatever lies beneath by the same step.
nonisolated package struct Greys: Sendable {
    /// What is chosen.
    package let wash: Shade
    /// What is under the pointer.
    package let hover: Shade
    /// A tile resting on the ground.
    package let tile: Shade
    /// A pinned thing that is open.
    package let pinLive: Shade
    /// What is chosen, on a tile.
    package let washOnTile: Shade
    /// What is under the pointer, on a tile.
    package let hoverOnTile: Shade
    /// Quieter words and marks.
    package let muted: Shade
    /// The quietest words and marks.
    package let faint: Shade

    /// On a white page.
    package static let white = Greys(
        wash: shade(0.063, 0.073),
        hover: shade(0.035, 0.045),
        tile: shade(0.063, 0.073).opacity(0.55),
        pinLive: shade(0.1, 0.112),
        washOnTile: shade(0.0294, 0.0342),
        hoverOnTile: shade(0.004, 0.005),
        muted: shade(0.45, 0.5281),
        faint: shade(0.17, 0.236)
    )

    /// On a page laid as a card inside the window's frame.
    package static let frame = Greys(
        wash: shade(0.0628, 0.0865),
        hover: shade(0.0419, 0.0595),
        tile: shade(0.0314, 0.0432),
        pinLive: shade(0.0995, 0.1243),
        washOnTile: shade(0.0324, 0.0452),
        hoverOnTile: shade(0.0108, 0.0169),
        muted: shade(0.4241, 0.5459),
        faint: shade(0.1309, 0.2649)
    )

    /// Black at `light` in the light look, white at `dark` in the dark one.
    private static func shade(_ light: Double, _ dark: Double) -> Shade {
        Shade(light: light, dark: dark)
    }
}

/// A grey that lets the ground show through: black over the light look, white over the dark.
nonisolated package struct Shade: ShapeStyle {
    /// How strong the black is in the light look, from 0 to 1.
    let light: Double
    /// How strong the white is in the dark look, from 0 to 1.
    let dark: Double
    /// How much of the shade is laid, from 0 to 1.
    let strength: Double

    init(light: Double, dark: Double, strength: Double = 1) {
        self.light = light
        self.dark = dark
        self.strength = strength
    }

    /// The same shade laid more lightly.
    package func opacity(_ strength: Double) -> Shade {
        Shade(light: light, dark: dark, strength: self.strength * strength)
    }

    package func resolve(in environment: EnvironmentValues) -> Color {
        environment.colorScheme == .dark
            ? Color.white.opacity(dark * strength)
            : Color.black.opacity(light * strength)
    }
}

nonisolated extension EnvironmentValues {
    /// The greys for the ground a screen sits on: a white page unless a frame says otherwise.
    @Entry package var greys = Greys.white
}
