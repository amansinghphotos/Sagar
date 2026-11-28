import Foundation
import Testing

/// A Mac made in a temporary folder: a home folder, a small repository holding the real rules script and start hook,
/// and the private notes beside it, each cloned from a repository standing in for GitHub.
private struct Mac {
    let top = FileManager.default.temporaryDirectory.appending(path: "new-mac-\(UUID().uuidString)")
    var home: URL { top.appending(path: "Home") }
    var work: URL { top.appending(path: "Developer/Work") }
    var notes: URL { top.appending(path: "Developer/Work Private") }

    init() throws {
        let project = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL
        for folder in ["Home/.claude", "GitHub", "Developer"] {
            try FileManager.default.createDirectory(at: top.appending(path: folder), withIntermediateDirectories: true)
        }
        for (name, place) in [("Work", work), ("Work-Private", notes)] {
            try git(["init", "-q", "--bare", "-b", "main", top.appending(path: "GitHub/\(name).git").path], in: top)
            try git(["clone", "-q", top.appending(path: "GitHub/\(name).git").path, place.path], in: top)
        }
        for file in ["Scripts/check", ".claude/hooks/start"] {
            try FileManager.default.createDirectory(
                at: work.appending(path: file).deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: project.appending(path: file), to: work.appending(path: file))
        }
        try write("Be brief.\n", to: notes.appending(path: "Claude/CLAUDE.md"))
        try write("{}\n", to: notes.appending(path: "Claude/settings.json"))
        try push(work)
        try push(notes)
    }

    func write(_ words: String, to file: URL) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try words.write(to: file, atomically: true, encoding: .utf8)
    }

    func push(_ place: URL) throws {
        try git(["add", "-A"], in: place)
        try git(
            ["-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", "A"],
            in: place)
        try git(["push", "-q", "origin", "HEAD"], in: place)
    }

    @discardableResult func git(_ arguments: [String], in place: URL) throws -> (words: String, passes: Bool) {
        try run("/usr/bin/env", ["git"] + arguments, in: place)
    }

    /// What a tool of the repository prints when run on this Mac, as its owner, and whether it passes.
    func run(_ tool: String, _ arguments: [String], in place: URL, also: [String: String] = [:]) throws -> (
        words: String, passes: Bool
    ) {
        let process = Process()
        let answer = Pipe()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        process.currentDirectoryURL = place
        // Never the chat's own settings file: a hook run here must not write into the chat that runs the tests.
        var environment = ProcessInfo.processInfo.environment.filter {
            !$0.key.hasPrefix("GIT_") && $0.key != "CLAUDE_ENV_FILE"
        }
        environment["HOME"] = home.path
        environment.merge(also) { $1 }
        process.environment = environment
        process.standardOutput = answer
        try process.run()
        process.waitUntilExit()
        let words = String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return (words, process.terminationStatus == 0)
    }

    func ready() throws -> String {
        try run(work.appending(path: ".claude/hooks/start").path, ["ready"], in: work).words
    }
    func leaving() throws -> (words: String, passes: Bool) {
        try run(work.appending(path: "Scripts/check").path, ["leaving"], in: work)
    }
}

/// A home folder with nothing in it is told each thing the owner's Claude needs, and the notes that hold a copy.
@Test func aNewHomeFolderIsToldWhatItStillNeeds() throws {
    let mac = try Mac()
    defer { try? FileManager.default.removeItem(at: mac.top) }
    let told = try mac.ready()
    #expect(told.contains("The owner's ~/.claude/CLAUDE.md\n"))
    #expect(told.contains("The agent-skills plugin\n"))
    #expect(told.contains("The taste-skill plugin\n"))
    #expect(told.contains("The cook skill\n"))
    #expect(told.contains("The salah skill\n"))
    #expect(!told.contains("private notes"))
}

