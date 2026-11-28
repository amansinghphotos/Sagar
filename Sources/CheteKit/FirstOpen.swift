import Foundation
import Keep

/// What lies under Chete's welcome on a new Mac: whether it is still due, the steps it takes one to a page,
/// which were skipped so Settings can offer them again, and what Bring Back says. No screen.
nonisolated package enum FirstOpen {
    /// True until the welcome was finished on this Mac.
    package static func isDue(in folder: URL) -> Bool {
        (try? record(in: folder).done) != true
    }

    /// Notes that the welcome is over, so it never shows again on this Mac.
    package static func done(in folder: URL) throws {
        var record = try record(in: folder)
        record.done = true
        try Store(folder: folder).write(record, named: name)
    }

    /// Notes a step skipped, so it waits in Settings.
    package static func skip(_ step: WelcomePage, in folder: URL) throws {
        var record = try record(in: folder)
        guard !record.skipped.contains(step) else { return }
        record.skipped.append(step)
        try Store(folder: folder).write(record, named: name)
    }

    /// The steps skipped, in the welcome's order.
    package static func skipped(in folder: URL) throws -> [WelcomePage] {
        let skipped = try record(in: folder).skipped
        return WelcomePage.allCases.filter(skipped.contains)
    }

    /// Brings back an exported history in place of what is here, and says what came back; any other file changes nothing.
    package static func bringBack(from file: URL, into folder: URL, keyName: String) throws -> String {
        let history = try History.bringBack(from: file)
        try history.replace(in: folder, keyName: keyName)
        return history.clips.count == 1 ? "Brought back 1 clip." : "Brought back \(history.clips.count) clips."
    }

    /// What the welcome keeps in Chete's folder.
    private struct Record: Codable {
        var done = false
        var skipped: [WelcomePage] = []
    }

    private static let name = "Welcome"

    private static func record(in folder: URL) throws -> Record {
        try Store(folder: folder).read(Record.self, named: name) ?? Record()
    }
}
