import AppKit
import Foundation
import Keep
import Testing

@testable import CheteKit

/// Copies made on a pasteboard of the test's own, never the one you copy to, and watched by Chete
/// as it watches yours. Clips go to a fresh folder sealed by a key the real Chete never uses.
/// Each test removes all three when it ends.
@MainActor
private struct Copying {
    let pasteboard = NSPasteboard(name: .init("Sagar Tests · \(UUID().uuidString)"))
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let keyName = "Sagar Tests · \(UUID().uuidString)"
    let watcher: Watcher

    /// Keeping is allowed unless a test says otherwise.
    init(allowed: @escaping @MainActor () -> Bool = { true }) throws {
        watcher = Watcher(
            pasteboard: pasteboard, copies: try Copies(folder: folder, keyName: keyName), allowed: allowed)
    }

    /// Copies as an app does, by clearing the pasteboard and writing to it, then lets Chete look once.
    func copy(_ write: (NSPasteboard) -> Void) async {
        pasteboard.clearContents()
        write(pasteboard)
        await watcher.look()
    }

    func copy(_ text: String) async {
        await copy { $0.setString(text, forType: .string) }
    }

    func clips() throws -> [Clip] {
        try Clips(folder: folder.appending(path: "Clips"), keyName: keyName).all()
    }

    func removed() {
        pasteboard.releaseGlobally()
        try? Seal.forget(named: keyName)
        try? FileManager.default.removeItem(at: folder)
    }
}

/// A small picture, as a drawing app puts it on the pasteboard.
private func picture() throws -> Data {
    let image = try #require(
        NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
    return try #require(image.representation(using: .png, properties: [:]))
}

private let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
private let transient = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
private let fromOtherDevice = NSPasteboard.PasteboardType("com.apple.is-remote-clipboard")

@Test func eachKindBecomesOneClipNewestFirst() async throws {
    let copying = try Copying()
    defer { copying.removed() }
    let link = try #require(URL(string: "https://example.com/menu"))
    let png = try picture()
    await copying.copy("Meet at the ਸਾਗਰ café at 7")
    await copying.copy { $0.writeObjects([link as NSURL]) }
    await copying.copy { $0.setData(png, forType: .png) }
    let clips = try copying.clips()
    #expect(clips.count == 3)
    #expect(
        clips.map(\.kinds) == [
            [.picture(png, type: "public.png")], [.link(link)], [.text("Meet at the ਸਾਗਰ café at 7")],
        ])
}

@Test func aFileIsKeptAsWhereItIsNotACopy() async throws {
    let copying = try Copying()
    defer { copying.removed() }
    let files = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: files) }
    try FileManager.default.createDirectory(at: files, withIntermediateDirectories: true)
    let report = files.appending(path: "Report.pdf")
    let photo = files.appending(path: "Photo.jpg")
    try Data("the report's own words".utf8).write(to: report)
    try Data("a photo".utf8).write(to: photo)
    // Finder puts each file's location on the pasteboard, one item for each.
    await copying.copy { $0.writeObjects([report as NSURL, photo as NSURL]) }
    #expect(try copying.clips().map(\.kinds) == [[.file(report), .file(photo)]])
}

@Test func aPasswordIsKeptEvenWhenMarkedPrivate() async throws {
    let copying = try Copying()
    defer { copying.removed() }
    // A password manager marks what it copies as concealed and passing, so that other apps leave it out.
    await copying.copy {
        $0.declareTypes([.string, concealed, transient], owner: nil)
        $0.setString("correct-horse-battery", forType: .string)
    }
    #expect(try copying.clips().map(\.kinds) == [[.text("correct-horse-battery")]])
}

@Test func theSameThingCopiedTwiceIsOneClipOnTop() async throws {
    let copying = try Copying()
    defer { copying.removed() }
    await copying.copy("first")
    await copying.copy("second")
    await copying.copy("first")
    #expect(try copying.clips().map(\.kinds) == [[.text("first")], [.text("second")]])
}

