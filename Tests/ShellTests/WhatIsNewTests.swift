import Foundation
import Testing

@testable import Shell

/// A build's own information, as its Info.plist has it once built with a release's notes.
private func build(_ number: String, new: String = "", better: String = "", fixed: String = "") -> [String: Any] {
    ["CFBundleVersion": number, "SagarNew": new, "SagarBetter": better, "SagarFixed": fixed]
}

@Test @MainActor func aBuildsLinesComeInOrderLeavingOutAnyItHasNot() {
    let lines = WhatIsNew.lines(in: build("1", new: "Find a clip by typing.", fixed: "Pasting no longer stalls."))
    #expect(lines.map(\.kind) == ["New", "Fixed"])
    #expect(lines.map(\.line) == ["Find a clip by typing.", "Pasting no longer stalls."])
}

@Test @MainActor func aBuildMadeWithoutNotesHasNoLines() {
    #expect(WhatIsNew.lines(in: build("1")).isEmpty)
    #expect(WhatIsNew.lines(in: [:]).isEmpty)
}

@Test @MainActor func theCardIsDueOnceOnANewBuildThatHasLines() throws {
    try withSettings { settings in
        #expect(WhatIsNew.due(build("1", new: "One."), settings) == nil)  // the very first open is the welcome's
        #expect(WhatIsNew.due(build("2", new: "Two."), settings)?.map(\.line) == ["Two."])
        #expect(WhatIsNew.due(build("2", new: "Two."), settings) == nil)
    }
}

@Test @MainActor func aNewBuildWithNoLinesShowsNoCardButIsSeen() throws {
    try withSettings { settings in
        _ = WhatIsNew.due(build("1"), settings)
        #expect(WhatIsNew.due(build("2"), settings) == nil)
        #expect(WhatIsNew.due(build("2", new: "Two."), settings) == nil)
    }
}

@Test @MainActor func theSameBuildOpenedAgainOwesNothingNew() throws {
    try withSettings { settings in
        _ = WhatIsNew.due(build("20261127.1600", new: "One."), settings)
        #expect(WhatIsNew.due(build("20261127.1600", new: "One."), settings) == nil)
    }
}

@Test @MainActor func aMendedBuildUnderTheSameNumberIsNewAgain() throws {
    try withSettings { settings in
        _ = WhatIsNew.due(build("20261127.1600", new: "One."), settings)
        #expect(WhatIsNew.due(build("20261127.1745", new: "Mended."), settings)?.map(\.line) == ["Mended."])
    }
}
