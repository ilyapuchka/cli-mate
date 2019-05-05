import Foundation
import CLImate
import CommonParsers
import Prelude

let name = "playground"
let year = 2019

let args = [
    "hello", "--name", name, "--year", "\(year)", "--verbose"
]

protocol Command {
    func run()
}

func command<T, U: Command>(_ iso: PartialIso<T, U>) -> PartialIso<T, Command> {
    return PartialIso<T, Command>(
        apply: iso.apply,
        unapply: { try ($0 as? U).flatMap(iso.unapply) }
    )
}

struct HelloCommand: Command {
    let name: String
    let year: Int?
    let verbose: Bool

    static let iso = command(parenthesize(PartialIso(
        apply: { HelloCommand(name: $0, year: $1, verbose: $2) },
        unapply: { ($0.name, $0.year, $0.verbose) }
    )))

    func run() {
        print("Hello \(name). Year is \(year ?? 0)")
    }
}

struct PrintCommand: Command {
    let verbose: Bool

    static let iso = PartialIso(
        apply: { PrintCommand(verbose: $0) },
        unapply: { (cmd: Command) in (cmd as? PrintCommand).map { $0.verbose } }
    )

    func run() {
        print("Hello!")
    }
}

struct ExitCommand: Command {
    static let iso = PartialIso(
        apply: { _ in ExitCommand() },
        unapply: { (cmd: Command) in (cmd as? ExitCommand).map { _ in unit } }
    )

    func run() {}
}

let commands: CLI<Command> = [
    HelloCommand.iso
        <¢> command(
            name: "hello",
            description: "greeting"
        )
        -- arg(
            name: "name", short: "n",
            description: "a name",
            example: "playground"
        )
        -- arg(
            name: "year", short: "y",
            description: "a year",
            example: 2019
        )
        -- option(
            name: "verbose",
            description: "be verbose"
    ),
    PrintCommand.iso
        <¢> command(
            name: "print",
            description: "printing"
        )
        -- option(
            name: "verbose",
            description: "be verbose"
    ),
    ExitCommand.iso
        <¢> command(
            name: "exit",
            description: "exit program"
    )
]


do {
    print(commands.help())

    try commands.match(args)

    var cmd = HelloCommand(name: name, year: year, verbose: true)

    try commands.print(cmd)!.render()
    try commands.print(cmd).flatMap(commands.match)
    try commands.template(for: cmd)!.render()

    try commands.run(args) {
        $0.run()
    }

    try commands.run(["hello", "--help"]) {
        $0.run()
    }
} catch {
    print(error)
}
