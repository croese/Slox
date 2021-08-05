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
    case variable(name: Token)
    case assign(name: Token, value: Expr)
    case logical(left: Expr, op: Token, right: Expr)
    case call(callee: Expr, paren: Token, arguments: [Expr])
    case funLiteral(token: Token, params: [Token], body: [Stmt])
}

