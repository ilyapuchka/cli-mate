import Foundation
import CLImate
import CommonParsers
import Prelude

let name = "playground"
let year = 2019

let args = [
    "hello", "--name", name, "--year", "\(year)", "--verbose"
    ]

enum Commands {
    case hello(name: String, year: Int?, verbose: Bool)
    case print(verbose: Bool)
}

extension Commands: Matchable {
    func match<A>(_ constructor: (A) -> Commands) -> A? {
        switch self {
        case let .hello(values as A) where self == constructor(values):
            return values
        case let .print(values as A) where self == constructor(values):
            return values
        default: return nil
        }
    }
}

let commands: CLI<Commands> = [
    iso(Commands.hello)
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
        )
        <%> option(
            name: "verbose", default: false,
            description: "be verbose"
    ),
    iso(Commands.print)
        <¢> command(
            name: "print",
            description: "printing"
        )
        <%> option(
            name: "verbose", default: false,
            description: "be verbose"
    )
    ]

do {
    print(commands.help())

    try commands.match(args)

    var cmd = Commands.hello(name: name, year: year, verbose: true)

    try commands.print(cmd)!.render()
    try commands.print(cmd).flatMap(commands.match)
    try commands.template(for: cmd)!.render()

    try commands.run(args) { (cmd) in
        print(cmd)
    }
} catch {
    print(error)
}
