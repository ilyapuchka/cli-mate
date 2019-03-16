# cli-mate

Define CLI commands using [CommonParsers](https://github.com/ilyapuchka/common-parsers).

```swift
enum Commands {
    case hello(name: String, verbose: Bool)
}

let commands: CLI<Commands> = [
    iso(Commands.hello)
        <¢> command(
            name: "hello",
            description: "greeting command"
        )
        <%> arg(
            name: "name", short: "n", .string, example: "world",
            description: "a name"
        )
        <%> option(
            name: "verbose", default: false,
            description: "be verbose"
        ),
]


let args = ["hello", "--name", "world", "--verbose"]

commands.run(args) { cmd in
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
