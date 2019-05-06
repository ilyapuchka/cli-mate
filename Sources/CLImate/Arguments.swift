import Foundation
import CommonParsers
import Prelude

private func equalsArgName(
    long: String,
    short: String?
) -> (CLITemplate) -> (String) -> Bool {
    return { template in
        return { name in
            name == template.longName(long) || (short.map { name == template.shortName($0) } ?? false)
        }
    }
}

private func argUsage<A, B>(
    long: String?,
    short: String?,
    description: String,
    _ f: PartialIso<A, B>
) -> (CLITemplate) -> (B) -> String {
    return { template in
        return { example in
            guard let _ = try? f.unapply(example) else { return "" }
            return template.argUsage(long, short, "\(B.self)", description)
        }
    }
}

private func argUsage<A>(
    long: String?,
    short: String?,
    description: String,
    _ f: PartialIso<String?, A?>
) -> (CLITemplate) -> (A?) -> String {
    return { template in
        return { example in
            guard let example = example, let _ = try? f.unapply(example) else { return "" }
            return template.argUsage(long, short, "\(A.self)", "\(description) (optional)")
        }
    }
}

private func argUsage<A, B>(
    long: String?,
    short: String?,
    description: String,
    _ f: PartialIso<A, [B]>
) -> (CLITemplate) -> ([B]) -> String {
    return { template in
        return { example in
            guard let _ = try? f.unapply(example) else { return "" }
            return template.argUsage(long, short, "[\(B.self)]", description)
        }
    }
}

private func arg<A>(
    long: String?,
    short: String?,
    _ f: PartialIso<String, A>,
    `default`: A?
) -> (CLITemplate) -> Parser<CommandLineArguments, A> {
    return { template in
        return Parser<CommandLineArguments, A>(
            parse: { format in
                if let long = long {
                    guard
                        let p = format.parts.firstIndex(where: equalsArgName(long: long, short: short)(template)),
                        p < format.parts.endIndex,
                        let v = try f.apply(format.parts[format.parts.index(after: p)])
                        else {
                            return `default`.map { (CommandLineArguments(parts: format.parts), $0) }
                    }

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
                        parts: [long.map { "\(template.longName($0))" }, s].compactMap { $0 }
                    )
                }
        },
            template: { a in
                try f.unapply(a).flatMap { s in
                    CommandLineArguments(
                        parts: [long.map { "\(template.longName($0))" }, "\(type(of: a))"].compactMap { $0 }
                    )
                }
        })
    }
}

public func arg<A>(
    name long: String? = nil,
    short: String? = nil,
    _ f: PartialIso<String, A>,
    default: A? = nil,
    description: String,
    example: A
) -> CLI<A> {
    return CLI<A>(
        parser: arg(long: long, short: short, f, default: `default`),
        usage: argUsage(long: long, short: short, description: description, f),
        examples: [example],
        template: cliTemplate
    )
}

public func arg<A: LosslessStringConvertible>(
    name long: String? = nil,
    short: String? = nil,
    default: A? = nil,
    description: String,
    example: A
) -> CLI<A> {
    return arg(
        name: long,
        short: short,
        .losslessStringConvertible,
        default: `default`,
        description: description,
        example: example
    )
}

private func arg<A>(
    long: String?,
    short: String?,
    _ f: PartialIso<String?, A?>
) -> (CLITemplate) -> Parser<CommandLineArguments, A?> {
    return { template in
        return Parser<CommandLineArguments, A?>(
            parse: { format in
                if let long = long {
                    guard
                        let p = format.parts.firstIndex(where: equalsArgName(long: long, short: short)(template)),
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
                        parts: [long.map { "\(template.longName($0))" }, s].compactMap { $0 }
                    )
                    } ?? .empty
        },
            template: { a in
                try f.unapply(a).flatMap { s in
                    CommandLineArguments(
                        parts: [long.map { "\(template.longName($0))" }, "\(type(of: a))"].compactMap { $0 }
                    )
                    } ?? .empty
        })
    }
}

