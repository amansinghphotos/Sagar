// Taken from Search, Sources/Search/Design.swift at commit c92ea7c. Copyright (c) 2026 Office Commun, MIT
// licence (ACKNOWLEDGEMENTS.md). Changed only where this repository's rules require: a shade is drawn by
// SwiftUI for the light or dark look, not by AppKit.
import SwiftUI

/// The greys of the column's rows, pins and buttons, for the ground they lie
/// on: the white's (the strip, a panel, the column with the page edge to
/// edge) or the window's beside the page's card, set by the column for
/// what is in it. Read through the environment, so a
/// row, a pin or a door is the same view on either ground.
nonisolated package struct Greys: Sendable {
    package let wash: Shade
    package let hover: Shade
    package let tile: Shade
    package let pinLive: Shade
    /// The live and hovered greys for a row lying on a tile (a Split View
    /// tab's panes), so the two together land where the plain ones do.
    package let washOnTile: Shade
    package let hoverOnTile: Shade
    /// The quiet ink of a tab's title that isn't live, the same way: on
    /// the plain ground Palette.muted exactly, on a space's Rich or Vivid
    /// colour as far from it as Palette.muted is from the plain ground,
    /// where the opaque grey lost a third of its contrast.
    package let muted: Shade
    /// The faintest ink, New tab's, the same way: on Vivid the opaque grey
    /// all but vanished into the colour.
    package let faint: Shade

    // Black in a light window, white in a dark one, at the strength that
    // lands on the same grey as Palette's over the ground they lie on (the
    // white, or the frame beside the card). On that ground nothing changes;
    // on a space's colour or gradient they take its tint, where an opaque
    // grey sat on it as a grey patch.
    package static let white = Greys(
        wash: shade(0.063, 0.073), hover: shade(0.035, 0.045),
        tile: shade(0.063, 0.073).opacity(0.55), pinLive: shade(0.10, 0.112),
        washOnTile: shade(0.0294, 0.0342), hoverOnTile: shade(0.004, 0.005),
        muted: shade(0.45, 0.5281), faint: shade(0.17, 0.236))
    package static let frame = Greys(
        wash: shade(0.0628, 0.0865), hover: shade(0.0419, 0.0595),
        tile: shade(0.0314, 0.0432), pinLive: shade(0.0995, 0.1243),
        washOnTile: shade(0.0324, 0.0452), hoverOnTile: shade(0.0108, 0.0169),
        muted: shade(0.4241, 0.5459), faint: shade(0.1309, 0.2649))

    private static func shade(_ light: Double, _ dark: Double) -> Shade {
        Shade(light: light, dark: dark)
    }
}

/// Black let through at `light` in the light look, white at `dark` in the dark one.
nonisolated package struct Shade: ShapeStyle {
    let light: Double
    let dark: Double
    var strength = 1.0

    /// The same shade, let through `strength` as much.
    package func opacity(_ strength: Double) -> Shade {
        Shade(light: light, dark: dark, strength: self.strength * strength)
    }

    package func resolve(in environment: EnvironmentValues) -> Color {
        environment.colorScheme == .dark
            ? Color.white.opacity(dark * strength) : Color.black.opacity(light * strength)
    }
}

nonisolated private struct GreysKey: EnvironmentKey {
    static let defaultValue = Greys.white
}

extension EnvironmentValues {
    nonisolated package var greys: Greys {
        get { self[GreysKey.self] }
        set { self[GreysKey.self] = newValue }
    }
}
