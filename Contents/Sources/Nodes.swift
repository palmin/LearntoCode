// 
//  Nodes.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
/*
     <abstract>
         Very basic node structures for keeping track of Statements and Expressions found in Contents.swift.
     </abstract>
 
     Copyright © 2016 Apple Inc. All Rights Reserved.
*/

import Foundation

// MARK: Protocols

public protocol Node {
    var lineCount: Int { get }
}

public protocol Expression: Node {
    var identifier: String { get }
}
extension Expression {
    public var lineCount: Int {
        return 1
    }
}

public protocol Statement: Node {
    var type: Keyword { get }
    var body: [Node] { get }
}

extension Statement {
    public var lineCount: Int {
        return body.reduce(1) { $0 + $1.lineCount }
    }
}

// MARK: Nodes

public struct CallNode: Expression {
    public let identifier: String
}

public struct VariableNode: Expression {
    public let identifier: String
}

public struct DefinitionNode: Statement {
    public var type: Keyword {
        return .func
    }
    
    public let name: String
    public let parameters: String
    public let body: [Node]
    
    public init(name: String, parameters: String, body: [Node]) {
        self.name = name
        self.parameters = parameters
        self.body = body
    }
}

public struct LoopNode: Statement {
    public let type: Keyword
    public let condition: String
    public let body: [Node]
}

public struct ConditionalStatementNode: Statement {
    public let type: Keyword
    public let condition: String
    public let body: [Node]
}
