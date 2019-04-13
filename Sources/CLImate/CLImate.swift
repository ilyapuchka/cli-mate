import Foundation
import CommonParsers
import Prelude

public struct CommandLineArguments: ExpressibleByArrayLiteral, Equatable {
    public private(set) var parts: [String]

    public init(parts: [String] = CommandLine.arguments) {
        self.parts = parts
    }

    public init(arrayLiteral elements: String...) {
        self.init(parts: elements)
    }
}

extension CommandLineArguments: Monoid {
    public static var empty: CommandLineArguments {
        return CommandLineArguments(parts: [])
    }

    public static func <> (lhs: CommandLineArguments, rhs: CommandLineArguments) -> CommandLineArguments {
        return CommandLineArguments(parts: lhs.parts + rhs.parts)
    }
}

extension CommandLineArguments: TemplateType {
    public var isEmpty: Bool {
        return parts.isEmpty
    }

    public func render() -> String {
        return parts.joined(separator: " ")
    }
}

public struct CLI<A>: FormatType {
    public let usage: (A) -> String
    public let example: [A]
    public let parser: Parser<CommandLineArguments, A>
    var template: CLITemplate = cliTemplate

    public init(_ parser: Parser<CommandLineArguments, A>) {
        self.parser = parser
        self.usage = String.init(describing:)
        self.example = []
    }

    public init(
        parser: Parser<CommandLineArguments, A>,
        usage: @escaping (A) -> String,
        example: [A]
    ) {
        self.parser = parser
        self.usage = usage
        self.example = example
    }

    init(
        parser: (CLITemplate) -> Parser<CommandLineArguments, A>,
        usage: (CLITemplate) -> (A) -> String,
        example: [A],
        template: CLITemplate
    ) {
        self.init(parser: parser(template), usage: usage(template), example: example)
    }

    public static var empty: CLI {
        return .init(parser: .empty, usage: const(""), example: [])
    }

    public func match(_ args: [String] = CommandLine.arguments) throws -> A? {
        return try self.match(CommandLineArguments(parts: args))
    }

    public func help(_ args: [String] = []) -> String {
        let usages: [String] = example
            .compactMap {
                guard let example = try? self.parser.print($0), let ex = example else { return nil }
                guard args.isEmpty || args.first(where: { ex.parts.contains($0) == false }) == nil else { return nil }

                return template.commandUsage(usage($0), ex.render())
        }

        if usages.isEmpty {
            return ""
        } else {
            return template.cliUsage(usages.joined(separator: "\n\n"))
        }
    }

    public func run(_ args: [String] = CommandLine.arguments, _ perform: (A) -> Void) throws -> Void {
        let isHelp = equalsOptionName(long: "help", short: nil)(template)

        if args.last.flatMap(isHelp) == true {
            Swift.print(help(Array(args.dropLast())))
        } else if let matched = try match(args) {
            perform(matched)
        }
    }
}

extension CLI: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CLI...) {
        self = elements.reduce(.empty, <|>)
    }
}

func <|> <A, B>(_ f: @escaping (A) throws -> B?, _ g: @escaping (A) throws -> B?) -> (A) throws -> B? {
    return { a in
        let b: B?
        do {
            b = try f(a)
        } catch {
            return try g(a)
        }
        return try b ?? g(a)
    }
}

infix operator --: infixr4

extension CLI {

    public static func <|> (lhs: CLI, rhs: CLI) -> CLI {
        func usageForExample(_ cli: CLI) -> (A) throws -> String? {
            return { example in
                guard try cli.parser.print(example) != nil else {
                    return nil
                }
                return cli.usage(example)
            }
        }

        return CLI<A>(
            parser: lhs.parser <|> rhs.parser,
            usage: { example in
                let usage = usageForExample(lhs) <|> usageForExample(rhs)
                return (try? usage(example) ?? "") ?? ""
        },
            example: lhs.example + rhs.example
        )
    }

