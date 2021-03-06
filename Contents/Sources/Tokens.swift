// 
//  Tokens.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
/*
     <abstract>
         TokenGenerator is a basic generator used to convert text into Tokens.
     </abstract>
     
     Copyright © 2016 Apple Inc. All Rights Reserved.
*/

import Foundation

// Only looking for a very limited set of keywords.
public enum Keyword: String {
    case `if` = "if"
    case `else` = "else"
    case elseIf = "else if"
    case `for` = "for"
    case `while` = "while"
    case `func` = "func"
}

// MARK: Token

enum Token {
    case identifier(String)
    case keyword(Keyword)
    
    case number(Double)
    
    // Includes punctuation, literals, and operators.
    case other(String)
    
    var contents: String {
        switch self {
        case .keyword(let kw): return kw.rawValue
        case .identifier(let str): return str
        case .number(let num): return String(num)
        case .other(let str): return str
        }
    }
}

extension Token: Equatable {}
func ==(lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case (.identifier(let l), .identifier(let r)) where l == r: return true
    case (.keyword(let l), .keyword(let r)) where l == r: return true
    case (.number(let l), .number(let r)) where l == r: return true
    case (.other(let l), .other(let r)) where l == r: return true
    default: return false
    }
}

struct Tokenizer {
    let expression: RegularExpression
    let transformToToken: (String) -> Token?
    
    init(pattern: String, transform: (String) -> Token?) throws {
        // "^" to match only the beginning of the provided content.
        expression = try RegularExpression(pattern: "^\(pattern)", options: [])
        self.transformToToken = transform
    }
    
    func firstMatch(in content: String) -> (length: Int, token: Token?)? {
        let contentRange = NSMakeRange(0, content.utf16.count)
        let matchRange = expression.rangeOfFirstMatch(in: content, options: [], range: contentRange)
        guard matchRange.location != NSNotFound else { return nil }
        
        let match = (content as NSString).substring(with: matchRange)
        return (matchRange.length, transformToToken(match))
    }
}

struct TokenIterator: IteratorProtocol {

    let tokenizers = [
        try! Tokenizer(pattern: "\\/\\*[\\s\\S]*?\\*\\/") { _ in nil }, // Multiline Comments
        try! Tokenizer(pattern: "\\/\\/[^\\n]*\\n?") { _ in nil }, // Single line Comments
        try! Tokenizer(pattern: "[ \\t\\n]") { _ in nil }, // Empty space
        
        try! Tokenizer(pattern: "\\d{0,}\\.?\\d{1,}") { .number(Double($0)!) },

        try! Tokenizer(pattern: "[\"'`]?[a-zA-Z][\\w.\"'`]*") { word in
            if let keyword = Keyword(rawValue: word) {
                return .keyword(keyword)
            }
            return .identifier(word)
        },
    ]
    
    let content: String
    let characters: String.CharacterView
    
    var index: String.CharacterView.Index
    
    init(content: String) {
        self.content = content
        
        characters = content.characters
        index = characters.startIndex
    }
    
    // MARK: IteratorProtocol
    
    mutating func next() -> Token? {
        // Not all matches produce a valid token, some are used just to advance the content.
        var token: Token?
        
        repeat {
            let remainingCharacters = characters.suffix(from: index)
            guard !remainingCharacters.isEmpty else { return nil }
            
            let remainingContent = String(remainingCharacters)
            if let match = firstMatch(in: remainingContent) {
                // Only take the first match. Matches should be mutually exclusive.
                token = match.token
                
                // Advance content passed matched expression.
                index = characters.index(index, offsetBy: match.length)
            }
            else {
                // Advance by one character if no match was found.
                index = characters.index(after: index)
                
                let nextCharacter = remainingCharacters.first!
                token = .other(String(nextCharacter))
            }
            
        // If a valid token could not be found, loop to find a token, or return `nil`
        // when there are no remaining characters.
        } while token == nil
        
        return token
    }
    
    func firstMatch(in content: String) -> (length: Int, token: Token?)? {
        for generator in tokenizers {
            guard let match = generator.firstMatch(in: content) else { continue }
            
            // Only take the first match. Matches should be mutually exclusive.
            return match
        }
        
        return nil
    }
}

struct TokenGenerator: Sequence {
    let content: String
    
    func makeIterator() -> TokenIterator {
        return TokenIterator(content: content)
    }
}
