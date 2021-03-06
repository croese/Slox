//
//  File.swift
//  
//
//  Created by Christian Roese on 8/3/21.
//

import Foundation

public class Environment {
    let enclosing: Environment?
    private var values = [String : Any?]()
    
    init() {
        self.enclosing = nil
    }
    
    init(enclosing: Environment) {
        self.enclosing = enclosing
    }
    
    public func define(name: String, value: Any?) {
        values[name] = value
    }
    
    public func get(name: Token) throws -> Any? {
        if let value = values[name.lexeme] {
            return value
        }
        
        if let parent = enclosing {
            return try parent.get(name: name)
        }
        
        throw RuntimeError(token: name, message: "Undefined variable '\(name.lexeme)'.")
    }
    
    public func assign(name: Token, value: Any?) throws {
        if values.keys.contains(name.lexeme) {
            values[name.lexeme] = value
            return
        }
        
        if let parent = enclosing {
            try parent.assign(name: name, value: value)
            return
        }
        
        throw RuntimeError(token: name, message: "Undefined variable '\(name.lexeme)'.")
    }
}
