// The hidden Mac itself: a virtual Mac on Apple's Virtualization framework, with no window and no sound.
// Every tour gets the same clean guest: an instant APFS copy of its clean disk, resumed from its saved
// memory, and thrown away afterwards, so nothing of one tour (permissions, data, pasteboard) reaches the next.
import AVFoundation
import Foundation
import ImageIO
import Virtualization

struct Machine {
    let folder: URL
    func file(_ name: String) -> URL { folder.appending(path: "Machine/\(name)") }
    /// The clean guest is one folder, Clean: its disk, its storage and its saved memory, always from one moment.
    var frozen: Bool { FileManager.default.fileExists(atPath: file("Clean/State.vzvmsave").path) }

    @MainActor
    func configuration(creating restore: VZMacOSConfigurationRequirements? = nil) throws
        -> VZVirtualMachineConfiguration
    {
        let platform = VZMacPlatformConfiguration()
        if let restore {
            try FileManager.default.createDirectory(at: file(""), withIntermediateDirectories: true)
            try restore.hardwareModel.dataRepresentation.write(to: file("HardwareModel"))
            try VZMacMachineIdentifier().dataRepresentation.write(to: file("MachineIdentifier"))
            try VZMACAddress.randomLocallyAdministered().string.write(
                to: file("MAC"), atomically: true, encoding: .utf8)
            platform.auxiliaryStorage = try VZMacAuxiliaryStorage(
                creatingStorageAt: file("AuxiliaryStorage"), hardwareModel: restore.hardwareModel, options: [])
            FileManager.default.createFile(atPath: file("Disk.img").path, contents: nil)
            let disk = try FileHandle(forWritingTo: file("Disk.img"))
            try disk.truncate(atOffset: 80 << 30)  // sparse: it takes only what the guest writes
            try disk.close()
        } else {
            platform.auxiliaryStorage = VZMacAuxiliaryStorage(url: file("AuxiliaryStorage"))
        }
        guard let model = VZMacHardwareModel(dataRepresentation: try Data(contentsOf: file("HardwareModel"))),
            let identifier = VZMacMachineIdentifier(
                dataRepresentation: try Data(contentsOf: file("MachineIdentifier"))),
            let address = VZMACAddress(string: try String(contentsOf: file("MAC"), encoding: .utf8))
        else { throw Damaged() }
        platform.hardwareModel = model
        platform.machineIdentifier = identifier

        let configuration = VZVirtualMachineConfiguration()
        configuration.platform = platform
        configuration.bootLoader = VZMacOSBootLoader()
        configuration.cpuCount = 4
        configuration.memorySize = 6 << 30
        let graphics = VZMacGraphicsDeviceConfiguration()
        graphics.displays = [
            VZMacGraphicsDisplayConfiguration(widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 80)
        ]
        configuration.graphicsDevices = [graphics]
        configuration.storageDevices = [
            VZVirtioBlockDeviceConfiguration(
                attachment: try VZDiskImageStorageDeviceAttachment(
                    url: file("Disk.img"), readOnly: false, cachingMode: .automatic, synchronizationMode: .full))
        ]
        let network = VZVirtioNetworkDeviceConfiguration()
        network.attachment = VZNATNetworkDeviceAttachment()
        network.macAddress = address
        configuration.networkDevices = [network]
        configuration.socketDevices = [VZVirtioSocketDeviceConfiguration()]
        configuration.keyboards = [VZMacKeyboardConfiguration()]
        configuration.pointingDevices = [VZMacTrackpadConfiguration()]
        configuration.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
        try configuration.validate()
        try configuration.validateSaveRestoreSupport()
        return configuration
    }

    /// The working disk and storage, copied afresh from the clean ones: APFS shares their blocks, so it is instant.
    func copyClean() throws {
        for name in ["Disk.img", "AuxiliaryStorage"] {
            try? FileManager.default.removeItem(at: file(name))
            guard clonefile(file("Clean/\(name)").path, file(name).path, 0) == 0 else { throw Damaged() }
        }
    }

    func discard() {
        for name in ["Disk.img", "AuxiliaryStorage"] { try? FileManager.default.removeItem(at: file(name)) }
    }

    /// The stopped guest and its saved memory, staged in Kept, become the clean one in a single rename; a failure
    /// before that rename leaves the old clean guest whole.
    func keepAsClean() throws {
        for name in ["Disk.img", "AuxiliaryStorage"] {
            try FileManager.default.moveItem(at: file(name), to: file("Kept/\(name)"))
        }
        try? FileManager.default.removeItem(at: file("Clean.old"))
        if FileManager.default.fileExists(atPath: file("Clean").path) {
            try FileManager.default.moveItem(at: file("Clean"), to: file("Clean.old"))
        }
        do { try FileManager.default.moveItem(at: file("Kept"), to: file("Clean")) } catch {
            try? FileManager.default.moveItem(at: file("Clean.old"), to: file("Clean"))  // the old one stays clean
            throw error
        }
        try? FileManager.default.removeItem(at: file("Clean.old"))
    }
}

