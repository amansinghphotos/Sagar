import Foundation
import Testing

@testable import Shell

/// A settings store of its own, emptied when the test is done.
private func withSettings(_ body: (UserDefaults) throws -> Void) throws {
    let name = "org.example.specimen.\(UUID().uuidString)"
    let settings = try #require(UserDefaults(suiteName: name))
    defer { settings.removePersistentDomain(forName: name) }
    try body(settings)
}

@Test func theVeryFirstOpenOwesNothingNew() throws {
    try withSettings { settings in
        #expect(!NewBuild(settings).isNew("20261127.1600"))
    }
}

@Test func theSameBuildOpenedAgainOwesNothingNew() throws {
    try withSettings { settings in
        _ = NewBuild(settings).isNew("20261127.1600")
        #expect(!NewBuild(settings).isNew("20261127.1600"))
    }
}

@Test func aNewBuildIsNewOnceOnly() throws {
    try withSettings { settings in
        _ = NewBuild(settings).isNew("20261127.1600")
        #expect(NewBuild(settings).isNew("20261204.0930"))
        #expect(!NewBuild(settings).isNew("20261204.0930"))
    }
}

@Test func aMendedBuildUnderTheSameNumberIsNewAgain() throws {
    try withSettings { settings in
        _ = NewBuild(settings).isNew("20261127.1600")
        #expect(NewBuild(settings).isNew("20261127.1745"))
    }
}
