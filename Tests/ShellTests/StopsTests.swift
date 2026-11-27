import Foundation
import MetricKit
import Testing

@testable import Shell

/// The home folder of the Mac running the test, so the paths in the stop are real ones.
private let home = NSHomeDirectory()

/// A made-up stop, in the shape MetricKit hands over, laced with what a report must never hold: a name,
/// a password, words from the app, paths in the home folder, the region, the process, and another binary's code.
private let crash = """
    {"callStackTree": {"callStackPerThread": true,
      "binaryInfo": [{"uuid": "6E2B4F0A-1C3D-4E5F-8A9B-0C1D2E3F4A5B", "name": "Specimen"},
                     {"uuid": "11111111-2222-3333-4444-555555555555", "name": "libsystem_kernel.dylib"}],
      "callStackThreads": [
        {"threadAttributed": false, "rootFrames": [{"binaryUUID": "6E2B4F0A-1C3D-4E5F-8A9B-0C1D2E3F4A5B",
          "address": 4295000777, "offsetIntoBinaryTextSegment": 777, "subFrames": []}]},
        {"threadAttributed": true, "rootFrames": [
          {"binaryUUID": "11111111-2222-3333-4444-555555555555", "address": 6000000000,
           "offsetIntoBinaryTextSegment": 4096, "subFrames": [
            {"binaryUUID": "6E2B4F0A-1C3D-4E5F-8A9B-0C1D2E3F4A5B", "address": 4295012345,
             "offsetIntoBinaryTextSegment": 12345, "subFrames": [
              {"binaryUUID": "6E2B4F0A-1C3D-4E5F-8A9B-0C1D2E3F4A5B", "address": 4295000255,
               "offsetIntoBinaryTextSegment": 255, "subFrames": []}]}]}]}]},
     "terminationReason": "Namespace SIGNAL, Code 11, \(home)/Documents/Bank.txt",
     "virtualMemoryRegionInfo": "0 is not in any region, near \(home)/Library/Specimen",
     "exceptionType": 1, "exceptionCode": 0, "signal": 11, "terminationCategory": "badAccess",
     "exceptionReason": {"composedMessage": "Rosa copied hunter2", "formatString": "%@ copied %@",
       "arguments": ["Rosa", "hunter2"], "exceptionType": "NSException", "className": "NSException",
       "exceptionName": "NSInvalidArgumentException"}}
    """

private let environment = """
    {"regionFormat": "GB", "osVersion": {"platform": "macOS", "number": "27.1", "buildNumber": "27B55"},
     "deviceType": "Mac16,10", "platformArchitecture": "arm64e", "lowPowerModeEnabled": false,
     "isTestFlightApp": false, "applicationVersion": "1.0", "applicationBuildVersion": "20261127.1600",
     "pid": 4242, "bundleIdentifier": "org.example.specimen", "signpostData": [], "states": []}
    """

private func made<T: Decodable>(_ json: String) throws -> T {
    try JSONDecoder().decode(T.self, from: Data(json.utf8))
}

/// A settings store of its own, emptied when the test is done.
private func withSettings(_ body: (UserDefaults) throws -> Void) throws {
    let name = "org.example.specimen.\(UUID().uuidString)"
    let settings = try #require(UserDefaults(suiteName: name))
    defer { settings.removePersistentDomain(forName: name) }
    try body(settings)
}

@Test func aReportHoldsOnlyTheAppTheMacAndWhereItStopped() throws {
    let text = StopReport.text(of: try made(crash), in: try made(environment), app: "Specimen")
    #expect(
        text == """
            Specimen 1.0, build 20261127.1600, stopped unexpectedly.
            Mac16,10, macOS 27.1.
            Where it stopped in Specimen 6E2B4F0A-1C3D-4E5F-8A9B-0C1D2E3F4A5B:
            0x3039
            0xff
            """)
}

@Test func aReportNeverHoldsAnythingPersonal() throws {
    let text = StopReport.text(of: try made(crash), in: try made(environment), app: "Specimen")
    for never in [
        "Rosa", "hunter2", home, "Bank", "GB", "4242", "org.example", "libsystem", "0x1000", "Namespace",
    ] {
        #expect(!text.contains(never), "The report holds \(never)")
    }
}

@Test func aKeptReportIsOfferedOnceOnly() throws {
    try withSettings { settings in
        Stops(settings).keep("Specimen stopped.")
        #expect(Stops(settings).next() == "Specimen stopped.")
        #expect(Stops(settings).next() == nil)
    }
}

@Test func aNewerStopTakesThePlaceOfOneNotYetOffered() throws {
    try withSettings { settings in
        Stops(settings).keep("The first stop.")
        Stops(settings).keep("The second stop.")
        #expect(Stops(settings).next() == "The second stop.")
        #expect(Stops(settings).next() == nil)
    }
}

@Test func nothingIsOfferedWhenTheAppNeverStopped() throws {
    try withSettings { settings in
        #expect(Stops(settings).next() == nil)
    }
}
