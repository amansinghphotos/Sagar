// The hidden Mac that tours run in, which Scripts/tour builds and drives. Each command's use: its usage line.
import Foundation
import Virtualization

signal(SIGPIPE, SIG_IGN)  // a write to an asker that has gone fails, rather than ending this program
let arguments = CommandLine.arguments.dropFirst()
let folder = URL(fileURLWithPath: arguments.dropFirst().first ?? ".")
switch arguments.first {
case "agent": agent(at: arguments.count == 2 ? String(arguments.last!) : nil)
case "run" where arguments.count >= 3: run(folder, arguments.dropFirst(2).joined(separator: " "))
case "turn" where arguments.count >= 4: turn(folder, arguments.dropFirst(2).first!, Array(arguments.dropFirst(3)))
case "latest":
    Task {
        do { print(try await VZMacOSRestoreImage.latestSupported.url.absoluteString) } catch { fail("\(error)") }
        exit(0)
    }
case "install" where arguments.count == 2:
    Task {
        do { try await install(folder) } catch { fail("Could not make the hidden Mac: \(error)") }
        exit(0)
    }
case "serve" where arguments.count == 2:
    Task { do { try await serve(folder) } catch { fail("Could not start the hidden Mac: \(error)") } }
case "start" where arguments.count == 2: start(folder)
case "stop" where arguments.count == 2: signalServe(folder, SIGTERM)
case "keep" where arguments.count == 2: signalServe(folder, SIGUSR1)
case "frame" where arguments.count == 3:
    Task {
        do { try await lastFrame(of: folder, to: URL(fileURLWithPath: String(arguments.last!))) } catch {
            fail("\(error)")
        }
        exit(0)
    }
default:
    fail(
        "usage: guest run <folder> <command> | turn <folder> <who> <program…> | agent [<socket>] | latest"
            + " | install <folder> | start <folder> | stop <folder> | keep <folder> | frame <video> <picture>")
}
dispatchMain()
