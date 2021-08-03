//
//  File.swift
//  
//
//  Created by Christian Roese on 8/3/21.
//

import Foundation

public class Parser {
    private let tokens: [Token]
    private var current = 0
    
    private var isAtEnd: Bool {
        return peek().type == .eof
    }
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    public func parse() -> [Stmt] {
        do {
            var statements = [Stmt]()
            while !isAtEnd {
                statements.append(try statement())
            }
            
            return statements
        } catch {
            return []
        }
    }
    
    private func statement() throws -> Stmt {
        if match(.print) {
            return try printStatement()
        }
        return try expressionStatement()
    }
    
    private func printStatement() throws -> Stmt {
        let value = try expression()
        try consume(type: .semicolon, message: "Expect ';' after value.")
        return .print(expr: value)
    }
    
    private func expressionStatement() throws -> Stmt {
        let value = try expression()
        try consume(type: .semicolon, message: "Expect ';' after value.")
        return .expression(expr: value)
    }
    
    private func expression() throws -> Expr {
        return try equality()
    }
    
    private func match(_ types: TokenType...) -> Bool {
        for type in types {
            if check(type) {
                advance()
                return true
            }
        }
        return false
    }
    
    private func check(_ type: TokenType) -> Bool {
        if isAtEnd {
            return false
        }
        return peek().type == type
    }
    
    private func advance() -> Token {
        if !isAtEnd {
            current += 1
        }
        return previous()
    }
    
    private func peek() -> Token {
        return tokens[current]
    }
    
    private func previous() -> Token {
        return tokens[current - 1]
    }
    
    private func equality() throws -> Expr {
        var expr = try comparison()
        while match(.bangEqual, .equalEqual) {
            let op = previous()
            let right = try comparison()
            expr = .binary(left: expr, operator: op, right: right)
        }
        
        return expr
    }
    
    private func comparison() throws -> Expr {
        var expr = try term()
        while match(.greater, .greaterEqual, .less, .lessEqual) {
            let op = previous()
            let right = try term()
            expr = .binary(left: expr, operator: op, right: right)
        }
        
        return expr
    }
    
    private func term() throws -> Expr {
        var expr = try factor()
        while match(.plus, .minus) {
            let op = previous()
            let right = try factor()
            expr = .binary(left: expr, operator: op, right: right)
        }
        
        return expr
    }
    
    private func factor() throws -> Expr {
        var expr = try unary()
        while match(.slash, .star) {
            let op = previous()
            let right = try unary()
            expr = .binary(left: expr, operator: op, right: right)
        }
        
        return expr
    }
    
    private func unary() throws -> Expr {
        if match(.bang, .minus) {
            let op = previous()
            let right = try unary()
            return .unary(operator: op, right: right)
        }
        return try primary()
    }
    
    private func primary() throws -> Expr {
        if match(.false) {
            return .literal(value: false)
        }
        if match(.true) {
            return .literal(value: true)
        }
        if match(.nil) {
            return .literal(value: nil)
        }
        if match(.number, .string) {
            return .literal(value: previous().literal)
        }
        
        if match(.leftParen) {
            let expr = try expression()
            try consume(type: .rightParen, message: "Expect ')' after expression.")
            return .grouping(expression: expr)
        }
        
        throw error(token: peek(), message: "Expect expression.")
    }
    
    private func consume(type: TokenType, message: String) throws -> Token {
        if check(type) {
            return advance()
        }
        
        throw error(token: peek(), message: message)
    }
    
    private func error(token: Token, message: String) -> Parser.Error {
        Slox.error(token: token, message: message)
        return .parsingError
    }
    
    private func synchronize() {
        advance()
        while !isAtEnd {
            if previous().type == .semicolon {
                return
            }
            
            switch peek().type {
            case .class: fallthrough
            case .for: fallthrough
            case .fun: fallthrough
            case .if: fallthrough
            case .print: fallthrough
            case .return: fallthrough
            case .var: fallthrough
            case .while: fallthrough
                return
            default: break
            }
            
            advance()
        }
    }
}

public extension Parser {
    enum Error: Swift.Error {
        case parsingError
    }
}
