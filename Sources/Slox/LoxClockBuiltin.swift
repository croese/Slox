//
//  File.swift
//  
//
//  Created by Christian Roese on 8/5/21.
//

import Foundation

public class LoxClockBuiltin: LoxCallable {
    public var description: String {
        return "<native fn>"
    }
    
    public var arity: Int {
        return 0
    }
    
    public func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        return Date().timeIntervalSince1970
    }
}
