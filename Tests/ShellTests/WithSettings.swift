import Foundation
import Testing

/// A settings store of its own, emptied when the test is done.
func withSettings(_ body: (UserDefaults) throws -> Void) throws {
    let name = "org.example.specimen.\(UUID().uuidString)"
    let settings = try #require(UserDefaults(suiteName: name))
    defer { settings.removePersistentDomain(forName: name) }
    try body(settings)
}
