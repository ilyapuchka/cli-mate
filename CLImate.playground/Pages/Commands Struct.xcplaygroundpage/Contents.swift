import Foundation
import CLImate
import CommonParsers
import Prelude

let name = "playground"
let year = 2019

let args = [
    "run", "hello", "--name", name, "--year", "\(year)", "--verbose"
]

struct Commands: Equatable, CustomPlaygroundDisplayConvertible {
    enum Command {
        case hello(name: String, year: Int?)
        case print
        case exit
    }

    let command: Command

    // Global options
    let verbose: Bool

    init(command: Command, verbose: Bool) {
        self.command = command
        self.verbose = verbose
    }

    init(command: Command) {
        self.command = command
        self.verbose = false
    }

    var playgroundDescription: Any {
        return "\(command) verbose: \(verbose)"
    }
}

extension Commands.Command: Matchable {
    func match<A>(_ constructor: (A) -> Commands.Command) -> A? {
        switch self {
        case let .hello(values as A) where self == constructor(values):
            return values
        case .print, .exit:
            guard let values = unit as? A, self == constructor(values) else {
                return nil
            }
            return values
        default: return nil
        }
    }
}

extension Commands: Matchable {
    func match<A>(_ constructor: (A) -> Commands) -> A? {
        if let values = (self.command, self.verbose) as? A, self == constructor(values) {
            return values
        }
        if let values = self.command as? A, self == constructor(values) {
            return values
        }
        return nil
    }
}


let helloCommand = iso(Commands.Command.hello)
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

let printCommand = iso(Commands.Command.print)
    <¢> command(
        name: "print",
        description: "printing"
)

let exitCommand = iso(Commands.Command.exit)
    <¢> command(
        name: "exit",
        description: "exit program"
)

let subCommands: CLI<Commands.Command> = [
    helloCommand,
    printCommand,
]

let commands: CLI<Commands> = [
    iso(Commands.init)
        <¢> command(
            name: "run",
            subCommands: subCommands
        )
        -- option(
            name: "verbose",
            description: "be verbose"
    ),
    iso(Commands.init)
        <¢> exitCommand
]


do {
    print(commands.help())

    try commands.match(args)

    var cmd = Commands(
        command: .hello(name: name, year: year),
        verbose: true
    )

    try commands.print(cmd)!.render()
    try commands.print(cmd).flatMap(commands.match)
    try commands.template(for: cmd)!.render()

    try commands.run(args) { (cmd) in
        print(cmd)
    }

    try commands.run(["run", "--help"]) { _ in }
} catch {
    print(error)
}
