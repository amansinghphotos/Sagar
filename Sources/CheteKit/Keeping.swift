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

nonisolated extension Clips {
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
