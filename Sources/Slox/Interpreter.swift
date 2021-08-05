//
//  File.swift
//  
//
//  Created by Christian Roese on 8/3/21.
//

import Foundation

public struct RuntimeError: Error {
    let token: Token
    let message: String
}

private struct BreakStatement: Error {
    let breakToken: Token
}

public struct Return: Error {
    let value: Any?
    
    init(value: Any?) {
        self.value = value
    }
}

public class Interpreter {
    
    public let globals = Environment()
    private var environment: Environment!
    
    init() {
        environment = globals
        globals.define(name: "clock", value: LoxClockBuiltin())
    }
    
    public func interpret(statements: [Stmt]) {
        do {
            for stmt in statements {
                try execute(stmt)
            }
        } catch let error as RuntimeError {
            Slox.runtimeError(error: error)
        } catch let error as BreakStatement {
            Slox.runtimeError(error: RuntimeError(token: error.breakToken,
                                                  message: "Break statements can only appear within a loop."))
        } catch {
            fatalError("Unknown error: \(error.localizedDescription)")
        }
    }
    
    private func execute(_ stmt: Stmt) throws {
        switch stmt {
        case .print(let expr):
            let value = try evaluate(expr: expr)
            print(stringify(object: value))
        case .expression(let expr):
            try evaluate(expr: expr)
        case .empty: break
        case .var(let name, let initializer):
            var value: Any? = nil
            if let i = initializer {
                value = try evaluate(expr: i)
            }
            
            environment.define(name: name.lexeme, value: value)
        case .block(let statements): try executeBlock(statements: statements,
                                                      environment: Environment(enclosing: self.environment))
        case .if(let condition, let thenBranch, let elseBranch):
            if isTruthy(try evaluate(expr: condition)) {
                try execute(thenBranch)
            } else if let el = elseBranch {
                try execute(el)
            }
        case .while(let condition, let body):
            while isTruthy(try evaluate(expr: condition)) {
                do {
                    try execute(body)
                } catch is BreakStatement {
                    break
                }
            }
        case .break(let token):
            throw BreakStatement(breakToken: token)
        case .function(let name, let params, let body):
            let function = LoxFunction(name: name.lexeme, params: params, body: body, closure: environment)
            environment.define(name: name.lexeme, value: function)
        case .return(keyword: _, value: let value):
            var result: Any?
            if let v = value {
                result = try evaluate(expr: v)
            }
            throw Return(value: result)
        }
    }
    
    internal func executeBlock(statements: [Stmt], environment: Environment) throws {
        let previous = self.environment
        
        defer {
            self.environment = previous
        }
        
        self.environment = environment
        for stmt in statements {
            try execute(stmt)
        }
    }
    
    private func stringify(object: Any?) -> String {
        guard let o = object else {
            return "nil"
        }
        
        if let num = o as? Double {
            var text = String(num)
            if text.hasSuffix(".0") {
                text = String(text.prefix(text.count - 2))
            }
            return text
        }
        
        return String(describing: o)
    }
    
    @discardableResult
    private func evaluate(expr: Expr) throws -> Any? {
        switch expr {
        case .binary(let left, let op, let right):
            let left = try evaluate(expr: left)
            let right = try evaluate(expr: right)
            
            switch op.type {
            case .greater:
                try checkNumberOperands(op: op, left: left, right: right)
                return (left as! Double) > (right as! Double)
            case .greaterEqual:
                try checkNumberOperands(op: op, left: left, right: right)
                return (left as! Double) >= (right as! Double)
            case .less:
                try checkNumberOperands(op: op, left: left, right: right)
                return (left as! Double) < (right as! Double)
            case .lessEqual:
                try checkNumberOperands(op: op, left: left, right: right)
                return (left as! Double) <= (right as! Double)
            case .bangEqual:
                return !isEqual(left, right)
            case .equalEqual:
                return isEqual(left, right)
            case .minus:
                try checkNumberOperands(op: op, left: left, right: right)
                return (left as! Double) - (right as! Double)
            case .slash:
                try checkNumberOperands(op: op, left: left, right: right)
                return (left as! Double) / (right as! Double)
            case .star:
                try checkNumberOperands(op: op, left: left, right: right)
                return (left as! Double) * (right as! Double)
            case .plus:
                if left is Double && right is Double {
                    return (left as! Double) + (right as! Double)
                }
                if left is String && right is String {
                    return (left as! String) + (right as! String)
                }
                throw RuntimeError(token: op, message: "Operands must be two numbers or two strings.")
            default:
                return nil
            }
        case .grouping(let expression): return try evaluate(expr: expression)
        case .literal(let value): return value
        case .unary(let op, let right):
            let right = try evaluate(expr: right)
            switch op.type {
            case .minus:
                try checkNumberOperand(op: op, operand: right)
                return -(right as! Double)
            case .bang: return !isTruthy(right)
            default: return nil
            }
        case .variable(name: let name): return try environment.get(name: name)
        case .assign(let name, let value):
            let value = try evaluate(expr: value)
            try environment.assign(name: name, value: value)
            return value
        case .logical(let left, let op, let right):
            let left = try evaluate(expr: left)
            if op.type == .or {
                if isTruthy(left) {
                    return left
                }
            } else {
                if !isTruthy(left) {
                    return left
                }
            }
            return try evaluate(expr: right)
        case .call(let callee, let paren, let arguments):
            let callee = try evaluate(expr: callee)
            
            let argValues = try arguments.map({ try evaluate(expr: $0) })
            
            guard let function = callee as? LoxCallable else {
                throw RuntimeError(token: paren, message: "Can only call functions and classes.")
            }
            
            if arguments.count != function.arity {
                throw RuntimeError(token: paren,
                                   message: "Expected \(function.arity) arguments but got \(arguments.count).")
            }
            
            return try function.call(interpreter: self, arguments: argValues)
        case .funLiteral(token: let token, params: let params, body: let body):
            return LoxFunction(name: "anon_func_line_\(token.line)", params: params, body: body, closure: environment)
        }
    }
    
    private func isTruthy(_ object: Any?) -> Bool {
        guard let o = object else {
            return false
        }
        if o is Bool {
            return o as! Bool
        }
        return true
    }
    
    private func isEqual(_ a: Any?, _ b: Any?) -> Bool {
        if a == nil && b == nil {
            return true
        }
        
        guard a is AnyHashable else { return false }
        guard b is AnyHashable else { return false }
        return (a as! AnyHashable) == (b as! AnyHashable)
    }
    
    private func checkNumberOperand(op: Token, operand: Any?) throws {
        guard operand is Double else {
            throw RuntimeError(token: op, message: "Operand must be a number.")
        }
    }
    
    private func checkNumberOperands(op: Token, left: Any?, right: Any?) throws {
        guard left is Double && right is Double else {
            throw RuntimeError(token: op, message: "Operands must be numbers.")
        }
    }
}
