//
//  File.swift
//  
//
//  Created by Christian Roese on 8/2/21.
//

import Foundation

public class Scanner {
    private let source: String
    private var tokens = [Token]()
    private var start = 0
    private var current = 0
    private var line = 1
    
    private var isAtEnd: Bool {
        return current >= source.count
    }
    
    public init(source: String) {
        self.source = source
    }
    
    public func scanTokens() -> [Token] {
        while !isAtEnd {
            start = current
            scanToken()
        }
        
        tokens.append(Token(type: .eof, lexeme: "", literal: nil, line: line))
        return tokens
    }
    
    private func scanToken() {
        let c = advance()
        switch c {
        case "(": addToken(type: .leftParen)
        case ")": addToken(type: .rightParen)
        case "{": addToken(type: .leftBrace)
        case "}": addToken(type: .rightBrace)
        case ",": addToken(type: .comma)
        case ".": addToken(type: .dot)
        case "-": addToken(type: .minus)
        case "+": addToken(type: .plus)
        case ";": addToken(type: .semicolon)
        case "*": addToken(type: .star)
        case "!": addToken(type: (match("=") ? .bangEqual : .bang))
        case "=": addToken(type: (match("=") ? .equalEqual : .equal))
        case "<": addToken(type: (match("=") ? .lessEqual : .less))
        case ">": addToken(type: (match("=") ? .greaterEqual : .greater))
        case "/":
            if match("/") {
                // found comment
                while peek() != "\n" && !isAtEnd {
                    advance()
                }
            } else {
                addToken(type: .slash)
            }
        case " ": fallthrough
        case "\r": fallthrough
        case "\t": break
        case "\n": line += 1
        case "\"": string()
        default:
            if c.isNumber {
                number()
            } else {
                Slox.error(line: line, message: "Unexpected character.")
            }
        }
    }
    
    private func advance() -> Character {
        let c = source[current]
        current += 1
        return c
    }
    
    private func addToken(type: TokenType, literal: Any? = nil) {
        let startIndex = source.index(source.startIndex, offsetBy: start)
        let endIndex = source.index(source.startIndex, offsetBy: current)
        let text = source[startIndex..<endIndex]
        tokens.append(Token(type: type, lexeme: String(text), literal: literal, line: line))
    }
    
    private func match(_ expected: Character) -> Bool {
        if isAtEnd {
            return false
        }
        if source[current] != expected {
            return false
        }
        
        current += 1
        return true
    }
    
    private func peek() -> Character {
        if isAtEnd {
            return "\0"
        }
        return source[current]
    }
    
    private func peekNext() -> Character {
        if current + 1 >= source.count {
            return "\0"
        }
        return source[current + 1]
    }
    
    private func string() {
        while peek() != "\"" && !isAtEnd {
            if peek() == "\n" {
                line += 1
            }
            advance()
        }
        
        if isAtEnd {
            Slox.error(line: line, message: "Unterminated string.")
            return
        }
        
        advance() // eat closing "
        
        let text = source.substring(startIndex: start + 1, exclusiveEndIndex: current - 1)
        addToken(type: .string, literal: text)
    }
    
    private func number() {
        while peek().isNumber {
            advance()
        }
        
        if peek() == "." && peekNext().isNumber {
            advance()
            
            while peek().isNumber {
                advance()
            }
        }
        
        addToken(type: .number,
                 literal: Double(source.substring(startIndex: start, exclusiveEndIndex: current)))
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
    
    func substring(startIndex: Int, exclusiveEndIndex: Int) -> String {
        let start = index(self.startIndex, offsetBy: startIndex)
        let end = index(self.startIndex, offsetBy: exclusiveEndIndex)
        return String(self[start..<end])
    }
}
