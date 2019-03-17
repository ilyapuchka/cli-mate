import Foundation
import CommonParsers
import Prelude

public struct CommandLineArguments {
    public private(set) var parts: [String]

    public init(parts: [String] = CommandLine.arguments) {
        self.parts = parts
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

    public static var empty: CLI {
        return .init(parser: .empty, usage: const(""), example: [])
    }

    public func match(_ template: CommandLineArguments) throws -> A? {
        return try self.parser.parse(template)?.match
    }

    public func match(_ args: [String] = CommandLine.arguments) throws -> A? {
        return try self.match(CommandLineArguments(parts: args))
    }

    public func help() -> String {
        return "Usage:\n\n" + example
            .compactMap {
                guard let example = try? self.parser.print($0), let ex = example?.render() else { return nil }
                return "\(usage($0))\n\nExample:\n  \(ex)"
            }
            .joined(separator: "\n\n")
    }

    public func run(_ args: [String] = CommandLine.arguments, _ perform: (A) -> Void) throws -> Void {
        try match(args).map(perform)
    }
}

private func argHelp<A>(parser: Parser<CommandLineArguments, A>, description: String, example: A?) -> String {
    guard
        let example = example,
        let tmp = try? parser.template(example)?.parts.joined(separator: " "),
        let template = tmp
        else { return "" }
    return "  \(template): \(description)"
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
        return CLI<B>(
            parser: lhs <¢> rhs.parser,
            usage: { ((try? lhs.unapply($0))?.map(rhs.usage)) ?? "" },
            example: rhs.example.compactMap({ (try? lhs.apply($0)) ?? nil })
        )
    }

    /// Processes with the left and right side Formats, and if they succeed returns the pair of their results.
    public static func <%> <B> (lhs: CLI, rhs: CLI<B>) -> CLI<(A, B)> {
        return CLI<(A, B)>(
            parser: lhs.parser <%> rhs.parser,
            usage: { lhs.usage($0.0) + "\n" + rhs.usage($0.1) },
            example: {
                lhs.example.flatMap({ (lhs) in
                    rhs.example.map({ (rhs) in
                        (lhs, rhs)
                    })
                })
        }()
        )
    }

    /// Processes with the left and right side Formats, discarding the result of the left side.
    public static func <%> (lhs: CLI<Prelude.Unit>, rhs: CLI) -> CLI {
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

public func arg<A>(
    long: String,
    short: String?,
    _ f: PartialIso<String, A>
) -> Parser<CommandLineArguments, A> {
    return Parser<CommandLineArguments, A>(
        parse: { format in
            guard
                let p = format.parts.index(where: { $0 == "--\(long)" || $0 == "-\(short ?? "-\(long)")" }),
                p < format.parts.endIndex,
                let v = try f.apply(format.parts[format.parts.index(after: p)])
                else { return nil }
            return (format, v)
    },
        print: { a in
            try f.unapply(a).flatMap { s in CommandLineArguments(parts: ["--\(long)", s]) }
    },
        template: { a in
            try f.unapply(a).flatMap { s in CommandLineArguments(parts: ["--\(long)\(short.map { " (-\($0))" } ?? "")", "\(type(of: a))"]) }
    })
}

public func arg<A>(
    name long: String,
    short: String? = nil,
    _ f: PartialIso<String, A>,
    example: A,
    description: String
) -> CLI<A> {
    let parser = arg(long: long, short: short, f)
    return CLI<A>(
        parser: parser,
        usage: { argHelp(parser: parser, description: description, example: $0) },
        example: [example]
    )
}

public func arg<A>(
    long: String,
    short: String?,
    _ f: PartialIso<String?, A?>
) -> Parser<CommandLineArguments, A?> {
    return Parser<CommandLineArguments, A?>(
        parse: { format in
            guard
                let p = format.parts.index(where: { $0 == "--\(long)" || $0 == "-\(short ?? "-\(long)")" }),
                p < format.parts.endIndex,
                let v = try f.apply(format.parts[format.parts.index(after: p)])
                else { return (format, nil) }
            return (format, v)
    },
        print: { a in
            try f.unapply(a).flatMap { s in CommandLineArguments(parts: ["--\(long)", s ?? ""]) }
                ?? .empty
    },
        template: { a in
            try f.unapply(a).flatMap { s in CommandLineArguments(parts: ["--\(long)\(short.map { " (-\($0))" } ?? "")", "\(type(of: a))"]) }
                ?? .empty
    })
}

public func arg<A>(
    name long: String,
    short: String? = nil,
    _ f: PartialIso<String?, A?>,
    example: A,
    description: String
) -> CLI<A?> {
    let parser = arg(long: long, short: short, f)
    return CLI<A?>(
        parser: parser,
        usage: { argHelp(parser: parser, description: description, example: $0) },
        example: [example]
    )
}

public func option(
    long: String,
    short: String?,
    default: Bool
) -> Parser<CommandLineArguments, Bool> {
    return Parser<CommandLineArguments, Bool>(
        parse: { format in
            let v = format.parts.contains(where: { $0 == "--\(long)" || $0 == "-\(short ?? "-\(long)")" })
            return (format, v || `default`)
    },
        print: { $0 ? CommandLineArguments(parts: ["--\(long)"]) : .empty },
        template: { $0 ? CommandLineArguments(parts: ["--\(long)", "(default: \(`default`))"]) : .empty }
    )
}

public func option(
    name long: String,
    short: String? = nil,
    default: Bool = false,
    description: String
) -> CLI<Bool> {
    let parser = option(long: long, short: short, default: `default`)
    return CLI<Bool>(
        parser: parser,
        usage: { argHelp(parser: parser, description: description, example: $0) },
        example: [true]
    )
}