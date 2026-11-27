import Foundation
import Keep

/// How long Chete keeps what you copy.
nonisolated package enum Keeping: String, Codable, CaseIterable, Sendable {
    case week, month, year, forever

    /// The earliest moment a clip may have been copied and still be kept, or nil to keep everything.
    package func oldestKept(now: Date, calendar: Calendar) -> Date? {
        switch self {
        case .week: calendar.date(byAdding: .weekOfYear, value: -1, to: now)
        case .month: calendar.date(byAdding: .month, value: -1, to: now)
        case .year: calendar.date(byAdding: .year, value: -1, to: now)
        case .forever: nil
        }
    }
}

/// Chete's settings, kept as a plain file in its folder.
nonisolated package struct Settings: Codable, Equatable, Sendable {
    /// A year at first.
    package var keeping: Keeping = .year

    package init(keeping: Keeping = .year) {
        self.keeping = keeping
    }

    /// A setting missing from the file, as one added in a later version, takes its first value.
    package init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        keeping = try values.decodeIfPresent(Keeping.self, forKey: .keeping) ?? .year
    }

    /// The settings saved in a store, or the first ones if none were saved.
    package static func read(from store: Store) throws -> Settings {
        try store.read(Settings.self, named: "Settings") ?? Settings()
    }

    package func write(to store: Store) throws {
        try store.write(self, named: "Settings")
    }
}

extension Clips {
    /// Deletes every clip copied longer ago than you chose to keep things.
    package func trim(_ keeping: Keeping, now: Date = .now, calendar: Calendar = .current) throws {
        guard let oldest = keeping.oldestKept(now: now, calendar: calendar) else { return }
        for clip in try all() where clip.copied < oldest {
            try delete(clip)
        }
    }

    /// Deletes one clip.
    package func delete(_ clip: Clip) throws {
        try store.removeSealed(named: clip.id.uuidString)
    }

    /// Deletes every clip.
    package func deleteAll() throws {
        for name in try store.sealedNames() {
            try store.removeSealed(named: name)
        }
    }
}
