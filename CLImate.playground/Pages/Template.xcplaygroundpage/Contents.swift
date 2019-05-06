import Foundation
import CLImate
import CommonParsers
import Prelude

let name = "playground"
let year = 2019

class FastlaneTemplate: CLITemplate {
    override func longName(_ name: String) -> String {
        return "\(name):"
    }
    override func shortName(_ name: String) -> String {
        return "\(name):"
    }
    override func longOption(_ name: String) -> String {
        return name
    }
    override func shortOption(_ name: String) -> String {
        return name
    }
    override func argUsage(_ long: String?, _ short: String?, _ type: String, _ description: String) -> String {
        return "  \(long ?? "")\(short.map { " (\($0))" } ?? ""): \(description) (\(type))"
    }
    override func optionUsage(_ long: String, _ short: String?, _ description: String) -> String {
        return "  \(long)\(short.map { " (\($0))" } ?? ""): \(description)"
    }
}

let args = [
    "hello", "name:", name, "year:", "\(year)", "verbose"
]

enum Commands {
    case hello(name: String, year: Int?, verbose: Bool)
    case print(verbose: Bool)
}

extension Commands: Matchable {
    func match<A>(_ constructor: (A) -> Commands) -> A? {
        switch self {
        case let .hello(values):
            guard let a = values as? A, self == constructor(a) else { return nil }
            return a
        case let .print(values):
            guard let a = values as? A, self == constructor(a) else { return nil }
            return a
        }
    }
}

let commands = CLI<Commands>.with(template: FastlaneTemplate()) {
    [
        Commands.hello
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
        Commands.print
            <¢> command(
                name: "print",
                description: "printing"
            )
            -- option(
                name: "verbose", short: "v",
                description: "be verbose"
        )
    ]
}

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

    try commands.run(["hello", "help"]) { _ in }
} catch {
    print(error)
}
