import Foundation

let slox = Slox(arguments: Array(CommandLine.arguments.dropFirst()))

do {
    try slox.run()
} catch Slox.Error.badUsage {
    print("Usage: slox [script]")
    exit(64)
} catch {
    print("Whoops! An error occurred: \(error)")
}