@MainActor
func install(_ folder: URL) async throws {
    let machine = Machine(folder: folder)
    if !FileManager.default.fileExists(atPath: machine.file("Installed").path) {
        let restore = folder.appending(path: "Restore.ipsw")
        let image = try await VZMacOSRestoreImage.image(from: restore)
        guard let requirements = image.mostFeaturefulSupportedConfiguration, requirements.hardwareModel.isSupported
        else { fail("This Mac cannot run that version of macOS as a guest.") }
        let vm = VZVirtualMachine(configuration: try machine.configuration(creating: requirements))
        let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: restore)
        let watch = Task {
            while !Task.isCancelled {
                print("installing: \(Int(installer.progress.fractionCompleted * 100))%")
                try? await Task.sleep(for: .seconds(60))
            }
        }
        try await installer.install()
        watch.cancel()
        if vm.state != .stopped { try await vm.stop() }
        FileManager.default.createFile(atPath: machine.file("Installed").path, contents: nil)
    }
    let vm = VZVirtualMachine(configuration: try machine.configuration())

    // The first start makes the guest's one user, who logs in by itself: macOS reads these only now.
    let password = String(
        (0..<24).map { _ in "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement()! })
    guard
        FileManager.default.createFile(
            atPath: machine.file("Password").path, contents: Data(password.utf8), attributes: [.posixPermissions: 0o600]
        )
    else { fail("Cannot write the guest's password.") }
    let provisioning = VZMacGuestProvisioningOptions()
    provisioning.fullName = "Tour"
    provisioning.username = "tour"
    provisioning.password = password
    provisioning.logsInAutomatically = true
    let options = VZMacOSVirtualMachineStartOptions()
    try options.setGuestProvisioning(provisioning)
    try await vm.start(options: options)
    print("first start: the guest sets itself up")
    try await Task.sleep(for: .seconds(300))
    try await vm.stop()
    print("installed")
}

@MainActor
final class Host: NSObject, VZVirtualMachineDelegate {
    let vm: VZVirtualMachine
    let machine: Machine
    var connections: [ObjectIdentifier: VZVirtioSocketConnection] = [:]
    var signals: [any DispatchSourceSignal] = []

    init(_ machine: Machine) throws {
        if machine.frozen { try machine.copyClean() }
        self.machine = machine
        vm = VZVirtualMachine(configuration: try machine.configuration())
        super.init()
        vm.delegate = self
    }

    nonisolated func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        MainActor.assumeIsolated { if machine.frozen { machine.discard() } }
        exit(0)
    }
    nonisolated func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: any Error) {
        fail("The hidden Mac stopped: \(error.localizedDescription)")
    }

    /// Joins one asker on this Mac to the agent in the guest, waiting while the guest starts up.
    func join(_ client: Int32, tries: Int = 150) {
        guard let device = vm.socketDevices.first as? VZVirtioSocketDevice else { return }
        device.connect(toPort: port) { result in
            switch result {
            case .success(let connection):
                let key = ObjectIdentifier(connection)
                self.connections[key] = connection
                let guest = connection.fileDescriptor
                let done = DispatchGroup()
                for (from, to) in [(client, guest), (guest, client)] {
                    done.enter()
                    Thread.detachNewThread {
                        // read(2) passes on whatever has come; FileHandle would wait for the whole 64 KB
                        var buffer = [UInt8](repeating: 0, count: 65536)
                        while true {
                            let count = read(from, &buffer, buffer.count)
                            if count < 0 && errno == EINTR { continue }
                            if count <= 0 || !writeAll(to, Data(buffer[0..<count])) { break }
                        }
                        shutdown(to, SHUT_WR)
                        done.leave()
                    }
                }
                done.notify(queue: .main) {
                    close(client)
                    connection.close()
                    self.connections[key] = nil
                }
            case .failure:
                guard tries > 0 else {
                    send(client, .error, Data("The hidden Mac did not answer: its agent is not running.\n".utf8))
                    send(client, .exit, bytes(1))
                    close(client)
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.join(client, tries: tries - 1) }
            }
        }
    }

    /// SIGTERM ends the guest: a copy is thrown away at once, the guest being prepared shuts down in order.
    /// SIGUSR1 keeps the guest as it is now as the clean one.
    func listenForSignals() {
        for (number, act) in [(SIGTERM, { self.end() }), (SIGUSR1, { self.keep() })] {
            signal(number, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
            source.setEventHandler(handler: act)
            source.resume()
            signals.append(source)
        }
    }

    func end() {
        guard !machine.frozen else {
            return vm.stop { _ in
                self.machine.discard()
                exit(0)
            }
        }
        try? vm.requestStop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) { self.vm.stop { _ in exit(0) } }
    }

    func keep() {
        Task {
            do {
                try await vm.pause()
                try? FileManager.default.removeItem(at: machine.file("Kept"))
                try FileManager.default.createDirectory(at: machine.file("Kept"), withIntermediateDirectories: false)
                try await vm.saveMachineStateTo(url: machine.file("Kept/State.vzvmsave"))
                try await vm.stop()
                try machine.keepAsClean()
                print("kept as the clean guest")
                exit(0)
            } catch {
                try? FileManager.default.removeItem(at: machine.file("Kept"))  // no half-kept guest left on the drive
                fail("Could not keep the guest: \(error)")
            }
        }
    }
}

