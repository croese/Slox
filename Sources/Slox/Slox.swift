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
    static var hadRuntimeError = false
    
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
        if Slox.hadRuntimeError {
            exit(70)
        }
    }
    
    private func run(_ source: String) {
        let scanner = Scanner(source: source)
        let tokens = scanner.scanTokens()
        let parser = Parser(tokens: tokens)
        let statements = parser.parse()
        
        if Slox.hadError {
            return
        }
        
        interpret(statements: statements)
    }
    
    static func error(line: Int, message: String) {
        report(line: line, location: "", message: message)
    }
    
    static func error(token: Token, message: String) {
        if token.type == .eof {
            report(line: token.line, location: " at end", message: message)
        } else {
            report(line: token.line, location: " at '\(token.lexeme)'", message: message)
        }
    }
    
    static func runtimeError(error: RuntimeError) {
        fputs("\(error.message)\n[line \(error.token.line)]\n", stderr)
        hadRuntimeError = true
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



