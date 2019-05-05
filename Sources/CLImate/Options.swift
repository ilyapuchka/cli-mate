import Foundation
import CommonParsers
import Prelude

func equalsOptionName(
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
    description: String
) -> (CLITemplate) -> (Bool) -> String {
    return { template in
        return {
            guard $0 else { return "" }
            return template.optionHelp(long, short, description)
        }
    }
}

func option(
    long: String,
    short: String?
) -> (CLITemplate) -> Parser<CommandLineArguments, Bool> {
    return { template in
        return Parser<CommandLineArguments, Bool>(
            parse: { format in
                guard
                    let p = format.parts.firstIndex(where: equalsOptionName(long: long, short: short)(template))
                    else {
                        return (format, false)
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
    description: String
) -> CLI<Bool> {
    return CLI<Bool>(
        parser: option(long: long, short: short),
        usage: optionHelp(name: long, short: short, description: description),
        examples: [true],
        template: cliTemplate
    )
}
