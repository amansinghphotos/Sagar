import Foundation
import Testing

@testable import Shell

/// A folder that looks like an app to Sparkle: an Info.plist with the given update settings.
private func app(feed: String?, key: String? = "JXPs7WUnX51U6VAYatd2DxmMPXdvoSbdpVGKp/H20hs=") throws -> Bundle {
    let folder = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).app/Contents")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var information: [String: Any] = [
        "CFBundleIdentifier": "org.example.specimen", "CFBundleName": "Specimen", "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0", "SUEnableAutomaticChecks": false,
    ]
    information["SUFeedURL"] = feed
    information["SUPublicEDKey"] = key
    try PropertyListSerialization.data(fromPropertyList: information, format: .xml, options: 0)
        .write(to: folder.appending(path: "Info.plist"))
    return try #require(Bundle(url: folder.deletingLastPathComponent()))
}

@Test func updatesStartForAnAppWithASignedFeed() throws {
    let updates = try Updates(for: app(feed: "https://example.com/specimen/appcast.xml"))
    #expect(updates.feed == URL(string: "https://example.com/specimen/appcast.xml"))
}

@Test func updatesRefuseAnAppWithNoFeed() throws {
    #expect(throws: (any Error).self) { try Updates(for: app(feed: nil)) }
}

@Test func updatesRefuseAnAppWithNoKey() throws {
    #expect(throws: (any Error).self) { try Updates(for: app(feed: "https://example.com/appcast.xml", key: nil)) }
}

/// The plan says an update is never silent. This builds a copy of the update settings every app really carries, in
/// Config/Info.plist, and asks Sparkle itself whether its window would offer a box to install updates without asking.
@Test func theUpdateWindowOffersNoBoxForSilentInstalls() throws {
    let settings = URL(filePath: #filePath).appending(path: "../../../Config/Info.plist").standardizedFileURL
    var information = try #require(
        PropertyListSerialization.propertyList(from: Data(contentsOf: settings), format: nil) as? [String: Any])
    information["CFBundleIdentifier"] = "org.example.specimen"
    information["CFBundleName"] = "Specimen"
    information["CFBundleVersion"] = "1"
    information["CFBundleShortVersionString"] = "1.0"
    let folder = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).app/Contents")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try PropertyListSerialization.data(fromPropertyList: information, format: .xml, options: 0)
        .write(to: folder.appending(path: "Info.plist"))
    let specimen = try #require(Bundle(url: folder.deletingLastPathComponent()))
    #expect(information["SUEnableAutomaticChecks"] as? Bool == true)  // so Sparkle's own default would offer the box
    #expect(!Updates.offersSilentInstalls(for: specimen))
}
