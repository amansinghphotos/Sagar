// The hidden Mac that tours run in, which Scripts/tour builds and drives. Each command's use: its usage line.
import Foundation

signal(SIGPIPE, SIG_IGN)  // a write to an asker that has gone fails, rather than ending this program
let arguments = CommandLine.arguments.dropFirst()
let folder = URL(fileURLWithPath: arguments.dropFirst().first ?? ".")
switch arguments.first {
case "agent": agent(at: arguments.count == 2 ? String(arguments.last!) : nil)
case "run" where arguments.count >= 3: run(folder, arguments.dropFirst(2).joined(separator: " "))
case "turn" where arguments.count >= 4: turn(folder, arguments.dropFirst(2).first!, Array(arguments.dropFirst(3)))
default: fail("usage: guest run <folder> <command> | turn <folder> <who> <program…> | agent [<socket>]")
}
