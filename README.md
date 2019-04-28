# cli-mate

Define CLI commands using [CommonParsers](https://github.com/ilyapuchka/common-parsers).

```swift
import CLImate
import CommonParsers
import Prelude

// Define commands type
enum Commands {
    case hello(name: String, verbose: Bool)
}

// Implement a helper protocol
extension Commands: Matchable {
    func match<A>(_ constructor: (A) -> Commands) -> A? {
        switch self {
        case let .hello(values):
            guard let a = values as? A, self == constructor(a) else { return nil }
            return a
        }
    }
}

// Define commands and their arguments
let commands: CLI<Commands> = [
    Commands.hello
        <¢> command(
            name: "hello",
            description: "greeting command"
        )
        -- arg(
            name: "name", short: "n",
            description: "a name",
            example: "world"
        )
        -- option(
            name: "verbose", default: false,
            description: "be verbose"
        ),
]

// Run a command
let args = ["hello", "--name", "world", "--verbose"]

try commands.run(args) { cmd in
    print(cmd)
    
    /**
    hello(name: "world", verbose: true)
    */
}
```

Each command will automatically support `--help` option to print its usage instructions. 
Providing just `--help` option without any command name will print instructions for all defined commands.  

```swift
try commands.run(["hello", "--help"])

/**
Usage:

hello: greeting command
    --name (-n) String: a name
    --verbose (default: false): be verbose

Example:
    hello --name world --verbose
*/
```

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "https://github.com/ilyapuchka/cli-mate.git", .branch("master")),
    ]
)
```
