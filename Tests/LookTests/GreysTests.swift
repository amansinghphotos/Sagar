import Foundation
import Testing

@testable import Look

/// Search's greys as its `Design.swift` writes them at commit c92ea7c: each `shade(light, dark)` of
/// `Greys.white` and `Greys.frame`, and the strength a `.opacity` gives it, read from the source.
@Test(arguments: ["white", "frame"])
func theGreysAreSearchs(ground: String) throws {
    let search: [String: [String: [String: Double]]] = try searchRecord("Greys")
    let greys = ground == "white" ? Greys.white : Greys.frame
    let ours: [String: Shade] = [
        "wash": greys.wash, "hover": greys.hover, "tile": greys.tile, "pinLive": greys.pinLive,
        "washOnTile": greys.washOnTile, "hoverOnTile": greys.hoverOnTile, "muted": greys.muted, "faint": greys.faint,
    ]
    let expected = try #require(search[ground])
    #expect(Set(ours.keys) == Set(expected.keys))
    for (name, shade) in ours {
        let want = try #require(expected[name])
        #expect(
            [shade.light, shade.dark, shade.strength] == [want["light"], want["dark"], want["strength"]], "\(name)")
    }
}
