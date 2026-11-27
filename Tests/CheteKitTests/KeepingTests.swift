import Foundation
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
