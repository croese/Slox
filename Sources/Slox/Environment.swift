//
//  File.swift
//  
//
//  Created by Christian Roese on 8/3/21.
//

import Foundation

public class Environment {
    private var values = [String : Any?]()
    
    public func define(name: String, value: Any?) {
        values[name] = value
    }
    
    public func get(name: Token) throws -> Any? {
        if let value = values[name.lexeme] {
            return value
        }
        
        throw RuntimeError(token: name, message: "Undefined variable '\(name.lexeme)'.")
    }
    
    public func assign(name: Token, value: Any?) throws {
        if values.keys.contains(name.lexeme) {
            values[name.lexeme] = value
            return
        }
        
        throw RuntimeError(token: name, message: "Undefined variable '\(name.lexeme)'.")
    }
}
