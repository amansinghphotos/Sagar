import Foundation
import Keep
import os

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
    /// Deletes every clip copied longer ago than you chose to keep things, and says which went.
    @discardableResult
    package func trim(_ keeping: Keeping, now: Date = .now, calendar: Calendar = .current) throws -> [Clip] {
        guard let oldest = keeping.oldestKept(now: now, calendar: calendar) else { return [] }
        let old = try all().filter { $0.copied < oldest }
        for clip in old { try delete(clip) }
        return old
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

extension Copies {
    /// Deletes what is older than you chose as Chete opens, and again each day it stays open. The day is
    /// counted through the Mac's sleep, and macOS may move the wake by up to an hour to group it with others.
    /// Each time clips go, `deleted` is told which, so the list can drop them.
    @discardableResult
    nonisolated package func trimDaily(
        every day: Duration = .seconds(86_400), now: @escaping @MainActor () -> Date = { .now },
        calendar: Calendar = .current, deleted: @escaping @MainActor ([Clip]) -> Void
    ) -> Task<Void, Never> {
        Task { @MainActor in
            while !Task.isCancelled {
                do {
                    let old = try await trim(now: now(), calendar: calendar)
                    if !old.isEmpty { deleted(old) }
                } catch {
                    Logger(subsystem: "com.amansingh.chete", category: "Copies")
                        .error("Old clips were not deleted: \(error)")
                }
                try? await Task.sleep(for: day, tolerance: day / 24)
            }
        }
    }
}