    public static func <¢> <B> (lhs: PartialIso<A, B>, rhs: CLI) -> CLI<B> {
        let example = rhs.example.compactMap({ (try? lhs.apply($0)) ?? nil })
        return CLI<B>(
            parser: lhs <¢> rhs.parser,
            usage: { ((try? lhs.unapply($0))?.map(rhs.usage)) ?? "" },
            example: example
        )
    }

    /// Processes with the left and right side Formats, and if they succeed returns the pair of their results.
    public static func -- <B> (lhs: CLI, rhs: CLI<B>) -> CLI<(A, B)> {
        let example = lhs.example.flatMap({ (lhs) in
            rhs.example.map({ (rhs) in
                (lhs, rhs)
            })
        })

        return CLI<(A, B)>(
            parser: lhs.parser <%> rhs.parser,
            usage: { lhs.usage($0.0) + "\n" + rhs.usage($0.1) },
            example: example
        )
    }

    /// Processes with the left and right side Formats, discarding the result of the left side.
    public static func -- (lhs: CLI<Prelude.Unit>, rhs: CLI) -> CLI {
        return CLI<A>(
            parser: lhs.parser %> rhs.parser,
            usage: { lhs.usage(unit) + "\n" + rhs.usage($0) },
            example: rhs.example
        )
    }
}

public func command(_ str: String) -> Parser<CommandLineArguments, Prelude.Unit> {
    return Parser<CommandLineArguments, Prelude.Unit>.init(
        parse: { format -> (rest: CommandLineArguments, match: Prelude.Unit)? in
            return format.parts.head().flatMap { (p, ps) in
                return (p == str)
                    ? (CommandLineArguments(parts: Array(ps)), unit)
                    : nil
            }
    },
        print: { _ in CommandLineArguments(parts: [str]) },
        template: { _ in CommandLineArguments(parts: [str]) }
    )
}

public func command(
    name str: String,
    description: String
) -> CLI<Prelude.Unit> {
    return CLI<Prelude.Unit>(
        parser: command(str),
        usage: const("\(str): \(description)"),
        example: [unit]
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
        example: subCommands.example
    )
}

public struct CLITemplate {
    public static let defaultLongArg: Arg = { "--\($0)" }
    public static let defaultShortArg: Arg = { "-\($0)" }
    public static let defaultArgHelp: ArgHelp = { long, short, type, description in
        if let long = long {
            return "  \(defaultLongArg(long))\(short.map { " (\(defaultShortArg($0)))" } ?? "") \(type): \(description)"
        } else if let short = short {
            return "  \(defaultShortArg(short)) \(type): \(description)"
        } else {
            return "  - \(type): \(description)"
        }
    }
    public static let defaultOptionHelp: OptionHelp = { long, short, `default`, description in
        "  --\(long)\(short.map { " (-\($0))" } ?? ""): \(description) (default: \(`default`))"
    }
    public static let defaultCommandUsage: CommandUsage = { usage, example in
        "\(usage)\n\nExample:\n  \(example)"
    }
    public static let defaultCLIUsage: (_ usage: String) -> String = { usage in
        "Usage:\n\n\(usage)"
    }

    public typealias Arg = (String) -> String
    public typealias ArgHelp = (
        _ long: String?,
        _ short: String?,
        _ type: String,
        _ description: String
    ) -> String

    public typealias Option = (String) -> String
    public typealias OptionHelp = (
        _ long: String,
        _ short: String?,
        _ `default`: String,
        _ description: String
    ) -> String

    public typealias CommandUsage = (
        _ usage: String,
        _ example: String
    ) -> String

    let longArg: Arg
    let shortArg: Arg
    let argHelp: ArgHelp
    let longOption: Option
    let shortOption: Option
    let optionHelp: OptionHelp
    let commandUsage: (String, String) -> String
    let cliUsage: (String) -> String

