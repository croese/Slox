//
//  File.swift
//  
//
//  Created by Christian Roese on 8/2/21.
//

import Foundation

public indirect enum Expr {
    case binary(left: Expr, operator: Token, right: Expr)
    case grouping(expression: Expr)
    case literal(value: Any?)
    case unary(operator: Token, right: Expr)
}

fileprivate func parenthesize(name: String, _ exprs: Expr...) -> String {
    var builder = String()
    
    builder.append("(\(name)")
    for e in exprs {
        builder.append(" ")
        builder.append(printExpr(expr: e))
    }
    builder.append(")")
    
    return builder
}

func printExpr(expr: Expr) -> String {
    switch expr {
    case .binary(let left, let op, let right): return parenthesize(name: op.lexeme, left, right)
    case .grouping(let expression): return parenthesize(name: "group", expression)
    case .literal(let value): return "\(value ?? "nil")"
    case .unary(let op, let right): return parenthesize(name: op.lexeme, right)
    }
}

func rpn(expr: Expr) -> String {
    switch expr {
    case .binary(let left, let op, let right): return "\(rpn(expr: left)) \(rpn(expr: right)) \(op.lexeme)"
    case .grouping(let expression): return rpn(expr: expression)
    case .literal(let value): return "\(value ?? "nil")"
    case .unary(let op, let right): return "\(rpn(expr: right)) \(op.lexeme)"
    }
}
