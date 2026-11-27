import Foundation
import Keep
import Testing

@testable import CheteKit

/// One fixed moment and one fixed calendar, so that a month is always the same length here.
private let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
}()

private func clip(_ text: String, daysOld days: Double) -> Clip {
    Clip(kinds: [.text(text)], copied: now.addingTimeInterval(-days * 86_400), app: nil)
}

/// Four clips of known ages, newest first.
private let ages = [
    clip("a day", daysOld: 1), clip("8 days", daysOld: 8), clip("40 days", daysOld: 40),
    clip("400 days", daysOld: 400),
]

@Test func aYearIsTheChoiceAtFirst() {
    #expect(Settings().keeping == .year)
}

@Test(arguments: [(Keeping.week, 1), (.month, 2), (.year, 3), (.forever, 4)])
func eachChoiceKeepsExactlyTheClipsItShould(keeping: Keeping, kept count: Int) throws {
    let kept = Kept()
    defer { kept.removed() }
    let clips = try kept.clips()
    for clip in ages { try clips.keep(clip) }
    try clips.trim(keeping, now: now, calendar: calendar)
    #expect(try clips.all() == Array(ages.prefix(count)))
}

@Test func deletingOneClipLeavesTheOthers() throws {
    let kept = Kept()
    defer { kept.removed() }
    let clips = try kept.clips()
    for clip in ages { try clips.keep(clip) }
    try clips.delete(ages[1])
    #expect(try clips.all() == [ages[0], ages[2], ages[3]])
    let files = try FileManager.default.contentsOfDirectory(atPath: kept.folder.path)
    #expect(!files.contains { $0.hasPrefix(ages[1].id.uuidString) })
}

@Test func deletingEverythingLeavesNothingBehind() throws {
    let kept = Kept()
    defer { kept.removed() }
    let clips = try kept.clips()
    for clip in ages { try clips.keep(clip) }
    try clips.deleteAll()
    #expect(try clips.all() == [])
    #expect(try FileManager.default.contentsOfDirectory(atPath: kept.folder.path) == [])
}

@Test func theChoiceIsKeptAndReadBack() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    #expect(try Settings.read(in: folder) == Settings())
    try Settings(keeping: .month).write(in: folder)
    #expect(try Settings.read(in: folder) == Settings(keeping: .month))
}

@Test func settingsFromALaterVersionWithMoreInThemStillRead() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try Data(#"{"keeping": "week", "added later": true}"#.utf8).write(to: folder.appending(path: "Settings.json"))
    #expect(try Settings.read(in: folder) == Settings(keeping: .week))
}

// While Chete stays open.

/// Chete's copies in a fresh folder, sealed by a key the real Chete never uses, keeping things a week:
/// one clip copied a day ago, and one that passes a week within the day.
private struct Open {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let keyName = "Sagar Tests · \(UUID().uuidString)"
    let copies: Copies
    let fresh: Clip
    let nearlyAWeekOld: Clip

    init() async throws {
        try Settings(keeping: .week).write(in: folder)
        copies = try Copies(folder: folder, keyName: keyName)
        let old = try await copies.take([.text("old")], fromOtherDevice: false, copied: now - 6.5 * 86_400, app: nil)
        let new = try await copies.take([.text("new")], fromOtherDevice: false, copied: now - 86_400, app: nil)
        (fresh, nearlyAWeekOld) = (try #require(new), try #require(old))
    }

    func removed() {
        try? Seal.forget(named: keyName)
        try? FileManager.default.removeItem(at: folder)
    }
}

@Test func aClipIsDeletedOnceItPassesTheTimeChosen() async throws {
    let open = try await Open()
    defer { open.removed() }
    #expect(try await open.copies.trim(now: now, calendar: calendar) == [])
    #expect(try await open.copies.all() == [open.fresh, open.nearlyAWeekOld])
    #expect(try await open.copies.trim(now: now + 86_400, calendar: calendar) == [open.nearlyAWeekOld])
    #expect(try await open.copies.all() == [open.fresh])
}

/// A clock the test moves: each time Chete asks, a day has gone by.
private final class Days {
    var asked = 0
    func next() -> Date {
        asked += 1
        return now + Double(asked - 1) * 86_400
    }
}

@Test func cheteDeletesWhenItOpensAndAgainEachDay() async throws {
    let open = try await Open()
    defer { open.removed() }
    let days = Days()
    let (deleted, told) = AsyncStream.makeStream(of: (clips: [Clip], onDay: Int).self)
    let daily = open.copies.trimDaily(every: .milliseconds(1), now: days.next, calendar: calendar) {
        told.yield(($0, days.asked))
    }
    defer { daily.cancel() }
    // Nothing was too old as Chete opened. A day on, the older clip had passed a week, and went.
    var passes = deleted.makeAsyncIterator()
    let first = try #require(await passes.next())
    #expect(first.clips == [open.nearlyAWeekOld])
    #expect(first.onDay == 2)
    #expect(try await open.copies.all() == [open.fresh])
}

@Test func theListDropsWhatWasDeletedButNotACopyMadeSince() {
    let shelf = Shelf(ages)
    let again = Clip(id: ages[3].id, kinds: ages[3].kinds, copied: now, app: nil)
    shelf.add(again)
    shelf.remove([ages[2], ages[3]])
    #expect(shelf.clips == [again, ages[0], ages[1]])
}
