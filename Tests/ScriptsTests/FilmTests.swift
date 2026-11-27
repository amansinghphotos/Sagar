import AVFoundation
import Foundation
import ImageIO
import Testing

private let root = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL

/// A real movie, as a tour records one: two seconds at 30 frames a second, 1600 by 1000 pixels, going from black to
/// white, written with AVFoundation into a temporary folder.
private func movie(in folder: URL) async throws -> URL {
    let file = folder.appending(path: "Tour.mp4")
    let writer = try AVAssetWriter(outputURL: file, fileType: .mp4)
    let input = AVAssetWriterInput(
        mediaType: .video,
        outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 1600, AVVideoHeightKey: 1000])
    let frames = writer.inputPixelBufferReceiver(for: input, pixelBufferAttributes: nil)
    try writer.start()
    writer.startSession(atSourceTime: .zero)
    for frame in 0..<60 {
        try await frames.append(grey(frame * 4), with: CMTime(value: CMTimeValue(frame), timescale: 30))
    }
    frames.finish()
    await writer.finishWriting()
    return file
}

/// One frame of the movie, every pixel the same grey.
private func grey(_ shade: Int) throws -> CVReadOnlyPixelBuffer {
    var buffer: CVPixelBuffer?
    CVPixelBufferCreate(nil, 1600, 1000, kCVPixelFormatType_32BGRA, nil, &buffer)
    guard let pixels = buffer else { throw CocoaError(.featureUnsupported) }
    CVPixelBufferLockBaseAddress(pixels, [])
    memset(CVPixelBufferGetBaseAddress(pixels), Int32(shade), CVPixelBufferGetDataSize(pixels))
    CVPixelBufferUnlockBaseAddress(pixels, [])
    return CVReadOnlyPixelBuffer(unsafeBuffer: pixels)
}

@Test func aTourRecordingBecomesAFilmThatShowsInADescription() async throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let film = folder.appending(path: "Tour.gif")
    let process = Process()
    process.executableURL = root.appending(path: "Scripts/film")
    process.arguments = ["gif", try await movie(in: folder).path, film.path]
    try process.run()
    process.waitUntilExit()
    #expect(process.terminationStatus == 0)

    // An animated picture, which GitHub shows in a description as it shows a still, playing for ever. It holds every
    // picture the movie does, each for as long as the movie showed it, at most 800 pixels wide.
    let source = try #require(CGImageSourceCreateWithURL(film as CFURL, nil))
    #expect(CGImageSourceGetType(source) as String? == "com.compuserve.gif")
    #expect(CGImageSourceGetCount(source) == 60)
    let first = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    #expect(first[kCGImagePropertyPixelWidth] as? Int == 800)
    let delays = (0..<CGImageSourceGetCount(source)).compactMap {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, $0, nil) as? [CFString: Any]
        let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        return gif?[kCGImagePropertyGIFDelayTime] as? Double
    }
    #expect(abs(delays.reduce(0, +) - 2) < 0.02, "it plays for as long as the movie did")
}
