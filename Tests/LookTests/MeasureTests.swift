import Foundation
import Testing

@testable import Look

/// Every type size, space, corner and shadow Search's code writes, read from its source at commit c92ea7c:
/// each `.font(.system(size:weight:design:))`, `.padding`, `spacing:`, `cornerRadius:` and black `.shadow`.
private struct SearchMeasures: Decodable {
    struct Words: Decodable, Hashable {
        let size: Double
        let weight: String
        let design: String
    }
    struct Shadow: Decodable, Hashable {
        let opacity: Double
        let radius: Double
        let x: Double
        let y: Double
    }
    let type: Set<Words>
    let space: Set<Double>
    let radius: Set<Double>
    let shadow: Set<Shadow>

    static func read() throws -> SearchMeasures {
        let file = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Fixtures/Search Measures.json")
        return try JSONDecoder().decode(SearchMeasures.self, from: Data(contentsOf: file))
    }
}

@Test(arguments: TypeRole.allCases)
func eachTypeRoleIsASizeSearchUses(role: TypeRole) throws {
    let type = SearchMeasures.Words(size: role.size, weight: role.weightName, design: role.designName)
    #expect(try SearchMeasures.read().type.contains(type), "\(role)")
}

@Test(arguments: Space.allCases)
func eachSpaceIsOneSearchUses(space: Space) throws {
    #expect(try SearchMeasures.read().space.contains(space.rawValue), "\(space)")
}

@Test(arguments: Radius.allCases)
func eachCornerIsOneSearchUses(radius: Radius) throws {
    #expect(try SearchMeasures.read().radius.contains(radius.rawValue), "\(radius)")
}

@Test(arguments: Elevation.allCases)
func eachShadowIsOneSearchUses(elevation: Elevation) throws {
    let shadow = SearchMeasures.Shadow(opacity: elevation.opacity, radius: elevation.radius, x: 0, y: elevation.y)
    #expect(try SearchMeasures.read().shadow.contains(shadow), "\(elevation)")
}
