# CLImate

Define CLI (command line interface) commands using [CommonParsers](https://github.com/ilyapuchka/common-parsers).

### Usage

#### Functions

The easiest way to define commands with CLImate is to use builtin `Command` type.
You start with defining a command as a function like this:

```swift
import CLImate
import CommonParsers
import Prelude

func hello(name: String, verbose: Bool) -> Command {
    return Command(args: (name, verbose)) {
        if verbose {
            print("Nice to see you, \(name)!")
        } else {
            print("Hello, \(name)!")
        }
    }
}
```

Note that arguments passed to the `Command.init` are grouped in a tuple and also are captured by its `run` closure.
You can already use this function to create and run a command:

```swift
hello(name: "World", verbose: false).run()
// Hello, World!
```

but that's not very useful. 
Now using this command function you can create your application and describe this command:

```swift
let app: CLI<Command> = [
    Command.make(hello)
        <¢> command(
            name: "hello",
            description: "greeting"
        )
        -- arg(
            name: "name", short: "n",
            description: "a name",
            example: "World"
        )
        -- option(
            name: "verbose",
            description: "be verbose"
        )
]
```

This will define an app with a command named `hello` that accepts a `name` parameter and a `verbose` option and runs a command returned by `hello` function.
Now you can run the app with `app.run()`. This will parse the command line arguments and invoke one of the registerred commands if it can match it, or throw an error. 

The app and every command in it will automatically get a `--help` option. When provided the app will output usage instructions for the whole app or for particular command, compiled using `description` and `example` values of commands and their arguments: 

```swift
app.run(["--help"])
app.run(["hello", "--help"])

Output:

hello: greeting
    --name (-n) String: a name
    --verbose: be verbose

Example:
    hello --name World --verbose
```

#### Enums or Structs

Alternatively you can define your commands using enums or structs:

```swift
// Define commands type
enum Commands {
    case hello(name: String, verbose: Bool)
}

// Define commands and their arguments
let app: CLI<Commands> = [
    Commands.hello
        <¢> command...
]
```

In this case `app.run()`  will accept a closure to which it will pass the instance of your enum or struct that it created based on the passed arguments and command description:

```swift
try app.run() { cmd in
    // cmd == Commands.hello(name: "World", verbose: false) 
}
```

This enum or struct type should implement `Matchable` protocol that framework will use to match commands with arguments.

```swift
extension Commands: Matchable {
    func match<A>(_ constructor: (A) -> Commands) -> A? {
        switch self {
        case let .hello(values):
            guard let a = values as? A, self == constructor(a) else { return nil }
            return a
        }
    }
}
```

If you choose not to implement this protocol you can define partial isomorphisms for each command manually:

```swift
extension Commands {
    enum iso {
        static let hello = parenthesize(
            PartialIso(
                apply: Commands.hello,
                unapply: {
                    guard case let .hello(name, year, verbose) = $0 else { return nil }
                    return (name, year, verbose)
                }
            )
        )
    }
}

let app: CLI<Commands> = [
    Commands.iso.hello 
        <¢> command...
```

As you can see both approaches require quite a lot of boilerplate (you can generate it using Sourcery or SwiftSyntax).
If it's not crucial for your app to represent commands as standalone types you should use `Command`.

See the playground for more examples of commands.

#### Extending number of arguments

You can use up to 10 arguments in your commands. If you wish to extend this number you can do that by adding `Command.make` function overload with required number of parameters. You may also want to add an overload of `parenthesize` free function to make implementation simpler. Check `Command.swift` to see how to implement these functions.

If you are not using `Command` type but use `Matchable` protocol you will need to add a new overload of `iso` free function and `<¢>` operator. You also still need to implement a new `parenthesize` free function. Check  `Matchable.swift` to see how to implement these functions.

If you are not using `Matchable` protocol then you only need to implement a new overload of `parenthesize` free function. See `Parenthesize.swift` in `CommonParsers` module to see how to implement it.

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "https://github.com/ilyapuchka/cli-mate.git", .branch("master")),
    ]
)
```
