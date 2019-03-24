# cli-mate

Define CLI commands using [CommonParsers](https://github.com/ilyapuchka/common-parsers).

```swift
enum Commands {
    case hello(name: String, verbose: Bool)
}

let commands: CLI<Commands> = [
    Commands.hello
        <¢> command(
            name: "hello",
            description: "greeting command"
        )
        -- arg(
            name: "name", short: "n", example: "world",
            description: "a name"
        )
        -- option(
            name: "verbose", default: false,
            description: "be verbose"
        ),
]


let args = ["hello", "--name", "world", "--verbose"]

try commands.run(args) { cmd in
    print(cmd)
    
    /**
    hello(name: "world", verbose: true)
    */
}

print(commands.help())

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
