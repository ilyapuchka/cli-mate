import Foundation
import CommonParsers
import Prelude

private func command(
    _ str: String?
) -> Parser<CommandLineArguments, Prelude.Unit> {
    return Parser<CommandLineArguments, Prelude.Unit>.init(
        parse: { format -> (rest: CommandLineArguments, match: Prelude.Unit)? in
            guard let str = str else { return (format, unit) }

            return format.parts.head().flatMap { (p, ps) in
                (p == str)
                    ? (CommandLineArguments(parts: Array(ps)), unit)
                    : nil
            }
    },
        print: { _ in CommandLineArguments(parts: str.map { [$0] } ?? []) },
        template: { _ in CommandLineArguments(parts: str.map { [$0] } ?? []) }
    )
}

private func commandUsage(
    name str: String,
    description: String
) -> (CLITemplate) -> (Prelude.Unit) -> String {
    return { template in
        const(template.commandUsage(str, description))
    }
}

public func command(
    name str: String,
    description: String
) -> CLI<Prelude.Unit> {
    return CLI<Prelude.Unit>(
        parser: const(command(str)),
        usage: commandUsage(name: str, description: description),
        examples: [unit],
        template: cliTemplate
    )
}

private func subCommandsUsage<A>(
    name str: String,
    subCommands: CLI<A>
) -> (CLITemplate) -> (A) -> String {
    return { template in
        return { args in
            template.commandUsage("\(str) \(subCommands.usage(args))", "")
        }
    }
}

public func command<A>(
    name str: String,
    subCommands: CLI<A>
) -> CLI<A> {
    let cmd = command(name: str, description: "")
    return CLI<A>(
        parser: const(cmd.parser %> subCommands.parser),
        usage: subCommandsUsage(name: str, subCommands: subCommands),
        examples: subCommands.examples,
        template: cliTemplate
    )
}

public func commands<A>(
    _ subCommands: CLI<A>
) -> CLI<A> {
    let cmd = CLI<Prelude.Unit>(
        parser: command(nil),
        usage: const(""),
        examples: [unit]
    )
    return CLI<A>(
        parser: cmd.parser %> subCommands.parser,
        usage: subCommands.usage,
        examples: subCommands.examples
    )
}
