// 
//  _KeyValueStoreAccess.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import PlaygroundSupport
import Foundation

/// The name of the current page being presented.
/// Must be manually set in the pages auxiliary sources.
public var pageIdentifier = ""

struct KeyValueStoreKey {
    
    static let characterName = "MicroWorlds.CharacterNameKey"
    static let characterPickerDomainName = "com.apple.learntocode.customization"
    
    static var executionCount: String {
        return "MicroWorlds.\(pageIdentifier).executionCountKey"
    }
    
}

public func currentPageRunCount() -> Int {
    let store = PlaygroundPage.current.keyValueStore
    if let value = store[KeyValueStoreKey.executionCount], case .integer(let count) = value {
        return count
    }
    
    return 0
}



extension ActorType {
    
    static func loadDefault() -> ActorType {
        // Return `.byte` as the default if no saved value is found.
        let fallbackType: ActorType = .byte

        if let value = UserDefaults(suiteName:KeyValueStoreKey.characterPickerDomainName)?.object(forKey: KeyValueStoreKey.characterName) {
            return ActorType(rawValue: value as! String) ?? fallbackType
        }
    
        return fallbackType
    }
    
    func saveAsDefault() {
        if let defaults = UserDefaults(suiteName: KeyValueStoreKey.characterPickerDomainName) {
            defaults.set(self.rawValue, forKey:KeyValueStoreKey.characterName)
            defaults.synchronize()
        }
    }
}
