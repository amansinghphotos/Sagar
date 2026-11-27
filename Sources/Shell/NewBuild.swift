import Foundation

/// Knows whether this build is opened for the first time on this Mac, so the app can say what is new
/// once. It keeps the date stamp of the last build it saw in the app's own settings. An app's very
/// first open is not news: that is the welcome's to greet.
package struct NewBuild {
    private let settings: UserDefaults
    private let key = "Shell.LastBuildSeen"

    package init(_ settings: UserDefaults = .standard) {
        self.settings = settings
    }

    /// True the first time a build follows a different one; remembers it, so it is true once only.
    /// A mended build under the same number has a new date stamp, so it is new again.
    package func isNew(_ build: String) -> Bool {
        let last = settings.string(forKey: key)
        settings.set(build, forKey: key)
        return last != nil && last != build
    }
}
