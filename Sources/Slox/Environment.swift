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
}
