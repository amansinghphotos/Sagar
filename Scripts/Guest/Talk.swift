// How this Mac and the hidden Mac speak: Scripts/tour asks, and the agent in the guest answers.
// Commands travel over the virtual machine's own socket, never over IP: a connection from this Mac to the
// guest's address would need the Local Network permission, which asks on the owner's screen.
import Foundation

let port: UInt32 = 7

func fail(_ words: String) -> Never {
    FileHandle.standardError.write(Data((words + "\n").utf8))
    exit(1)
}

// MARK: Frames: a kind, a four-byte length, then the bytes.

enum Frame: UInt8 { case command, input, inputEnd, output, error, exit }

@discardableResult
func writeAll(_ fd: Int32, _ data: Data) -> Bool {
    data.withUnsafeBytes { raw in
        var offset = 0
        while offset < raw.count {
            let count = write(fd, raw.baseAddress! + offset, raw.count - offset)
            if count < 0 && errno == EINTR { continue }
            if count <= 0 { return false }
            offset += count
        }
        return true
    }
}

func readExactly(_ fd: Int32, _ count: Int) -> Data? {
    var data = Data(count: count)
    let complete = data.withUnsafeMutableBytes { raw in
        var offset = 0
        while offset < count {
            let got = read(fd, raw.baseAddress! + offset, count - offset)
            if got < 0 && errno == EINTR { continue }
            if got <= 0 { return false }
            offset += got
        }
        return true
    }
    return complete ? data : nil
}

@discardableResult
func send(_ fd: Int32, _ kind: Frame, _ body: Data = Data()) -> Bool {
    let length = UInt32(body.count)
    let header = Data([
        kind.rawValue, UInt8(length >> 24), UInt8(length >> 16 & 255), UInt8(length >> 8 & 255), UInt8(length & 255),
    ])
    return writeAll(fd, header + body)
}

func receive(_ fd: Int32) -> (Frame, Data)? {
    guard let header = readExactly(fd, 5), let kind = Frame(rawValue: header[0]) else { return nil }
    let length = header[1...4].reduce(0) { $0 << 8 | Int($1) }
    guard let body = readExactly(fd, length) else { return nil }
    return (kind, body)
}

func number(_ body: Data) -> Int32 { Int32(bitPattern: body.reduce(0) { $0 << 8 | UInt32($1) }) }

// MARK: In the guest

func agent() -> Never {
    let listener = socket(AF_VSOCK, SOCK_STREAM, 0)
    var address = sockaddr_vm()
    address.svm_len = UInt8(MemoryLayout<sockaddr_vm>.size)
    address.svm_family = sa_family_t(AF_VSOCK)
    address.svm_port = port
    address.svm_cid = UInt32.max  // any
    let bound = withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            bind(listener, $0, socklen_t(MemoryLayout<sockaddr_vm>.size))
        }
    }
    guard listener >= 0, bound == 0, listen(listener, 16) == 0 else {
        fail("agent: cannot listen on the virtual socket: \(String(cString: strerror(errno)))")
    }
    while true {
        let connection = accept(listener, nil, nil)
        if connection >= 0 { Thread.detachNewThread { answer(connection) } }
    }
}

