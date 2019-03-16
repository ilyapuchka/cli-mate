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
    }

    let command: Command

    // Global options
    let verbose: Bool

    var playgroundDescription: Any {
        return "\(command) verbose: \(verbose)"
    }
}

extension Commands.Command: Matchable {
    func match<A>(_ constructor: (A) -> Commands.Command) -> A? {
        switch self {
        case let .hello(values as A) where self == constructor(values):
            return values
        case .print:
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
        guard let values = (self.command, self.verbose) as? A, self == constructor(values) else { return nil }
        return values
    }
}

let subCommands: CLI<Commands.Command> = [
    iso(Commands.Command.hello)
        <¢> command(
            name: "hello",
            description: "greeting"
        )
        <%> arg(
            name: "name", short: "n", .string, example: "playground",
            description: "a name"
        )
        <%> arg(
            name: "year", short: "y", opt(.int), example: 2019,
            description: "a year"
    ),
    iso(Commands.Command.print)
        <¢> command(
            name: "print",
            description: "printing"
    ),
]

let commands =
    iso(Commands.init)
        <¢> command(
            name: "run",
            description: "runs a command"
        )
        <%> subCommands
        <%> option(
            name: "verbose", default: false,
            description: "be verbose"
)


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
} catch {
    print(error)
}
