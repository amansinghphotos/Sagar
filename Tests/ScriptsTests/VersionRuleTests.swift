import Foundation
import Testing

/// Asks the real release script whether one version may follow the last one that shipped.
private func follows(_ last: String, _ next: String) throws -> Bool {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/release").standardizedFileURL
    let process = Process()
    let answer = Pipe()
    process.executableURL = script
    process.arguments = ["follows", last, next]
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self) == "yes\n"
}

@Test(arguments: [
    ("", "1.0"), ("", "0.1"), ("0.1", "0.2"), ("1.4", "1.5"), ("1.4", "2.0"), ("1.9", "1.10"), ("0.2", "1.0"),
])
func theNextNumberIsAllowed(last: String, next: String) throws {
    #expect(try follows(last, next))
}

@Test(arguments: [
    ("", "0.2"), ("1.4", "1.6"), ("1.4", "1.4"), ("1.4", "1.3"), ("1.4", "1.5.1"), ("1.4", "3.0"), ("1.4", "1.05"),
    ("0.9", "1.00"), ("1.4", "2.1"), ("1.4", "v1.5"), ("1.4", "1"),
])
func anyOtherNumberIsRefused(last: String, next: String) throws {
    #expect(try !follows(last, next))
}