func answer(_ fd: Int32) {
    defer { close(fd) }
    guard let (kind, body) = receive(fd), kind == .command, let command = String(data: body, encoding: .utf8) else {
        return
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", command]
    let input = Pipe()
    let output = Pipe()
    let error = Pipe()
    process.standardInput = input
    process.standardOutput = output
    process.standardError = error
    do { try process.run() } catch {
        send(fd, .error, Data("agent: \(error)\n".utf8))
        send(fd, .exit, Data([0, 0, 0, 127]))
        return
    }
    // The command leads a process group of its own: when its asker goes, all it started is stopped, so a
    // tour left behind never holds the guest's screen against the next chat's.
    let state = Answer(group: process.processIdentifier)
    let readers = DispatchGroup()
    for (pipe, kind) in [(output, Frame.output), (error, Frame.error)] {
        let source = pipe.fileHandleForReading.fileDescriptor
        readers.enter()
        Thread.detachNewThread {
            var buffer = [UInt8](repeating: 0, count: 65536)
            while true {
                let count = read(source, &buffer, buffer.count)
                if count < 0 && errno == EINTR { continue }
                if count <= 0 { break }
                if !state.sending({ send(fd, kind, Data(buffer[0..<count])) }) { state.stop() }
            }
            readers.leave()
        }
    }
    let sink = input.fileHandleForWriting
    let asker = DispatchGroup()
    asker.enter()
    Thread.detachNewThread {
        var open = true
        while let (kind, body) = receive(fd) {
            if kind == .input && open { writeAll(sink.fileDescriptor, body) }
            if kind == .inputEnd && open {
                try? sink.close()
                open = false
            }
        }
        if open { try? sink.close() }
        state.stop()  // the asker has gone, or has its answer: either way nothing of its command goes on
        asker.leave()
    }
    process.waitUntilExit()
    readers.wait()
    let status = UInt32(
        bitPattern: process.terminationReason == .exit ? process.terminationStatus : 128 + process.terminationStatus)
    state.finish {
        send(
            fd, .exit,
            Data([UInt8(status >> 24), UInt8(status >> 16 & 255), UInt8(status >> 8 & 255), UInt8(status & 255)]))
    }
    shutdown(fd, SHUT_RDWR)  // wakes the reader of the asker, so the socket is closed only after it has let go
    asker.wait()
}

/// One command's state, shared by the threads that answer for it.
final class Answer: @unchecked Sendable {
    let group: pid_t
    let lock = NSLock()
    var finished = false
    init(group: pid_t) { self.group = group }
    func sending(_ write: () -> Bool) -> Bool { lock.withLock(write) }
    func stop() { lock.withLock { if !finished { kill(-group, SIGTERM) } } }
    func finish(_ write: () -> Bool) {
        lock.withLock {
            finished = true
            _ = write()
        }
    }
}

func unixAddress(_ path: String) -> sockaddr_un {
    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    withUnsafeMutableBytes(of: &address.sun_path) { raw in
        guard path.utf8.count < raw.count else {
            fail("\(path): too long a path for a socket; keep the project's path short.")
        }
        raw.copyBytes(from: Array(path.utf8) + [0])
    }
    return address
}

// MARK: On this Mac: asking

func connectUnix(_ path: String) -> Int32 {
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    var address = unixAddress(path)
    let connected = withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
        }
    }
    if connected != 0 { close(fd) }
    return connected == 0 ? fd : -1
}

func run(_ folder: URL, _ command: String) -> Never {
    let fd = connectUnix(folder.appending(path: "guest.sock").path)
    guard fd >= 0 else { fail("The hidden Mac is not running.") }
    send(fd, .command, Data(command.utf8))
    Thread.detachNewThread {
        var buffer = [UInt8](repeating: 0, count: 65536)
        while true {
            let count = read(0, &buffer, buffer.count)
            if count < 0 && errno == EINTR { continue }
            if count <= 0 || !send(fd, .input, Data(buffer[0..<count])) { break }
        }
        send(fd, .inputEnd)
    }
    while let (kind, body) = receive(fd) {
        switch kind {
        case .output: if !writeAll(1, body) { exit(141) }  // its reader has gone: so does the command
        case .error: writeAll(2, body)
        case .exit: exit(number(body))
        default: break
        }
    }
    fail("The hidden Mac stopped answering.")
}

/// Starts `serve` in a session of its own, so it outlives the chat that asked, holding none of its files open.
func start(_ folder: URL) -> Never {
    var attributes: posix_spawnattr_t?
    posix_spawnattr_init(&attributes)
    posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID | POSIX_SPAWN_CLOEXEC_DEFAULT))
    var actions: posix_spawn_file_actions_t?
    posix_spawn_file_actions_init(&actions)
    posix_spawn_file_actions_addopen(&actions, 0, "/dev/null", O_RDONLY, 0)
    posix_spawn_file_actions_addopen(
        &actions, 1, folder.appending(path: "serve.log").path, O_WRONLY | O_CREAT | O_APPEND, 0o644)
    posix_spawn_file_actions_adddup2(&actions, 1, 2)
    let me = Bundle.main.executablePath ?? CommandLine.arguments[0]
    let argv = [me, "serve", folder.path].map { strdup($0) } + [nil]
    var pid: pid_t = 0
    exit(posix_spawn(&pid, me, &actions, &attributes, argv, environ) == 0 ? 0 : 1)
}

/// Runs a program once no other chat's is running: one tour at a time, in the order asked.
func turn(_ folder: URL, _ who: String, _ program: [String]) -> Never {
    let path = folder.appending(path: "turn.lock").path
    let lock = open(path, O_CREAT | O_RDWR, 0o644)
    guard lock >= 0 else { fail("Cannot open \(path).") }
    if flock(lock, LOCK_EX | LOCK_NB) != 0 {
        let holder = (try? String(contentsOfFile: path, encoding: .utf8)) ?? "another chat"
        writeAll(
            1,
            Data(
                "The hidden Mac is busy with \(holder.trimmingCharacters(in: .whitespacesAndNewlines)); waiting in line.\n"
                    .utf8))
        flock(lock, LOCK_EX)
    }
    ftruncate(lock, 0)
    writeAll(lock, Data((who + "\n").utf8))
    let argv = program.map { strdup($0) } + [nil]
    execvp(program[0], argv)  // the lock stays held by the program, and is let go when it ends
    fail("Cannot run \(program[0]).")
}
