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
    case fastlane(lane: String, options: [String])
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
        case let .fastlane(values):
            guard let a = values as? A, self == constructor(a) else { return nil }
            return a
        }
    }
}

let commands: CLI<Commands> = [
    Commands.hello
        <¢> command(
            name: "hello",
            description: "greeting"
        )
        -- arg(
            name: "name", short: "n", example: "playground",
            description: "a name"
        )
        -- arg(
            name: "year", short: "y", example: 2019,
            description: "a year"
        )
        -- option(
            name: "verbose", default: false,
            description: "be verbose"
    ),
    Commands.print
        <¢> command(
            name: "print",
            description: "printing"
        )
        -- option(
            name: "verbose", short: "v", default: false,
            description: "be verbose"
    ),
    Commands.fastlane
        <¢> command(
            name: "/fastlane",
            description: "run lane"
        )
        -- arg(
            name: nil, .string, example: "test_babylon",
            description: "name of the lane"
        )
        -- varArg(
            example: ["branch:develop"],
            description: "lane options"
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

    try commands.run(["help", "--help"]) { _ in }

    try commands.run(["/fastlane", "test", "branch:develop", "device:iPhone5"]) { (cmd) in
        print(cmd)
    }

} catch {
    print(error)
}