    public init(
        longArg: @escaping Arg = CLITemplate.defaultLongArg,
        shortArg: @escaping Arg = CLITemplate.defaultShortArg,
        argHelp: @escaping ArgHelp = CLITemplate.defaultArgHelp,
        longOption: @escaping Option = CLITemplate.defaultLongArg,
        shortOption: @escaping Option = CLITemplate.defaultShortArg,
        optionHelp: @escaping OptionHelp = CLITemplate.defaultOptionHelp,
        commandUsage: @escaping CommandUsage = CLITemplate.defaultCommandUsage,
        cliUsage: @escaping (String) -> String = CLITemplate.defaultCLIUsage
    ) {
        self.longArg = longArg
        self.shortArg = shortArg
        self.argHelp = argHelp
        self.longOption = longOption
        self.shortOption = shortOption
        self.optionHelp = optionHelp
        self.commandUsage = commandUsage
        self.cliUsage = cliUsage
    }
}

private var cliTemplate: CLITemplate = CLITemplate()

extension CLI {
    public static func with(template: CLITemplate, _ define: () -> CLI) -> CLI {
        cliTemplate = template
        defer { cliTemplate = CLITemplate() }
        var cli = define()
        cli.template = template
        return cli
    }
}

private func equalsArgName(
    long: String,
    short: String?
) -> (CLITemplate) -> (String) -> Bool {
    return { template in
        return { name in
            name == template.longArg(long) || (short.map { name == template.shortArg($0) } ?? false)
        }
    }
}

private func argHelp<A>(
    long: String?,
    short: String?,
    description: String,
    _ f: PartialIso<String, A>
) -> (CLITemplate) -> (A) -> String {
    return { template in
        return { example in
            guard let _ = try? f.unapply(example) else { return "" }
            return template.argHelp(long, short, "\(A.self)", description)
        }
    }
}

private func argHelp<A>(
    long: String?,
    short: String?,
    description: String,
    _ f: PartialIso<String?, A?>
) -> (CLITemplate) -> (A?) -> String {
    return { template in
        return { example in
            guard let example = example, let _ = try? f.unapply(example) else { return "" }
            return template.argHelp(long, short, "\(A.self)", description)
        }
    }
}

private func argHelp<A>(
    long: String?,
    short: String?,
    description: String,
    _ f: PartialIso<String, [A]>
) -> (CLITemplate) -> ([A]) -> String {
    return { template in
        return { example in
            guard let _ = try? f.unapply(example) else { return "" }
            return template.argHelp(long, short, "\(A.self)... ", description)
        }
    }
}

private func equalsOptionName(
    long: String,
    short: String?
) -> (CLITemplate) -> (String) -> Bool {
    return { template in
        return { name in
            name == template.longOption(long) || (short.map { name == template.shortOption($0) } ?? false)
        }
    }
}

private func optionHelp(
    name long: String,
    short: String?,
    default: Bool,
    description: String
) -> (CLITemplate) -> (Bool) -> String {
    return { template in
        return {
            guard $0 else { return "" }
            return template.optionHelp(long, short, "\(`default`)", description)
        }
    }
}

func arg<A>(
    long: String?,
    short: String?,
    _ f: PartialIso<String, A>
) -> (CLITemplate) -> Parser<CommandLineArguments, A> {
    return { template in
        return Parser<CommandLineArguments, A>(
            parse: { format in
                if let long = long {
                    guard
                        let p = format.parts.index(where: equalsArgName(long: long, short: short)(template)),
                        p < format.parts.endIndex,
                        let v = try f.apply(format.parts[format.parts.index(after: p)])
                        else { return nil }

                    var parts = format.parts
                    parts.remove(at: p)
                    parts.remove(at: p)
                    return (CommandLineArguments(parts: parts), v)
                } else {
                    return try format.parts.head().flatMap { (p, ps) in
                        guard let v = try f.apply(p) else { return nil }
                        return (CommandLineArguments(parts: Array(ps)), v)
                    }
                }
        },
            print: { a in
                try f.unapply(a).flatMap { s in
                    CommandLineArguments(
                        parts: long.map { ["\(template.longArg($0))", s] } ?? []
                    )
                }
        },
            template: { a in
                try f.unapply(a).flatMap { s in
                    CommandLineArguments(
                        parts: long.map { ["\(template.longArg($0))", "\(type(of: a))"] } ?? []
                    )
                }
        })
    }
}

