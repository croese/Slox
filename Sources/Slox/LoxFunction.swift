//
//  File.swift
//  
//
//  Created by Christian Roese on 8/5/21.
//

import Foundation

class LoxFunction: LoxCallable {
    let description: String
    let arity: Int
    
    private let params: [Token]
    private let body: [Stmt]
    private let closure: Environment
    
    init(name: String, params: [Token], body: [Stmt], closure: Environment) {
        description = "<fn \(name)>"
        arity = params.count
        self.params = params
        self.body = body
        self.closure = closure
    }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        let environment = Environment(enclosing: closure)
        for (i, param) in params.enumerated() {
            environment.define(name: param.lexeme, value: arguments[i])
        }
        
        do {
            try interpreter.executeBlock(statements: body, environment: environment)
        } catch let ret as Return {
            return ret.value
        }
        return nil
    }
    
    
}
