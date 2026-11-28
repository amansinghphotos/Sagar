import Foundation
import Pictures
import SwiftUI
import Testing

/// Where Search's own pictures and records are kept, beside these tests.
private let fixtures = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Fixtures")

/// Search's record `Fixtures/Search <name>.json`.
func searchRecord<Record: Decodable>(_ name: String) throws -> Record {
    try JSONDecoder().decode(Record.self, from: Data(contentsOf: fixtures.appending(path: "Search \(name).json")))
}

/// Search's picture `Fixtures/Search <name> Light.png`, or `Dark.png`.
func searchPicture(_ name: String, dark: Bool, sourceLocation: SourceLocation = #_sourceLocation) throws -> CGImage {
    let file = fixtures.appending(path: "Search \(name) \(dark ? "Dark" : "Light").png")
    return try #require(approvedPicture(at: file), sourceLocation: sourceLocation)
}

/// Fails the test unless the screen matches Search's picture `name`, and, when `shadeForShade`, matches it within
/// the `fine` step too. Gives back our picture, for a test that reads it further.
@discardableResult
func expectSearchPicture(
    of view: some View, width: CGFloat, height: CGFloat, named name: String, dark: Bool, shadeForShade: Bool = false,
    sourceLocation: SourceLocation = #_sourceLocation
) throws -> CGImage {
    let search = try searchPicture(name, dark: dark, sourceLocation: sourceLocation)
    let ours = try picture(of: view, width: width, height: height, dark: dark)
    #expect(differingPixels(ours, search) <= tolerance, sourceLocation: sourceLocation)
    if shadeForShade {
        #expect(differingPixels(ours, search, levels: fine) <= tolerance, sourceLocation: sourceLocation)
    }
    return ours
}
