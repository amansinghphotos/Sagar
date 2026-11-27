import Foundation
import Sparkle

/// Sparkle, started for one app: it checks the app's feed daily and when asked.
package final class Updates {
    /// The updater for this app, or nil if the app was built without a feed or a key.
    package static let shared = try? Updates(for: .main)

    private let updater: SPUUpdater

    /// Starts Sparkle for an app. Throws if the app names no feed or carries no update key.
    package init(for app: Bundle) throws {
        let named = (app.object(forInfoDictionaryKey: "SUFeedURL") as? String).flatMap(URL.init(string:))
        guard named?.scheme == "https" else { throw UpdatesError.noFeed }
        let driver = SPUStandardUserDriver(hostBundle: app, delegate: nil)
        updater = SPUUpdater(hostBundle: app, applicationBundle: app, userDriver: driver, delegate: nil)
        try updater.start()
    }

    /// Whether Sparkle's update window would offer this app's people a box to install updates without asking.
    package static func offersSilentInstalls(for app: Bundle) -> Bool {
        SPUUpdaterSettings(hostBundle: app).allowsAutomaticUpdates
    }

    /// Where this app looks for updates.
    package var feed: URL? { updater.feedURL }

    /// Looks for an update now and shows the person what it finds.
    package func check() { updater.checkForUpdates() }
}

/// Why updates could not start.
package enum UpdatesError: Error {
    case noFeed
}
