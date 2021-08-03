//
//  File.swift
//  
//
//  Created by Christian Roese on 8/3/21.
//

import Foundation

public enum Stmt {
    case empty
    case expression(expr: Expr)
    case print(expr: Expr)
    case `var`(name: Token, initializer: Expr?)
}
