//
//  File.swift
//  
//
//  Created by Christian Roese on 8/3/21.
//

import Foundation

public indirect enum Stmt {
    case empty
    case expression(expr: Expr)
    case print(expr: Expr)
    case `var`(name: Token, initializer: Expr?)
    case block(statements: [Stmt])
    case `if`(condition: Expr, thenBranch: Stmt, elseBranch: Stmt?)
    case `while`(condition: Expr, body: Stmt)
    case `break`(token: Token)
    case function(name: Token, params: [Token], body: [Stmt])
    case `return`(keyword: Token, value: Expr?)
}