public func arg<A>(
    name long: String? = nil,
    short: String? = nil,
    _ f: PartialIso<String?, A?>,
    description: String,
    example: A
) -> CLI<A?> {
    return CLI<A?>(
        parser: arg(long: long, short: short, f),
        usage: argUsage(long: long, short: short, description: description, f),
        examples: [example],
        template: cliTemplate
    )
}

public func arg<A: LosslessStringConvertible>(
    name long: String? = nil,
    short: String? = nil,
    description: String,
    example: A
) -> CLI<A?> {
    return arg(
        name: long,
        short: short,
        opt(.losslessStringConvertible),
        description: description,
        example: example
    )
}

extension PartialIso where A == [String] {
    public static func array(_ f: PartialIso<String, B>) -> PartialIso<[String], [B]> {
        return PartialIso<[String], [B]>(
            apply: { (string) -> [B]? in
                try string.compactMap(f.apply)
        },
            unapply: { (array) -> [String]? in
                try array.compactMap(f.unapply)
        })
    }
}

private func arg<A>(
    name long: String,
    short: String?,
    _ f: PartialIso<String, A>,
    default: [A]?
) -> (CLITemplate) -> Parser<CommandLineArguments, [A]> {
    return { template in
        return Parser<CommandLineArguments, [A]>.init(
            parse: { (format) -> (rest: CommandLineArguments, match: [A])? in
                guard !format.parts.isEmpty else { return nil }
                var format = format
                var result = [A]()
                let parser = arg(long: long, short: short, f, default: nil)
                while let (rest, match) = try parser(template).parse(format) {
                    result.append(match)
                    format = rest
                }
                guard !result.isEmpty else {
                    return `default`.map { (CommandLineArguments(parts: format.parts), $0) }
                }
                return (format, result)
        },
            print: { (array) -> CommandLineArguments? in
                try CommandLineArguments(parts: array.compactMap(f.unapply).flatMap {
                    ["\(template.longName(long))", $0]
                })
        },
            template: { (array) -> CommandLineArguments? in
                return CommandLineArguments(parts: [template.longName(long), "\(A.self)..."])
        })
    }
}

public func arg<A>(
    name long: String,
    short: String? = nil,
    _ f: PartialIso<String, A>,
    default: [A]? = nil,
    description: String,
    example: [A]
) -> CLI<[A]> {
    return CLI<[A]>(
        parser: arg(name: long, short: short, f, default: `default`),
        usage: argUsage(long: long, short: short, description: description, PartialIso.array(f)),
        examples: [example],
        template: cliTemplate
    )
}

public func arg<A: LosslessStringConvertible>(
    name long: String,
    short: String? = nil,
    default: [A]? = nil,
    description: String,
    example: [A]
) -> CLI<[A]> {
    return CLI<[A]>(
        parser: arg(name: long, short: short, .losslessStringConvertible, default: `default`),
        usage: argUsage(long: long, short: short, description: description, PartialIso.array(.losslessStringConvertible)),
        examples: [example],
        template: cliTemplate
    )
}

private func varArg<A>(
    _ f: PartialIso<[String], [A]>,
    `default`: [A]?
) -> (CLITemplate) -> Parser<CommandLineArguments, [A]> {
    return { template in
        return Parser<CommandLineArguments, [A]>(
            parse: { format in
                if format.parts.isEmpty {
                    return ([], `default` ?? [])
                }
                guard
                    let v = try f.apply(format.parts) ?? `default`
                    else { return nil }
                return ([], v)
        },
            print: { a in
                try f.unapply(a).flatMap { s in
                    CommandLineArguments(
                        parts: s
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

public func arg<A>(
    _ f: PartialIso<String, A>,
    default: [A]? = nil,
    description: String,
    example: [A]
) -> CLI<[A]> {
    let array = PartialIso.array(f)
    return CLI<[A]>(
        parser: varArg(array, default: `default`),
        usage: argUsage(long: nil, short: nil, description: description, array),
        examples: [example],
        template: cliTemplate
    )
}

public func arg<A: LosslessStringConvertible>(
    default: [A]? = nil,
    description: String,
    example: [A]
) -> CLI<[A]> {
    return arg(
        .losslessStringConvertible,
        default: `default`,
        description: description,
        example: example
    )
}