@MainActor
func serve(_ folder: URL) async throws {
    // One guest for every chat: a second `serve` finds the lock taken and leaves.
    let lock = open(folder.appending(path: "serve.lock").path, O_CREAT | O_RDWR, 0o644)
    guard lock >= 0, flock(lock, LOCK_EX | LOCK_NB) == 0 else { exit(0) }
    ftruncate(lock, 0)
    writeAll(lock, Data("\(getpid())\n".utf8))
    let machine = Machine(folder: folder)
    let host: Host
    do { host = try Host(machine) } catch {
        machine.discard()  // a guest that cannot start leaves no copy behind
        throw error
    }
    host.listenForSignals()
    let listener = listenUnix(folder.appending(path: "guest.sock").path)
    do {
        if machine.frozen {
            try await host.vm.restoreMachineStateFrom(url: machine.file("Clean/State.vzvmsave"))
            try await host.vm.resume()
        } else {
            try await host.vm.start()
        }
    } catch {
        if machine.frozen { machine.discard() }  // a guest that cannot start leaves no copy behind
        throw error
    }
    print("started")
    Thread.detachNewThread {
        while true {
            let client = accept(listener, nil, nil)
            if client >= 0 { DispatchQueue.main.async { host.join(client) } } else { usleep(100_000) }
        }
    }
}

/// Starts `serve` in a session of its own, so it outlives the chat that asked, holding none of its files open.
func start(_ folder: URL) -> Never {
    var attributes: posix_spawnattr_t?
    posix_spawnattr_init(&attributes)
    posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID | POSIX_SPAWN_CLOEXEC_DEFAULT))
    var actions: posix_spawn_file_actions_t?
    posix_spawn_file_actions_init(&actions)
    posix_spawn_file_actions_addopen(&actions, 0, "/dev/null", O_RDONLY, 0)
    let log = folder.appending(path: "serve.log").path
    posix_spawn_file_actions_addopen(&actions, 1, log, O_WRONLY | O_CREAT | O_APPEND, 0o644)
    posix_spawn_file_actions_adddup2(&actions, 1, 2)
    let me = Bundle.main.executablePath ?? CommandLine.arguments[0]
    let argv = [me, "serve", folder.path].map { strdup($0) } + [nil]
    var pid: pid_t = 0
    exit(posix_spawn(&pid, me, &actions, &attributes, argv, environ) == 0 ? 0 : 1)
}

/// Sends `serve` a signal (SIGTERM: end; SIGUSR1: keep as clean) and waits until it has gone.
func signalServe(_ folder: URL, _ number: Int32) -> Never {
    let path = folder.appending(path: "serve.lock").path
    let lock = open(path, O_RDWR)
    guard lock >= 0, flock(lock, LOCK_EX | LOCK_NB) != 0 else { exit(0) }  // nothing is running
    if let pid = pid_t((try? String(contentsOfFile: path, encoding: .utf8))?.trimmingCharacters(in: .newlines) ?? "") {
        kill(pid, number)
    }
    flock(lock, LOCK_EX)  // let go when serve ends
    exit(0)
}

/// The last frame of a tour's screen recording, as a picture: what the screen showed when the tour stopped.
@MainActor
func lastFrame(of video: URL, to picture: URL) async throws {
    let asset = AVURLAsset(url: video)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.requestedTimeToleranceBefore = .zero
    let end = try await asset.load(.duration)
    let (frame, _) = try await generator.image(at: CMTimeSubtract(end, CMTime(value: 1, timescale: 10)))
    guard let file = CGImageDestinationCreateWithURL(picture as CFURL, "public.png" as CFString, 1, nil) else {
        fail("Cannot write \(picture.path).")
    }
    CGImageDestinationAddImage(file, frame, nil)
    guard CGImageDestinationFinalize(file) else { fail("Cannot write \(picture.path).") }
}

struct Damaged: Error, CustomStringConvertible {
    var description: String { "its files are damaged, or not on an APFS drive: make it again with Scripts/tour setup." }
}
