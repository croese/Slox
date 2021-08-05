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
        var statements = [Stmt]()
        while !isAtEnd {
            statements.append(declaration())
        }
        
        return statements
    }
    
    private func declaration() -> Stmt {
        do {
            if match(.fun) {
                return try function(kind: "function")
            }
            
            if match(.var) {
                return try varDeclaration()
            }
            return try statement()
        } catch {
            synchronize()
            return .empty
        }
    }
    
    private func function(kind: String) throws -> Stmt {
        let name = try consume(type: .identifier, message: "Expect \(kind) name.")
        try consume(type: .leftParen, message: "Expect '(' after \(kind) name.")
        var parameters = [Token]()
        if !check(.rightParen) {
            repeat {
                if parameters.count >= 255 {
                    error(token: peek(), message: "Can't have more than 255 parameters.")
                }
                parameters.append(try consume(type: .identifier, message: "Expect parameter name."))
            } while match(.comma)
        }
        try consume(type: .rightParen, message: "Expect ')' after parameters.")
        try consume(type: .leftBrace, message: "Expect '{' before \(kind) body.")
        let body = try block()
        return .function(name: name, params: parameters, body: body)
    }
    
    private func varDeclaration() throws -> Stmt {
        let name = try consume(type: .identifier, message: "Expect variable name.")
        
        var initializer: Expr?
        if match(.equal) {
            initializer = try expression()
        }
        
        try consume(type: .semicolon, message: "Expect ';' after variable declaration.")
        return .var(name: name, initializer: initializer)
    }
    
    private func statement() throws -> Stmt {
        if match(.break) {
            try consume(type: .semicolon, message: "Expect ';' after 'break'.")
            return .break(token: previous())
        }
        
        if match(.for) {
            return try forStatement()
        }
        
        if match(.if) {
            return try ifStatement()
        }
        
        if match(.print) {
            return try printStatement()
        }
        
        if match(.return) {
            return try returnStatement()
        }
        
        if match(.while) {
            return try whileStatement()
        }
        
        if match(.leftBrace) {
            return .block(statements: try block())
        }
        return try expressionStatement()
    }
    
    private func returnStatement() throws -> Stmt {
        let keyword = previous()
        var value: Expr? = nil
        if !check(.semicolon) {
            value = try expression()
        }
        
        try consume(type: .semicolon, message: "Expect ';' after return value.")
        return .return(keyword: keyword, value: value)
    }
    
    private func forStatement() throws -> Stmt {
        try consume(type: .leftParen, message: "Expect '(' after 'for'.")
        
        var initializer: Stmt?
        if match(.semicolon) {
            initializer = nil
        } else if match(.var) {
            initializer = try varDeclaration()
        } else {
            initializer = try expressionStatement()
        }
        
        var condition: Expr?
        if !check(.semicolon) {
            condition = try expression()
        }
        
        try consume(type: .semicolon, message: "Expect ';' after loop condition.")
        
        var increment: Expr?
        if !check(.rightParen) {
            increment = try expression()
        }
        try consume(type: .rightParen, message: "Expect ')' after for clause.")
        
        var body = try statement()
        
        if let inc = increment {
            body = .block(statements: [body, .expression(expr: inc)])
        }
        body = .while(condition: condition ?? .literal(value: true), body: body)
        
        if let i = initializer {
            body = .block(statements: [i, body])
        }
        
        return body
    }
    
    private func whileStatement() throws -> Stmt {
        try consume(type: .leftParen, message: "Expect '(' after 'while'.")
        let condition = try expression()
        try consume(type: .rightParen, message: "Expect ')' after while condition.")
        
        let body = try statement()
        
        return .while(condition: condition, body: body)
    }
    
    private func ifStatement() throws -> Stmt {
        try consume(type: .leftParen, message: "Expect '(' after 'if'.")
        let condition = try expression()
        try consume(type: .rightParen, message: "Expect ')' after if condition.")
        
        let thenBranch = try statement()
        var elseBranch: Stmt?
        if match(.else) {
            elseBranch = try statement()
        }
        
        return .if(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }
    
    private func printStatement() throws -> Stmt {
        let value = try expression()
        try consume(type: .semicolon, message: "Expect ';' after value.")
        return .print(expr: value)
    }
    
    private func block() throws -> [Stmt] {
        var statements = [Stmt]()
        
        while !check(.rightBrace) && !isAtEnd {
            statements.append(declaration())
        }
        
        try consume(type: .rightBrace, message: "Expect '}' after block.")
        return statements
    }
    
    private func expressionStatement() throws -> Stmt {
        let value = try expression()
        try consume(type: .semicolon, message: "Expect ';' after value.")
        return .expression(expr: value)
    }
    
    private func expression() throws -> Expr {
        return try assignment()
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
    
    @discardableResult
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
    
    private func assignment() throws -> Expr {
        let expr = try or()
        
        if match(.equal) {
            let equals = previous()
            let value = try assignment()
            
            switch expr {
            case .variable(let name): return .assign(name: name, value: value)
            default:
                error(token: equals, message: "Invalid assignment target.")
            }
        }
        
        return expr
    }
    
    private func or() throws -> Expr {
        var expr = try and()
        
        while match(.or) {
            let op = previous()
            let right = try or()
            expr = .logical(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    private func and() throws -> Expr {
        var expr = try equality()
        
        while match(.and) {
            let op = previous()
            let right = try equality()
            expr = .logical(left: expr, op: op, right: right)
        }
        
        return expr
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
        return try call()
    }
    
    private func call() throws -> Expr {
        var expr = try primary()
        
        while(true) {
            if match(.leftParen) {
                expr = try finishCall(expr)
            } else {
                break
            }
        }
        
        return expr
    }
    
    private func finishCall(_ callee: Expr) throws -> Expr {
        var arguments = [Expr]()
        if !check(.rightParen) {
            repeat {
                if arguments.count >= 255 {
                    error(token: peek(), message: "Can't have more than 255 arguments.")
                }
                arguments.append(try expression())
            } while(match(.comma))
        }
        
        let paren = try consume(type: .rightParen, message: "Expect ')' after arguments.")
        
        return .call(callee: callee, paren: paren, arguments: arguments)
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
        
        if match(.fun) { // anonymous function
            let token = previous()
            try consume(type: .leftParen, message: "Expect '(' after 'fun' in anonymous function.")
            var parameters = [Token]()
            if !check(.rightParen) {
                repeat {
                    if parameters.count >= 255 {
                        error(token: peek(), message: "Can't have more than 255 parameters.")
                    }
                    parameters.append(try consume(type: .identifier, message: "Expect parameter name."))
                } while match(.comma)
            }
            try consume(type: .rightParen, message: "Expect ')' after parameters.")
            try consume(type: .leftBrace, message: "Expect '{' before anonymous function body.")
            let body = try block()
            return .funLiteral(token: token, params: parameters, body: body)
        }
        
        if match(.identifier) {
            return .variable(name: previous())
        }
        
        if match(.leftParen) {
            let expr = try expression()
            try consume(type: .rightParen, message: "Expect ')' after expression.")
            return .grouping(expression: expr)
        }
        
        throw error(token: peek(), message: "Expect expression.")
    }
    
    @discardableResult
    private func consume(type: TokenType, message: String) throws -> Token {
        if check(type) {
            return advance()
        }
        
        throw error(token: peek(), message: message)
    }
    
    @discardableResult
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
            case .while: 
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