@Test func aCopyFromAnotherDeviceIsKeptAtFirst() async throws {
    let copying = try Copying()
    defer { copying.removed() }
    await copying.copy {
        $0.declareTypes([.string, fromOtherDevice], owner: nil)
        $0.setString("from the phone", forType: .string)
    }
    #expect(try copying.clips().map(\.kinds) == [[.text("from the phone")]])
}

@Test func aCopyFromAnotherDeviceIsLeftOutWhenTurnedOff() async throws {
    let copying = try Copying()
    defer { copying.removed() }
    var settings = try Settings.read(in: copying.folder)
    settings.keepsCopiesFromOtherDevices = false
    try settings.write(in: copying.folder)
    await copying.copy {
        $0.declareTypes([.string, fromOtherDevice], owner: nil)
        $0.setString("from the phone", forType: .string)
    }
    await copying.copy("from this Mac")
    #expect(try copying.clips().map(\.kinds) == [[.text("from this Mac")]])
    #expect(try Settings.read(in: copying.folder).keepsCopiesFromOtherDevices == false)
}

@Test func whatWasThereBeforeCheteOpenedIsNotANewCopy() async throws {
    let pasteboard = NSPasteboard(name: .init("Sagar Tests · \(UUID().uuidString)"))
    defer { pasteboard.releaseGlobally() }
    pasteboard.clearContents()
    pasteboard.setString("copied before", forType: .string)
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let keyName = "Sagar Tests · \(UUID().uuidString)"
    defer {
        try? Seal.forget(named: keyName)
        try? FileManager.default.removeItem(at: folder)
    }
    let watcher = Watcher(
        pasteboard: pasteboard, copies: try Copies(folder: folder, keyName: keyName), allowed: { true })
    await watcher.look()
    #expect(try Clips(folder: folder.appending(path: "Clips"), keyName: keyName).all() == [])
}

@Test func watchingFindsACopyByItself() async throws {
    let copying = try Copying()
    defer { copying.removed() }
    copying.watcher.start()
    copying.pasteboard.clearContents()
    copying.pasteboard.setString("found without being asked", forType: .string)
    for _ in 0..<40 where try copying.clips().isEmpty {
        try await Task.sleep(for: .milliseconds(100))
    }
    #expect(try copying.clips().map(\.kinds) == [[.text("found without being asked")]])
}

/// The rules allow 1% of the processor while Chete waits: 100 ms in 10 s. Ten seconds of watching is
/// twenty looks at a pasteboard where nothing changed, timed on this thread alone.
@Test func tenSecondsOfWatchingAtRestStaysUnderTheLimit() async throws {
    let copying = try Copying()
    defer { copying.removed() }
    let before = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)
    for _ in 0..<Watcher.looksPerSecond * 10 {
        await copying.watcher.look()
    }
    let spent = Duration.nanoseconds(clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID) - before)
    #expect(spent < .milliseconds(100))
}

/// Until Paste from Other Apps is allowed, Chete reads nothing you copy, so macOS never asks copy by copy.
/// Once it is allowed, Chete keeps what you copy next, by itself, and not what was copied before.
@Test @MainActor func nothingIsReadUntilKeepingIsAllowed() async throws {
    let allowed = Allowed()
    let copying = try Copying(allowed: { allowed.on })
    defer { copying.removed() }
    await copying.copy("before it was allowed")
    #expect(try copying.clips().isEmpty)
    allowed.on = true
    await copying.watcher.look()
    #expect(try copying.clips().isEmpty)
    await copying.copy("after it was allowed")
    #expect(try copying.clips().map(\.kinds) == [[.text("after it was allowed")]])
}

/// Whether keeping is allowed, as System Settings would say, for a test to turn on.
@MainActor
private final class Allowed {
    var on = false
}
