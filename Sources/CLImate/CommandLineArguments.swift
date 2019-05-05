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
