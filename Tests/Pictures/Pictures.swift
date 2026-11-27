import AppKit
import SwiftUI
import Testing

/// How many pixels may differ before two pictures count as different. Edges are smoothed a little
/// differently from one Mac to the next; one changed word is far more than this.
package let tolerance = 40

/// What comparing a screen with its approved picture found.
package enum Verdict: Equatable {
    case same
    case different(pixels: Int)
    case noApprovedPicture
}

/// Why a screen could not be pictured.
package enum PictureError: Error {
    case couldNotDraw
}

/// Fails the test unless the screen matches `Pictures/<name>.png` beside the test file.
/// A new or changed picture is left in `.build/Pictures` for the owner to approve.
package func expectPicture(
    of view: some View, width: CGFloat, height: CGFloat, named name: String, dark: Bool = false,
    filePath: String = #filePath, sourceLocation: SourceLocation = #_sourceLocation
) throws {
    let approved = URL(filePath: filePath).deletingLastPathComponent().appending(path: "Pictures")
    let made = URL(filePath: FileManager.default.currentDirectoryPath).appending(path: ".build/Pictures")
    let verdict = try compare(
        view, width: width, height: height, named: name, dark: dark, approved: approved, made: made)
    #expect(verdict == .same, "\(name).png: see .build/Pictures", sourceLocation: sourceLocation)
}

/// Pictures the screen and compares it with `<name>.png` in `approved`. Unless they are the same,
/// the new picture is written to `made`.
package func compare(
    _ view: some View, width: CGFloat, height: CGFloat, named name: String, dark: Bool = false, approved: URL,
    made: URL
) throws -> Verdict {
    let image = try picture(of: view, width: width, height: height, dark: dark)
    var verdict = Verdict.noApprovedPicture
    let file = approved.appending(path: "\(name).png")
    if let expected = approvedPicture(at: file) {
        let pixels = differingPixels(image, expected)
        verdict = pixels > tolerance ? .different(pixels: pixels) : .same
    }
    if verdict != .same {
        try FileManager.default.createDirectory(at: made, withIntermediateDirectories: true)
        try NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?
            .write(to: made.appending(path: "\(name).png"))
    }
    return verdict
}

/// A window that is never put on screen and always has two pixels a point, whatever screen the Mac has.
private final class HiddenWindow: NSWindow {
    override var backingScaleFactor: CGFloat { 2 }
}

/// Pictures a screen from a real window that is never put on screen: two pixels a point, the light
/// look unless `dark`, scroll bars that show only while scrolling, drawn as the front window would be.
package func picture(of view: some View, width: CGFloat, height: CGFloat, dark: Bool = false) throws -> CGImage {
    _ = NSApplication.shared
    UserDefaults.standard.set("WhenScrolling", forKey: "AppleShowScrollBars")
    let frame = NSRect(x: 0, y: 0, width: width, height: height)
    let screen = view.frame(width: width, height: height)
        .environment(\.appearsActive, true)
        .environment(\.displayScale, 2)
    let host = NSHostingView(rootView: screen)
    let window = HiddenWindow(contentRect: frame, styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    window.contentView = host
    host.layoutSubtreeIfNeeded()
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(width * 2), pixelsHigh: Int(height * 2), bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
            bitsPerPixel: 0)
    else { throw PictureError.couldNotDraw }
    bitmap.size = frame.size
    host.cacheDisplay(in: host.bounds, to: bitmap)
    guard let drawn = bitmap.cgImage else { throw PictureError.couldNotDraw }
    return try onItsWindow(drawn, window)
}

/// A screen draws only its own contents: what lies behind them is the window's to draw. The picture
/// is laid on the window's background, as a person sees it, so that no part of it is see-through.
private func onItsWindow(_ drawn: CGImage, _ window: NSWindow) throws -> CGImage {
    var background: CGColor?
    window.effectiveAppearance.performAsCurrentDrawingAppearance {
        background = window.backgroundColor.usingColorSpace(.deviceRGB)?.cgColor
    }
    let whole = CGRect(x: 0, y: 0, width: drawn.width, height: drawn.height)
    guard let background,
        let context = CGContext(
            data: nil, width: drawn.width, height: drawn.height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else { throw PictureError.couldNotDraw }
    context.setFillColor(background)
    context.fill(whole)
    context.draw(drawn, in: whole)
    guard let image = context.makeImage() else { throw PictureError.couldNotDraw }
    return image
}

/// How many pixels differ in colour by more than a small step. Pictures of different sizes differ everywhere.
package func differingPixels(_ first: CGImage, _ second: CGImage) -> Int {
    guard first.width == second.width, first.height == second.height else { return .max }
    let one = bytes(of: first)
    let two = bytes(of: second)
    var differing = 0
    for pixel in stride(from: 0, to: one.count, by: 4)
    where (0..<4).contains(where: { abs(Int(one[pixel + $0]) - Int(two[pixel + $0])) > 24 }) {
        differing += 1
    }
    return differing
}

private func bytes(of image: CGImage) -> [UInt8] {
    var data = [UInt8](repeating: 0, count: image.width * image.height * 4)
    data.withUnsafeMutableBytes { buffer in
        let context = CGContext(
            data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
            bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }
    return data
}

/// The red, green and blue of one point of a picture, each 0 to 255. A point is two pixels across.
package func colour(at x: Int, _ y: Int, in image: CGImage) -> [Int] {
    let all = bytes(of: image)
    let pixel = ((y * 2) * image.width + x * 2) * 4
    return (0..<3).map { Int(all[pixel + $0]) }
}

/// The picture kept in a file, if there is one.
package func approvedPicture(at file: URL) -> CGImage? {
    CGImageSourceCreateWithURL(file as CFURL, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
}

/// How many pixels of a kept picture let what lies behind it show through.
package func seeThroughPixels(_ image: CGImage) -> Int {
    let all = bytes(of: image)
    return stride(from: 3, to: all.count, by: 4).count { all[$0] < 255 }
}
