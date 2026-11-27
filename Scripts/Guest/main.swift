// The hidden Mac that tours run in. Scripts/tour builds this program and drives it; a chat need not call it.
//
// On this Mac:   guest run <folder> <cmd>  runs a shell command in the guest; standard input goes with it
//                guest turn <folder> <who> <program…>  runs the program when no other chat's is running
// In the guest:  guest agent               answers `run`
import Foundation

signal(SIGPIPE, SIG_IGN)  // a write to an asker that has gone fails, rather than ending this program
let arguments = CommandLine.arguments.dropFirst()
let folder = URL(fileURLWithPath: arguments.dropFirst().first ?? ".")
switch arguments.first {
case "agent": agent()
case "run" where arguments.count >= 3: run(folder, arguments.dropFirst(2).joined(separator: " "))
case "turn" where arguments.count >= 4: turn(folder, arguments.dropFirst(2).first!, Array(arguments.dropFirst(3)))
default: fail("usage: guest run <folder> <command> | turn <folder> <who> <program…> | agent")
}
