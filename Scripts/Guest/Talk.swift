// Scripts/tour asks; the agent in the guest answers over the machine's own socket, never over IP, which
// from this Mac would need the Local Network permission and ask on the owner's screen.
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
    (try? FileHandle(fileDescriptor: fd).write(contentsOf: data)) != nil
}

func readExactly(_ fd: Int32, _ count: Int) -> Data? {
    var data = Data()
    while data.count < count {
        guard let more = try? FileHandle(fileDescriptor: fd).read(upToCount: count - data.count), !more.isEmpty
        else { return nil }
        data += more
    }
    return data
}

/// Four bytes, the high one first.
func bytes(_ value: UInt32) -> Data { Data([24, 16, 8, 0].map { UInt8(value >> $0 & 255) }) }

@discardableResult
func send(_ fd: Int32, _ kind: Frame, _ body: Data = Data()) -> Bool {
    writeAll(fd, Data([kind.rawValue]) + bytes(UInt32(body.count)) + body)
}

func receive(_ fd: Int32) -> (Frame, Data)? {
    guard let header = readExactly(fd, 5), let kind = Frame(rawValue: header[0]) else { return nil }
    let length = header[1...4].reduce(0) { $0 << 8 | Int($1) }
    guard let body = readExactly(fd, length) else { return nil }
    return (kind, body)
}

func number(_ body: Data) -> Int32 { Int32(bitPattern: body.reduce(0) { $0 << 8 | UInt32($1) }) }

// MARK: In the guest

/// Answers commands: in the guest on the virtual machine's own socket; given a path, on a local one, as the tests do.
func agent(at path: String?) -> Never {
    let listener: Int32
    if let path {
        listener = listenUnix(path)
    } else {
        listener = socket(AF_VSOCK, SOCK_STREAM, 0)
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
    }
    while true {
        let connection = accept(listener, nil, nil)
        if connection >= 0 { Thread.detachNewThread { answer(connection) } } else { usleep(100_000) }
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
        send(fd, .exit, bytes(127))
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
    state.stop()  // what it left running in the background goes too, and lets go of the output
    readers.wait()
    let status = UInt32(
        bitPattern: process.terminationReason == .exit ? process.terminationStatus : 128 + process.terminationStatus)
    state.finish { send(fd, .exit, bytes(status)) }
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

func listenUnix(_ path: String) -> Int32 {
    unlink(path)
    let listener = socket(AF_UNIX, SOCK_STREAM, 0)
    var address = unixAddress(path)
    let bound = withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            bind(listener, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
        }
    }
    guard bound == 0, listen(listener, 16) == 0 else { fail("Cannot listen at \(path).") }
    return listener
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
