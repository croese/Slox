//
//  File.swift
//  
//
//  Created by Christian Roese on 8/2/21.
//

import Foundation

public final class Slox {
    private let arguments: [String]
    static var hadError = false;
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }
    
    public func run() throws {
        guard self.arguments.count <= 1 else {
            throw Error.badUsage
        }
        
        if self.arguments.count == 1 {
            try runFile(self.arguments[0])
        } else {
            runPrompt()
        }
    }
    
    private func runPrompt() {
        while true {
            print("> ", terminator: "")
            let line = readLine(strippingNewline: true)
            guard let line = line else {
                break
            }
            run(line)
            Slox.hadError = false
        }
    }
    
    private func runFile(_ path: String) throws {
        let source = try String(contentsOfFile: path)
        run(source)
        
        if Slox.hadError {
            exit(65)
        }
    }
    
    private func run(_ source: String) {
        let scanner = Scanner(source: source)
        let tokens = scanner.scanTokens()
        
        for t in tokens {
            print(t)
        }
    }
    
    static func error(line: Int, message: String) {
        report(line: line, location: "", message: message)
    }
    
    private static func report(line: Int, location: String, message: String) {
        fputs("[line \(line)] Error\(location): \(message)\n", stderr)
        hadError = true
    }
}

public extension Slox {
    enum Error: Swift.Error {
        case badUsage
    }
}
