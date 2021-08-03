//
//  File.swift
//  
//
//  Created by Christian Roese on 8/3/21.
//

import Foundation

public enum Stmt {
    case expression(expr: Expr)
    case print(expr: Expr)
}
