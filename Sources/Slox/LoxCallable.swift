//
//  File.swift
//  
//
//  Created by Christian Roese on 8/4/21.
//

import Foundation

public protocol LoxCallable: CustomStringConvertible {
    var arity: Int { get }
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any?
}


