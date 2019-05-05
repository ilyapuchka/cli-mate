import Foundation
import CommonParsers
import Prelude

public struct Command {
    let identifier: String
    let args: Any
    public let run: () -> Void

    public init(identifier: String = #function, args: Any = unit, run: @escaping () -> Void) {
        self.identifier = identifier
        self.args = args
        self.run = run
    }
}

extension CLI where A == Command {
    public func run(_ args: [String] = CommandLine.arguments) throws -> Void {
        try run(args, { $0.run() })
    }
}

private func command(
    _ str: String?
) -> Parser<CommandLineArguments, Prelude.Unit> {
    return Parser<CommandLineArguments, Prelude.Unit>.init(
        parse: { format -> (rest: CommandLineArguments, match: Prelude.Unit)? in
            guard let str = str else { return (format, unit) }

            return format.parts.head().flatMap { (p, ps) in
                return (p == str)
                    ? (CommandLineArguments(parts: Array(ps)), unit)
                    : nil
            }
    },
        print: { _ in CommandLineArguments(parts: str.map { [$0] } ?? []) },
        template: { _ in CommandLineArguments(parts: str.map { [$0] } ?? []) }
    )
}

public func command(
    name str: String,
    description: String
) -> CLI<Prelude.Unit> {
    return CLI<Prelude.Unit>(
        parser: command(str),
        usage: const("\(str): \(description)"),
        examples: [unit]
    )
}

public func command<A>(
    name str: String,
    subCommands: CLI<A>
) -> CLI<A> {
    let cmd = command(name: str, description: "")
    return CLI<A>(
        parser: cmd.parser %> subCommands.parser,
        usage: { "\(str) \(subCommands.usage($0))" },
        examples: subCommands.examples
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

extension Command {
    public static func make(_ f: @escaping () -> Command) -> PartialIso<Prelude.Unit, Command> {
        return PartialIso(
            apply: { _ in f() },
            unapply: {
                let args = $0.args as? Prelude.Unit
                guard $0.identifier == f().identifier else { return nil }
                return args
        })
    }

    public static func make<A>(_ f: @escaping (A) -> Command) -> PartialIso<A, Command> {
        return PartialIso(
            apply: f,
            unapply: {
                let args = $0.args as? A
                guard $0.identifier == args.map(f)?.identifier else { return nil }
                return args
        })
    }

    public static func make<A, B>(_ f: @escaping (A, B) -> Command) -> PartialIso<(A, B), Command> {
        return make { f($0.0, $0.1) } |> parenthesize
    }

    public static func make<A, B, C>(_ f: @escaping (A, B, C) -> Command) -> PartialIso<(A, (B, C)), Command> {
        return make { f($0.0, $0.1, $0.2) } |> parenthesize
    }

    public static func make<A, B, C, D>(_ f: @escaping (A, B, C, D) -> Command) -> PartialIso<(A, (B, (C, D))), Command> {
        return make { f($0.0, $0.1, $0.2, $0.3) } |> parenthesize
    }

    public static func make<A, B, C, D, E>(_ f: @escaping (A, B, C, D, E) -> Command) -> PartialIso<(A, (B, (C, (D, E)))), Command> {
        return make { f($0.0, $0.1, $0.2, $0.3, $0.4) } |> parenthesize
    }

    public static func make<A, B, C, D, E, F>(_ f: @escaping (A, B, C, D, E, F) -> Command) -> PartialIso<(A, (B, (C, (D, (E, F))))), Command> {
        return make { f($0.0, $0.1, $0.2, $0.3, $0.4, $0.5) } |> parenthesize
    }

    public static func make<A, B, C, D, E, F, G>(_ f: @escaping (A, B, C, D, E, F, G) -> Command) -> PartialIso<(A, (B, (C, (D, (E, (F, G)))))), Command> {
        return make { f($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6) } |> parenthesize
    }

    public static func make<A, B, C, D, E, F, G, H>(_ f: @escaping (A, B, C, D, E, F, G, H) -> Command) -> PartialIso<(A, (B, (C, (D, (E, (F, (G, H))))))), Command> {
        return make { f($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7) } |> parenthesize
    }

    public static func make<A, B, C, D, E, F, G, H, I>(_ f: @escaping (A, B, C, D, E, F, G, H, I) -> Command) -> PartialIso<(A, (B, (C, (D, (E, (F, (G, (H, I)))))))), Command> {
        return make { f($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8) } |> parenthesize
    }

    public static func make<A, B, C, D, E, F, G, H, I, J>(_ f: @escaping (A, B, C, D, E, F, G, H, I, J) -> Command) -> PartialIso<(A, (B, (C, (D, (E, (F, (G, (H, (I, J))))))))), Command> {
        return make { f($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8, $0.9) } |> parenthesize
    }
}
