import Foundation
import MetricKit

/// The short report a person may choose to send after an app stops unexpectedly. It holds only the app, its
/// version and build, the Mac's model, the macOS version, and where in the app's own code it stopped, so it
/// never carries anything they copied or typed, a name, a region or a path.
package enum StopReport {
    /// How many of the app's own frames it lists, from where it stopped outwards.
    static let frames = 20

    package static func text(
        of crash: CrashDiagnostic, in mac: DiagnosticReport.Environment, app: String
    ) -> String {
        let tree = crash.callStackTree
        let own = tree.binaryInfo.values.first { $0.name == app }?.uuid
        let thread = tree.callStackThreads.first { $0.threadAttributed == true } ?? tree.callStackThreads.first
        var offsets: [UInt64] = []
        func walk(_ frame: CallStackFrame) {
            if own != nil, frame.binaryUUID == own, let offset = frame.offsetIntoBinaryTextSegment {
                offsets.append(offset)
            }
            frame.subFrames.forEach(walk)
        }
        thread?.rootFrames.forEach(walk)
        var lines = [
            "\(app) \(mac.applicationVersion), build \(mac.applicationBuildVersion), stopped unexpectedly.",
            "\(mac.deviceType), macOS \(mac.osVersion.number).",
        ]
        if let own, !offsets.isEmpty {
            lines.append("Where it stopped in \(app) \(own.uuidString):")
            lines += offsets.prefix(frames).map { "0x" + String($0, radix: 16) }
        }
        return lines.joined(separator: "\n")
    }
}

/// Keeps the report of the latest stop until the app's next open offers it, once. It lives in the app's own
/// settings, beside the last build seen.
package struct Stops {
    private let settings: UserDefaults
    private let key = "Shell.StopWaiting"

    package init(_ settings: UserDefaults = .standard) {
        self.settings = settings
    }

    /// Keeps a report to offer; a newer stop takes the place of one not yet offered.
    package func keep(_ report: String) {
        settings.set(report, forKey: key)
    }

    /// The report waiting to be offered, if any. Once handed over it is gone, so it is never offered twice.
    package func next() -> String? {
        defer { settings.removeObject(forKey: key) }
        return settings.string(forKey: key)
    }

    /// Listens for MetricKit's reports, which arrive soon after the app opens again, and keeps each stop's.
    /// The listening lasts as long as the app.
    package static func listen(app: String) {
        Task {
            for await report in MetricManager().diagnosticReports {
                if case .crash(let crash) = report.result {
                    Stops().keep(StopReport.text(of: crash, in: report.environment, app: app))
                }
            }
        }
    }
}
