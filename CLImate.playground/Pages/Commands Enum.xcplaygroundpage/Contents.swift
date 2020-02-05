import Foundation
import CLImate
import CommonParsers
import Prelude

let name = "playground"
let year = 2019

let arguments = [
    "hello", "--name", name, "--year", "\(year)", "--verbose"
    ]

enum Commands: Matchable {
    case hello(name: String, year: Int?, verbose: Bool)
    case print(verbose: Bool)
    case fastlane(lane: String, options: [String])
}

extension Commands {
    enum iso {
        static let hello = parenthesize(
            PartialIso<(String, Int?, Bool), Commands>(
                apply: Commands.hello,
                unapply: {
                    guard case let .hello(name, year, verbose) = $0 else { return nil }
                    return (name, year, verbose)
            }
            )
        )
    }
}

let commands: CLI<Commands> = [
    Commands.iso.hello
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
    ),
    Commands.fastlane
        <¢> command(
            name: "/fastlane",
            description: "run lane"
        )
        -- arg(
            description: "name of the lane",
            example: "test_babylon"
        )
        -- arg(
            default: ["branch:develop"],
            description: "lane options",
            example: ["branch:develop"]
        ),
//    Commands.fastlane
//        <¢> command(
//            name: "/fastlane",
//            description: "run lane"
//        )
//        -- arg(
//            name: "lane",
//            description: "name of the lane",
//            example: "test_babylon"
//        )
//        -- arg(
//            name: "options",
//            description: "lane options",
//            example: ["branch:develop", "device:iPhone5s"]
//    )
]

do {
    print(commands.help())

    try commands.match(arguments)

    let cmd = Commands.hello(name: name, year: year, verbose: true)

    try commands.print(cmd)!.render()
    try commands.print(cmd).flatMap(commands.match)
    try commands.template(for: cmd)!.render()

    try commands.run(arguments) { (cmd) in
        print(cmd)
    }

    try commands.run(["/fastlane", "test"]) { (cmd) in
        print(cmd)
    }

//    try commands.run(["/fastlane", "--options", "branch:develop", "--lane", "test", "--options", "device:iPhone5s"]) { (cmd) in
//        print(cmd)
//    }

} catch {
    print(error)
}
