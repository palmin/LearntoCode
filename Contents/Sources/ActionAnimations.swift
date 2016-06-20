// 
//  ActionAnimations.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

struct ActionAnimations {
    typealias Animations = [CAAnimationGroup]
    
    static var actorActionsForType = [ActorType: [ActorAction: Animations]]()
    
    // MARK: Animation Loading
    
    static func loadAnimations(for type: ActorType, actions: [ActorAction]) {
        // Grab the existing animations if there are any.
        var animationsForAction: [ActorAction: [CAAnimationGroup]] = actorActionsForType[type] ?? [:]
        let identifiers = ActorAction.allIdentifiersByType
        
        for action in actions {
            guard animationsForAction[action] == nil else { continue } // Don't reload existing animations.
            
            for identifier in identifiers[action] ?? [] {
                let prefix = type.resourceFilePathPrefix
                guard let animationGroup = loadAnimation(prefix + identifier) else { continue }
                
                animationsForAction[action] = [animationGroup] + (animationsForAction[action] ?? [])
            }
        }
        
        actorActionsForType[type] = animationsForAction
    }
    
    // MARK:
    
    let type: ActorType
    var animationsForAction: [ActorAction: Animations] {
        return ActionAnimations.actorActionsForType[self.type] ?? [:]
    }
    
    init(type: ActorType) {
        self.type = type
    }
    
    func animations(for action: ActorAction) -> Animations {
        let animations = animationsForAction[action] ?? []
        
        if animations.isEmpty {
            log(message: "Cache miss. Loading '\(action)' action for \(type).")
            ActionAnimations.loadAnimations(for: type, actions: [action])
        }
        
        // Attempt to recover, but there may not be an animation for the requested action. 
        return animationsForAction[action] ?? []
    }
    
    /// `nil` returns a random animation for the provided action.
    /// If an invaild index is provided this wall fall back to a random animation
    /// for the action (if one exists).
    func animation(for action: ActorAction, index: Int? = nil) -> CAAnimationGroup? {
        let animations = self.animations(for: action)
        guard !animations.isEmpty else { return nil }
        
        let index = index ?? animations.randomIndex
        if animations.indices.contains(index) {
            return animations[index]
        }
        else {
            return animations.randomElement
        }
    }
    
    subscript(action: ActorAction) -> Animations {
        return animations(for: action)
    }
}
