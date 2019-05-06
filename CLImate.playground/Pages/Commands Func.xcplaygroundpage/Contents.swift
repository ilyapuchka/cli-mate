import Foundation
import CLImate
import CommonParsers
import Prelude

let name = "playground"
let year = 2019

let args = [
    "hello", "--name", name, "--year", "\(year)", "--verbose"
]

func hello(name: String, year: Int?, verbose: Bool) -> Command {
    return Command(args: (name, year, verbose)) {
        print("Hello \(name). Year is \(year ?? 0)")
    }
}

func bye(name: String, year: Int?, verbose: Bool) -> Command {
    return Command(args: (name, year, verbose)) {
        print("Bye \(name). Year is \(year ?? 0)")
    }
}

func print(verbose: Bool) -> Command {
    return Command(args: verbose) {
        print("Hello!")
    }
}

func exit() -> Command {
    return Command(args: unit) {
        print("Exit!")
    }
}

let commands: CLI<Command> = [
    Command.make(hello)
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
    Command.make(bye)
        <¢> command(
            name: "bye",
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
    Command.make(print)
        <¢> command(
            name: "print",
            description: "printing"
        )
        -- option(
            name: "verbose",
            description: "be verbose"
    ),
    Command.make(exit)
        <¢> command(
            name: "exit",
            description: "exit program"
    )
]


do {
    try commands.run(["--help"]) {
        $0.run()
    }

    try commands.match(args)

    var cmd = hello(name: name, year: year, verbose: true)

    try commands.print(cmd)!.render()
    try commands.print(cmd).flatMap(commands.match)
    try commands.template(for: cmd)!.render()

    try commands.run(args) {
        $0.run()
    }
} catch {
    print(error)
}
