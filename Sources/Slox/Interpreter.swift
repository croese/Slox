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
    
    init(token: Token, message: String) {
        self.token = token
        self.message = message
    }
}

public func interpret(expr: Expr) {
    do {
        let value = try evaluate(expr: expr)
        print(stringify(object: value))
    } catch let error as RuntimeError {
        Slox.runtimeError(error: error)
    } catch {
        fatalError("Unknown error: \(error.localizedDescription)")
    }
}

fileprivate func stringify(object: Any?) -> String {
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

fileprivate func evaluate(expr: Expr) throws -> Any? {
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
    }
}

fileprivate func isTruthy(_ object: Any?) -> Bool {
    guard let o = object else {
        return false
    }
    if o is Bool {
        return o as! Bool
    }
    return true
}

fileprivate func isEqual(_ a: Any?, _ b: Any?) -> Bool {
    if a == nil && b == nil {
        return true
    }
    
    guard a is AnyHashable else { return false }
    guard b is AnyHashable else { return false }
    return (a as! AnyHashable) == (b as! AnyHashable)
}

fileprivate func checkNumberOperand(op: Token, operand: Any?) throws {
    guard operand is Double else {
        throw RuntimeError(token: op, message: "Operand must be a number.")
    }
}

fileprivate func checkNumberOperands(op: Token, left: Any?, right: Any?) throws {
    guard left is Double && right is Double else {
        throw RuntimeError(token: op, message: "Operands must be numbers.")
    }
}
