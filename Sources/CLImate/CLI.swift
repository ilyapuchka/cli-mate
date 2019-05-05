import Foundation
import CommonParsers
import Prelude

public struct CLI<A>: FormatType {
    public let usage: (A) -> String
    public let examples: [A]
    public let parser: Parser<CommandLineArguments, A>
    var template: CLITemplate = cliTemplate

    public init(_ parser: Parser<CommandLineArguments, A>) {
        self.parser = parser
        self.usage = String.init(describing:)
        self.examples = []
    }

    public init(
        parser: Parser<CommandLineArguments, A>,
        usage: @escaping (A) -> String,
        examples: [A]
    ) {
        self.parser = parser
        self.usage = usage
        self.examples = examples
    }

    init(
        parser: (CLITemplate) -> Parser<CommandLineArguments, A>,
        usage: (CLITemplate) -> (A) -> String,
        examples: [A],
        template: CLITemplate
    ) {
        self.init(parser: parser(template), usage: usage(template), examples: examples)
        self.template = template
    }

    public static var empty: CLI {
        return .init(parser: .empty, usage: const(""), examples: [])
    }

    public func match(_ args: [String] = CommandLine.arguments) throws -> A? {
        return try self.match(CommandLineArguments(parts: args))
    }

    public func help(_ args: [String] = []) -> String {
        let usages: [String] = examples
            .compactMap {
                guard let example = try? self.parser.print($0) else { return nil }
                guard args.isEmpty || args.first(where: { example.parts.contains($0) == false }) == nil else { return nil }

                return template.commandUsage(usage($0), example.render())
        }

        guard !usages.isEmpty else {
            return ""
        }

        return template.cliUsage(usages.joined(separator: "\n\n"))
    }

    public func run(_ args: [String] = CommandLine.arguments, _ perform: (A) -> Void) throws -> Void {
        let isHelp = equalsOptionName(long: "help", short: nil)

        if args.last.flatMap(isHelp(template)) == true {
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
            examples: lhs.examples + rhs.examples
        )
    }

    public static func <¢> <B> (lhs: PartialIso<A, B>, rhs: CLI) -> CLI<B> {
        let examples = rhs.examples.compactMap({ (try? lhs.apply($0)) ?? nil })
        return CLI<B>(
            parser: lhs <¢> rhs.parser,
            usage: { ((try? lhs.unapply($0))?.map(rhs.usage)) ?? "" },
            examples: examples
        )
    }

    /// Processes with the left and right side Formats, and if they succeed returns the pair of their results.
    public static func -- <B> (lhs: CLI, rhs: CLI<B>) -> CLI<(A, B)> {
        let examples = lhs.examples.flatMap({ (lhs) in
            rhs.examples.map({ (rhs) in
                (lhs, rhs)
            })
        })

        return CLI<(A, B)>(
            parser: lhs.parser <%> rhs.parser,
            usage: { lhs.usage($0.0) + "\n" + rhs.usage($0.1) },
            examples: examples
        )
    }

    /// Processes with the left and right side Formats, discarding the result of the left side.
    public static func -- (lhs: CLI<Prelude.Unit>, rhs: CLI) -> CLI {
        return CLI<A>(
            parser: lhs.parser %> rhs.parser,
            usage: { lhs.usage(unit) + "\n" + rhs.usage($0) },
            examples: rhs.examples
        )
    }
}

infix operator --: infixr4