public func arg<A>(
    name long: String? = nil,
    short: String? = nil,
    _ f: PartialIso<String, A>,
    example: A,
    description: String
) -> CLI<A> {
    return CLI<A>(
        parser: arg(
            long: long,
            short: short,
            f
        ),
        usage: argHelp(
            long: long,
            short: short,
            description: description,
            f
        ),
        example: [example],
        template: cliTemplate
    )
}

public func arg<A: LosslessStringConvertible>(
    name long: String? = nil,
    short: String? = nil,
    example: A,
    description: String
) -> CLI<A> {
    return arg(
        name: long,
        short: short,
        .losslessStringConvertible,
        example: example,
        description: description
    )
}

func arg<A>(
    long: String?,
    short: String?,
    _ f: PartialIso<String?, A?>
) -> (CLITemplate) -> Parser<CommandLineArguments, A?> {
    return { template in
        return Parser<CommandLineArguments, A?>(
            parse: { format in
                if let long = long {
                    guard
                        let p = format.parts.index(where: equalsArgName(long: long, short: short)(template)),
                        p < format.parts.endIndex,
                        let v = try f.apply(format.parts[format.parts.index(after: p)])
                        else { return (format, nil) }

                    var parts = format.parts
                    parts.remove(at: p)
                    parts.remove(at: p)
                    return (CommandLineArguments(parts: parts), v)
                } else {
                    return try format.parts.head().flatMap { (p, ps) in
                        guard let v = try f.apply(p) else { return (format, nil) }
                        return (CommandLineArguments(parts: Array(ps)), v)
                    }
                }
        },
            print: { a in
                try f.unapply(a).flatMap { s in
                    CommandLineArguments(
                        parts: long.map { ["\(template.longArg($0))", s ?? ""] } ?? []
                    )
                    }
                    ?? .empty
        },
            template: { a in
                try f.unapply(a).flatMap { s in
                    CommandLineArguments(
                        parts: long.map { ["\(template.longArg($0))", "\(type(of: a))"] } ?? []
                    )
                    }
                    ?? .empty
        })
    }
}

public func arg<A>(
    name long: String? = nil,
    short: String? = nil,
    _ f: PartialIso<String?, A?>,
    example: A,
    description: String
) -> CLI<A?> {
    return CLI<A?>(
        parser: arg(
            long: long,
            short: short,
            f
        ),
        usage: argHelp(
            long: long,
            short: short,
            description: description,
            f
        ),
        example: [example],
        template: cliTemplate
    )
}

public func arg<A: LosslessStringConvertible>(
    name long: String? = nil,
    short: String? = nil,
    example: A,
    description: String
) -> CLI<A?> {
    return arg(
        name: long,
        short: short,
        opt(.losslessStringConvertible),
        example: example,
        description: description
    )
}

private func array<A>(_ f: PartialIso<String, A>) -> PartialIso<String, [A]> {
    return PartialIso<String, [A]>(
        apply: { (string) -> [A]? in
            try string
                .components(separatedBy: " ")
                .compactMap(f.apply)
    },
        unapply: { (array) -> String? in
            try array
                .compactMap(f.unapply)
                .joined(separator: " ")
    }
    )
}

