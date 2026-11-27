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
    func run(_ tool: String, _ arguments: [String], in place: URL) throws -> (words: String, passes: Bool) {
        let process = Process()
        let answer = Pipe()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        process.currentDirectoryURL = place
        var environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        environment["HOME"] = home.path
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

/// Of the chats' copies, only one whose work has merged, that holds no changes and is still there, is left behind.
@Test func onlyACleanCopyOfMergedWorkIsListedAsLeftBehind() throws {
    let mac = try Mac()
    defer { try? FileManager.default.removeItem(at: mac.top) }
    let copies = mac.top.appending(path: "Copies")
    for (name, branch) in [("done", "1-done"), ("gone", "2-gone"), ("busy", "3-busy")] {
        try mac.git(["worktree", "add", "-q", "-b", branch, copies.appending(path: name).path], in: mac.work)
    }
    try FileManager.default.removeItem(at: copies.appending(path: "gone"))
    try mac.write("half done\n", to: copies.appending(path: "busy/Slice.swift"))
    let merged = try mac.git(["rev-parse", "HEAD"], in: mac.work).words
    let left = try mac.run(
        "/bin/bash", ["-c", "printf '%s' \"$0\" | .claude/hooks/start leftovers", merged], in: mac.work)
    #expect(left.words == "done ")
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

/// Runs a tool with the given home folder, and returns what it printed.
private func printed(_ tool: String, _ arguments: [String], in place: URL, home: URL) throws -> String {
    let process = Process()
    let answer = Pipe()
    process.executableURL = URL(filePath: tool)
    process.arguments = arguments
    process.currentDirectoryURL = place
    var environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
    environment["HOME"] = home.path
    process.environment = environment
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

/// A drive made of a real disk image, with a small repository on it holding the real start hook and numbers, and a
/// home folder on the Mac's own disk. The image is detached and removed after `body`.
private func onADrive(_ body: (_ work: URL, _ home: URL) throws -> Void) throws {
    let top = FileManager.default.temporaryDirectory.appending(path: "drive-\(UUID().uuidString)")
    let drive = top.appending(path: "Drive")
    let home = top.appending(path: "Home")
    let image = top.appending(path: "Drive.sparseimage").path
    try FileManager.default.createDirectory(at: drive, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: top) }
    _ = try printed(
        "/usr/bin/hdiutil",
        ["create", "-quiet", "-size", "200m", "-type", "SPARSE", "-fs", "APFS", "-volname", "Drive", image],
        in: top, home: home)
    _ = try printed(
        "/usr/bin/hdiutil", ["attach", "-quiet", "-nobrowse", "-mountpoint", drive.path, image], in: top, home: home)
    defer { _ = try? printed("/usr/bin/hdiutil", ["detach", "-quiet", "-force", drive.path], in: top, home: home) }
    let work = drive.appending(path: "Developer/Work")
    let project = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL
    for file in [".claude/hooks/start", "CONSTRAINTS.md", ".gitignore"] {
        try FileManager.default.createDirectory(
            at: work.appending(path: file).deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: project.appending(path: file), to: work.appending(path: file))
    }
    let git = { (arguments: [String]) in _ = try printed("/usr/bin/env", ["git"] + arguments, in: work, home: home) }
    try git(["init", "-q", "-b", "main"])
    try git(["add", "-A"])
    try git(["-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", "A"])
    try body(work, home)
}

/// The tests that make a disk image run one at a time: images made at once can clash.
@Suite(.serialized) struct OnADrive {
    /// On a drive of its own, a real disk image here, the caches move beside the project, with what they hold, and a
    /// link left from an old drive is pointed at the new one.
    @Test func theCachesLiveOnTheDriveAndFollowANewOne() throws {
        let top = FileManager.default.temporaryDirectory.appending(path: "drive-\(UUID().uuidString)")
        let drive = top.appending(path: "Drive")
        let home = top.appending(path: "Home")
        let image = top.appending(path: "Drive.sparseimage").path
        try FileManager.default.createDirectory(at: drive, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: top) }
        _ = try printed(
            "/usr/bin/hdiutil",
            [
                "create", "-quiet", "-size", "200m", "-type", "SPARSE", "-fs", "APFS", "-volname", "Drive",
                image,
            ], in: top, home: home)
        _ = try printed(
            "/usr/bin/hdiutil", ["attach", "-quiet", "-nobrowse", "-mountpoint", drive.path, image], in: top, home: home
        )
        defer { _ = try? printed("/usr/bin/hdiutil", ["detach", "-quiet", "-force", drive.path], in: top, home: home) }

        let work = drive.appending(path: "Developer/Work")
        let hook = work.appending(path: ".claude/hooks/start")
        try FileManager.default.createDirectory(at: hook.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: URL(filePath: #filePath).appending(path: "../../../.claude/hooks/start").standardizedFileURL, to: hook)
        _ = try printed("/usr/bin/env", ["git", "init", "-q"], in: work, home: home)
        let usual = home.appending(path: "Library/Caches/org.swift.swiftpm")
        try FileManager.default.createDirectory(at: usual, withIntermediateDirectories: true)
        try "kept\n".write(to: usual.appending(path: "Kept"), atomically: true, encoding: .utf8)
        let caches = drive.appending(path: "Developer/Caches").resolvingSymlinksInPath().path
        #expect(try printed(hook.path, ["ready"], in: work, home: home).contains("org.swift.swiftpm cache"))

        _ = try printed(hook.path, ["caches"], in: work, home: home)
        let link = { (name: String) in
            URL(
                filePath: try FileManager.default.destinationOfSymbolicLink(
                    atPath: home.appending(path: "Library/Caches/\(name)").path)
            ).resolvingSymlinksInPath().path
        }
        #expect(try link("org.swift.swiftpm") == caches + "/org.swift.swiftpm")
        #expect(try link("com.apple.dt.xctest.tool") == caches + "/com.apple.dt.xctest.tool")
        #expect(FileManager.default.fileExists(atPath: caches + "/org.swift.swiftpm/Kept"))
        #expect(!(try printed(hook.path, ["ready"], in: work, home: home).contains("cache")))

        try FileManager.default.removeItem(at: usual)
        try FileManager.default.createSymbolicLink(
            atPath: usual.path, withDestinationPath: "/nowhere/Caches/org.swift.swiftpm")
        #expect(try printed(hook.path, ["ready"], in: work, home: home).contains("org.swift.swiftpm cache"))
        _ = try printed(hook.path, ["caches"], in: work, home: home)
        #expect(try link("org.swift.swiftpm") == caches + "/org.swift.swiftpm")
    }

    /// With the project on its drive, a build or a project left on the Mac's own disk is named at each chat's start; a
    /// home folder with neither is told nothing.
    @Test func aStrayBuildOrProjectOnTheMacsOwnDiskIsNamed() throws {
        try onADrive { work, home in
            let hook = work.appending(path: ".claude/hooks/start").path
            #expect(try printed(hook, ["lean"], in: work, home: home) == "")
            let stray = home.appending(path: "Library/Developer/Xcode/DerivedData/Stray")
            try FileManager.default.createDirectory(at: stray, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(
                at: home.appending(path: "Code/Old/.git"), withIntermediateDirectories: true)
            let told = try printed(hook, ["lean"], in: work, home: home)
            #expect(told.contains("Builds on the Mac's own disk: ~/Library/Developer/Xcode/DerivedData\n"))
            #expect(told.contains("A project or its build on the Mac's own disk: ~/Code/Old/.git\n"))
        }
    }

    /// On the drive, a finished chat's copy untouched for a day is removed. These stay: one touched today, one holding
    /// changes, one busy deep inside, one holding ignored files that are not builds, and one whose work has not merged.
    @Test func aFinishedCopyUntouchedForADayIsRemoved() throws {
        try onADrive { work, home in
            let copies = work.deletingLastPathComponent().appending(path: "Copies")
            let run = { (tool: String, arguments: [String]) in try printed(tool, arguments, in: work, home: home) }
            let merged = try run("/usr/bin/env", ["git", "rev-parse", "HEAD"])
            for name in ["old", "fresh", "busy", "deep", "local", "unmerged"] {
                _ = try run(
                    "/usr/bin/env", ["git", "worktree", "add", "-q", "-b", name, copies.appending(path: name).path])
            }
            let place = { (copy: String, file: String) in copies.appending(path: "\(copy)/\(file)") }
            try "half done\n".write(to: place("busy", "Slice.swift"), atomically: true, encoding: .utf8)
            try FileManager.default.createDirectory(at: place("local", ".claude"), withIntermediateDirectories: true)
            try "{}\n".write(to: place("local", ".claude/settings.local.json"), atomically: true, encoding: .utf8)
            try FileManager.default.createDirectory(at: place("old", ".build"), withIntermediateDirectories: true)
            try "built\n".write(to: place("old", ".build/Old.o"), atomically: true, encoding: .utf8)
            _ = try run(
                "/bin/bash",
                [
                    "-c",
                    "cd \"$0\" && git -c user.name=T -c user.email=t@users.noreply.github.com commit -q --allow-empty -m B",
                    copies.appending(path: "unmerged").path,
                ])
            for name in ["old", "busy", "deep", "local", "unmerged"] {
                _ = try run(
                    "/bin/bash",
                    ["-c", "find \"$0\" -exec touch -h -t 202601010000 {} +", copies.appending(path: name).path])
            }
            try FileManager.default.createDirectory(at: place("deep", ".build"), withIntermediateDirectories: true)
            try "building\n".write(to: place("deep", ".build/Now.o"), atomically: true, encoding: .utf8)
            let hook = work.appending(path: ".claude/hooks/start").path
            let removed = try run("/bin/bash", ["-c", "printf '%s' \"$1\" | \"$0\" tidy", hook, merged])
            #expect(removed == "old ")
            #expect(!FileManager.default.fileExists(atPath: copies.appending(path: "old").path))
            for name in ["fresh", "busy", "deep", "local", "unmerged"] {
                #expect(FileManager.default.fileExists(atPath: copies.appending(path: name).path))
            }
        }
    }
}