/// Once the Claude instructions, plugins and skill are in, only the drive is missing, as a temporary folder is on
/// the home folder's own disk; a later change to the instructions
/// asks for a fresh copy in the notes, so the copy that travels is never old.
@Test func aMacWithEverythingIsToldNothingUntilItsInstructionsChange() throws {
    let mac = try Mac()
    defer { try? FileManager.default.removeItem(at: mac.top) }
    try mac.write("Be brief.\n", to: mac.home.appending(path: ".claude/CLAUDE.md"))
    try mac.write("{}\n", to: mac.home.appending(path: ".claude/settings.json"))
    try mac.write("cook\n", to: mac.home.appending(path: ".claude/skills/cook/SKILL.md"))
    try mac.write("salah\n", to: mac.home.appending(path: ".claude/skills/salah/SKILL.md"))
    try mac.write(
        #"{"plugins": {"agent-skills@addy-agent-skills": [{}], "taste-skill@taste-skill": [{}]}}"#,
        to: mac.home.appending(path: ".claude/plugins/installed_plugins.json"))
    #expect(try mac.ready() == "The project on its own drive, off the disk that holds the home folder\n")

    try mac.write("Be brief. Be kind.\n", to: mac.home.appending(path: ".claude/CLAUDE.md"))
    #expect(try mac.ready().contains("A fresh copy of ~/.claude/CLAUDE.md in the private notes"))
}

/// Without the notes beside the repository, the Mac is told to clone them.
@Test func aMacWithoutTheNotesIsToldToCloneThem() throws {
    let mac = try Mac()
    defer { try? FileManager.default.removeItem(at: mac.top) }
    try FileManager.default.removeItem(at: mac.notes)
    #expect(try mac.ready().contains("The private notes, cloned beside the repository as 'Work Private'"))
}

/// A chat's start on a Mac that lacks things checks, measures and tidies nothing: the Build Mac checklist asks once.
/// A token kept from earlier stands in for the keychain, and the repository is not on GitHub, so neither is asked.
@Test func aChatsStartChecksAndTidiesNothing() throws {
    let mac = try Mac()
    defer { try? FileManager.default.removeItem(at: mac.top) }
    let kept = mac.top.appending(path: "Temporary")
    try mac.write("none\n", to: kept.appending(path: "sagar-agent-token"))
    let started = try mac.run(
        mac.work.appending(path: ".claude/hooks/start").path, [], in: mac.work, also: ["TMPDIR": kept.path + "/"])
    #expect(started.words.hasPrefix("Sagar. The app in work:"))
    for words in ["Still to come", "own disk", "removed from the drive", "Copies whose work has merged"] {
        #expect(!started.words.contains(words))
    }
}

/// Everything pushed: the Mac may go. Work GitHub does not have, or a change never committed, holds it back.
@Test func aMacMayGoOnlyWhenNothingLivesOnItAlone() throws {
    let mac = try Mac()
    defer { try? FileManager.default.removeItem(at: mac.top) }
    let pushed = try mac.leaving()
    #expect(pushed.passes)
    #expect(pushed.words == "Nothing lives only on this Mac.\n")

    try mac.git(["switch", "-q", "-c", "7-a-slice"], in: mac.work)
    try mac.write("half done\n", to: mac.work.appending(path: "Slice.swift"))
    try mac.git(["add", "-A"], in: mac.work)
    try mac.git(
        ["-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", "B"],
        in: mac.work)
    try mac.write("a thought\n", to: mac.notes.appending(path: "Notes.md"))
    let held = try mac.leaving()
    #expect(!held.passes)
    #expect(held.words.contains("Work, 7-a-slice: work GitHub does not have\n"))
    #expect(held.words.contains("Work Private: changes not yet committed\n"))
}

/// On a Mac set up by the steps, a copy of the project on the home folder's own disk stops a chat and the commit gate.
@Test func aMacSetUpForTheDriveStopsWorkOffIt() throws {
    let mac = try Mac()
    defer { try? FileManager.default.removeItem(at: mac.top) }
    try mac.write("[sagar]\n\tdrive = yes\n", to: mac.home.appending(path: ".gitconfig"))
    let started = try mac.run(mac.work.appending(path: ".claude/hooks/start").path, [], in: mac.work)
    #expect(started.words.hasPrefix("Stop: this copy of the project is not on its drive."))
    let gate = try mac.run(mac.work.appending(path: "Scripts/check").path, ["folder"], in: mac.work)
    #expect(!gate.passes)
    #expect(gate.words.hasPrefix("This copy is not on the drive the project lives on"))
}

