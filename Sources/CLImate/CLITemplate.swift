import Foundation
import CommonParsers
import Prelude

var cliTemplate = CLITemplate()

open class CLITemplate {
    public init() {}

    open func longName(_ name: String) -> String {
        return "--\(name)"
    }

    open func shortName(_ name: String) -> String {
        return "-\(name)"
    }

    open func longOption(_ name: String) -> String {
        return longName(name)
    }

    open func shortOption(_ name: String) -> String {
        return shortName(name)
    }

    open func argUsage(
        _ long: String?,
        _ short: String?,
        _ type: String,
        _ description: String
    ) -> String {
        if let long = long {
            return "  \(longName(long))\(short.map { " (\(shortName($0)))" } ?? "") \(type): \(description)"
        } else if let short = short {
            return "  \(shortName(short)) \(type): \(description)"
        } else {
            return "  - \(type): \(description)"
        }
    }

    open func optionUsage(
        _ long: String,
        _ short: String?,
        _ description: String
    ) -> String {
        return "  \(longName(long))\(short.map { " (\(shortName($0)))" } ?? ""): \(description)"
    }

    open func commandUsage(
        _ name: String,
        _ description: String
    ) -> String {
        return "\(name)\(description.isEmpty ? "" : ": \(description)")"
    }

    open func commandUsageExample(
        _ usage: String,
        _ example: String
    ) -> String {
        return "\(usage)\n\nExample:\n  \(example)"
    }

    open func cliUsage(_ usage: String) -> String {
        return usage
    }
}