private func varArg<A>(
    _ f: PartialIso<String, [A]>
) -> (CLITemplate) -> Parser<CommandLineArguments, [A]> {
    return { template in
        return Parser<CommandLineArguments, [A]>(
            parse: { format in
                guard !format.parts.isEmpty,
                    let v = try f.apply(format.parts.joined(separator: " "))
                    else { return nil }
                return ([], v)
        },
            print: { a in
                try f.unapply(a).flatMap { s in
                    CommandLineArguments(
                        parts: [s]
                    )
                }
        },
            template: { a in
                try f.unapply(a).flatMap { s in
                    CommandLineArguments(
                        parts: ["\(A.self)..."]
                    )
                }
        })
    }
}

public func varArg<A>(
    _ f: PartialIso<String, A>,
    example: [A],
    description: String
) -> CLI<[A]> {
    return CLI<[A]>(
        parser: varArg(array(f)),
        usage: argHelp(
            long: nil,
            short: nil,
            description: description,
            array(f)
        ),
        example: [example],
        template: cliTemplate
    )
}

public func varArg<A: LosslessStringConvertible>(
    example: [A],
    description: String
) -> CLI<[A]> {
    return varArg(
        .losslessStringConvertible,
        example: example,
        description: description
    )
}

func option(
    long: String,
    short: String?,
    default: Bool
) -> (CLITemplate) -> Parser<CommandLineArguments, Bool> {
    return { template in
        return Parser<CommandLineArguments, Bool>(
            parse: { format in
                guard
                    let p = format.parts.index(where: equalsArgName(long: long, short: short)(template))
                    else {
                        return (format, `default`)
                }
                var parts = format.parts
                parts.remove(at: p)
                return (CommandLineArguments(parts: parts), true)
        },
            print: { $0 ? CommandLineArguments(parts: ["\(template.longOption(long))"]) : .empty },
            template: { $0 ? CommandLineArguments(parts: ["\(template.longOption(long))"]) : .empty }
        )
    }
}

public func option(
    name long: String,
    short: String? = nil,
    default: Bool = false,
    description: String
) -> CLI<Bool> {
    return CLI<Bool>(
        parser: option(
            long: long,
            short: short,
            default: `default`
        ),
        usage: optionHelp(
            name: long,
            short: short,
            default: `default`,
            description: description
        ),
        example: [true],
        template: cliTemplate
    )
}

public func <¢> <U: Matchable>(_ f: U, cli: CLI<Prelude.Unit>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢> <A, U: Matchable>(_ f: @escaping (A) -> U, cli: CLI<A>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, U: Matchable>(_ f: @escaping ((A, B)) -> U, cli: CLI<(A, B)>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, U: Matchable>(_ f: @escaping (A, B, C) -> U, cli: CLI<(A, (B, C))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, U: Matchable>(_ f: @escaping (A, B, C, D) -> U, cli: CLI<(A, (B, (C, D)))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, U: Matchable>(_ f: @escaping (A, B, C, D, E) -> U, cli: CLI<(A, (B, (C, (D, E))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, U: Matchable>(_ f: @escaping (A, B, C, D, E, F) -> U, cli: CLI<(A, (B, (C, (D, (E, F)))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, G, U: Matchable>(_ f: @escaping (A, B, C, D, E, F, G) -> U, cli: CLI<(A, (B, (C, (D, (E, (F, G))))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, G, H, U: Matchable>(_ f: @escaping (A, B, C, D, E, F, G, H) -> U, cli: CLI<(A, (B, (C, (D, (E, (F, (G, H)))))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, G, H, I, U: Matchable>(_ f: @escaping (A, B, C, D, E, F, G, H, I) -> U, cli: CLI<(A, (B, (C, (D, (E, (F, (G, (H, I))))))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, G, H, I, J, U: Matchable>(_ f: @escaping (A, B, C, D, E, F, G, H, I, J) -> U, cli: CLI<(A, (B, (C, (D, (E, (F, (G, (H, (I, J)))))))))>) -> CLI<U> {
    return iso(f) <¢> cli
}