/// Runs a tool with the given home folder, and returns what it printed. It waits without holding one of the few
/// threads every test shares, so a test that waits on its own timer is never starved while a disk image is made.
private func printed(_ tool: String, _ arguments: [String], in place: URL, home: URL) async throws -> String {
    let process = Process()
    let answer = Pipe()
    process.executableURL = URL(filePath: tool)
    process.arguments = arguments
    process.currentDirectoryURL = place
    var environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
    environment["HOME"] = home.path
    process.environment = environment
    process.standardOutput = answer
    try await withCheckedThrowingContinuation { (ended: CheckedContinuation<Void, any Error>) in
        process.terminationHandler = { _ in ended.resume() }
        do { try process.run() } catch { ended.resume(throwing: error) }
    }
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

/// A drive made of a real disk image, with a small repository on it holding the real start hook, and a
/// home folder on the Mac's own disk. The image is detached and removed after `body`.
private func withADrive(_ body: (_ work: URL, _ home: URL) async throws -> Void) async throws {
    let top = FileManager.default.temporaryDirectory.appending(path: "drive-\(UUID().uuidString)")
    let drive = top.appending(path: "Drive")
    let home = top.appending(path: "Home")
    let image = top.appending(path: "Drive.sparseimage").path
    try FileManager.default.createDirectory(at: drive, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: top) }
    _ = try await printed(
        "/usr/bin/hdiutil",
        ["create", "-quiet", "-size", "200m", "-type", "SPARSE", "-fs", "APFS", "-volname", "Drive", image],
        in: top, home: home)
    _ = try await printed(
        "/usr/bin/hdiutil", ["attach", "-quiet", "-nobrowse", "-mountpoint", drive.path, image], in: top, home: home)
    do {
        let work = drive.appending(path: "Developer/Work")
        let project = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL
        for file in [".claude/hooks/start"] {
            try FileManager.default.createDirectory(
                at: work.appending(path: file).deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: project.appending(path: file), to: work.appending(path: file))
        }
        for arguments in [
            ["init", "-q", "-b", "main"], ["add", "-A"],
            ["-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", "A"],
        ] {
            _ = try await printed("/usr/bin/env", ["git"] + arguments, in: work, home: home)
        }
        try await body(work, home)
    } catch {
        _ = try? await printed("/usr/bin/hdiutil", ["detach", "-quiet", "-force", drive.path], in: top, home: home)
        throw error
    }
    _ = try await printed("/usr/bin/hdiutil", ["detach", "-quiet", "-force", drive.path], in: top, home: home)
}

/// The tests that make a disk image run one at a time: images made at once can clash.
@Suite(.serialized) struct OnADrive {
    /// On a drive of its own, the caches move beside the project, with what they hold, and a link left from an old
    /// drive is pointed at the new one.
    @Test func theCachesLiveOnTheDriveAndFollowANewOne() async throws {
        try await withADrive { work, home in
            let hook = work.appending(path: ".claude/hooks/start").path
            let usual = home.appending(path: "Library/Caches/org.swift.swiftpm")
            try FileManager.default.createDirectory(at: usual, withIntermediateDirectories: true)
            try "kept\n".write(to: usual.appending(path: "Kept"), atomically: true, encoding: .utf8)
            let caches = work.deletingLastPathComponent().appending(path: "Caches").resolvingSymlinksInPath().path
            #expect(try await printed(hook, ["ready"], in: work, home: home).contains("org.swift.swiftpm cache"))

            _ = try await printed(hook, ["caches"], in: work, home: home)
            let link = { (name: String) in
                URL(
                    filePath: try FileManager.default.destinationOfSymbolicLink(
                        atPath: home.appending(path: "Library/Caches/\(name)").path)
                ).resolvingSymlinksInPath().path
            }
            #expect(try link("org.swift.swiftpm") == caches + "/org.swift.swiftpm")
            #expect(try link("com.apple.dt.xctest.tool") == caches + "/com.apple.dt.xctest.tool")
            #expect(FileManager.default.fileExists(atPath: caches + "/org.swift.swiftpm/Kept"))
            #expect(!(try await printed(hook, ["ready"], in: work, home: home).contains("cache")))

            try FileManager.default.removeItem(at: usual)
            try FileManager.default.createSymbolicLink(
                atPath: usual.path, withDestinationPath: "/nowhere/Caches/org.swift.swiftpm")
            #expect(try await printed(hook, ["ready"], in: work, home: home).contains("org.swift.swiftpm cache"))
            _ = try await printed(hook, ["caches"], in: work, home: home)
            #expect(try link("org.swift.swiftpm") == caches + "/org.swift.swiftpm")
        }
    }
}
