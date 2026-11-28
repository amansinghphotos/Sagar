import Foundation
import Testing

/// Gives the real rules script a tour's record, as xcresulttool lists its tests, and returns what it prints.
private func reported(by record: String) throws -> String {
    try Script.run(Script.check, ["findings"], input: Script.recorded("\(record).json")).words
}

/// The record is a real run of three made-up steps, with its path and the Mac's identifiers made up, reported as Chete's tour reports an audit finding: one step with
/// two findings, which XCTest counts as expected failures, one that passes, and one that fails.
@Test func eachAuditFindingIsWrittenIntoTheSummary() throws {
    #expect(
        try reported(by: "A Tour With Audit Findings") == """
            note: Accessibility audit, reported, not failing (decision 9): Window: Parent/Child mismatch: element: none named
            note: Accessibility audit, reported, not failing (decision 9): Settings: Element has no description: TextField “”

            """)
}

/// Decision 9 lets audit findings pass, and nothing else: in the same record, the step that failed still failed.
@Test func aStepThatFailsBesideTheFindingsStillFails() throws {
    let record = try JSONSerialization.jsonObject(
        with: Script.recorded("A Tour With Audit Findings.json"))
    #expect(steps(in: record)["testAStepThatFails()"] == "Failed")
    #expect(steps(in: record)["testAFindingIsReported()"] == "Expected Failure")
    #expect(try !reported(by: "A Tour With Audit Findings").contains("Typing did not narrow the list"))
}

/// Each step of a record, by name, and how it ended.
private func steps(in node: Any) -> [String: String] {
    var found: [String: String] = [:]
    if let node = node as? [String: Any] {
        if node["nodeType"] as? String == "Test Case", let name = node["name"] as? String {
            found[name] = node["result"] as? String
        }
        for child in node.values { found.merge(steps(in: child)) { first, _ in first } }
    } else if let nodes = node as? [Any] {
        for child in nodes { found.merge(steps(in: child)) { first, _ in first } }
    }
    return found
}
