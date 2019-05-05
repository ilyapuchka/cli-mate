import Foundation
import CommonParsers
import Prelude

var cliTemplate: CLITemplate = CLITemplate()

extension CLI {
    public static func with(template: CLITemplate, _ define: () -> CLI) -> CLI {
        cliTemplate = template
        defer { cliTemplate = CLITemplate() }
        var cli = define()
        cli.template = template
        return cli
    }
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
    public static let defaultOptionHelp: OptionHelp = { long, short, description in
        "  --\(long)\(short.map { " (-\($0))" } ?? ""): \(description)"
    }
    public static let defaultCommandUsage: CommandUsage = { usage, example in
        "\(usage)\n\nExample:\n  \(example)"
    }
    public static let defaultCLIUsage: (_ usage: String) -> String = { $0 }

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
