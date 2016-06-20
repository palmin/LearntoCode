// 
//  Commandable.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

// MARK: CommandPerformer

protocol CommandCompletionDelegate: class {
    func commandableFinished(_ commandable: Commandable)
//    func performer(commandable: Commandable, didCompleteCommand: Command)
}

protocol Commandable: class {
    
    var id: Int { get }
    
    func perform(_ command: Command)
    func cancel(_ command: Command)
    
    // O(1) immediate state change. 
    func applyStateChange(for command: Command)
}

/// Used by the ActorComponents as a generic interface for running a command.
protocol ActorComponent: Commandable {
    unowned var actor: Actor { get }

    init(actor: Actor)

    func performRandom(action: ActorAction, withSpeed: Float)
    func perform(action: ActorAction, atIndex: Int, speed: Float)
}

// Default implementations
extension ActorComponent {
    var node: SCNNode {
        return actor.node
    }
    
    var id: Int {
        return actor.id
    }
    
    func key(for command: Command) -> String {
        return "\(self).\(command)"
    }
    
    func applyStateChange(for command: Command) {
        // Optional implementation
    }
    
    func perform(_ command: Command) {
        // Not all commands apply to the actor, return immediately if there is no action.
        guard let action = command.action else { return }
        performRandom(action: action)
    }
    
    func cancel(_ command: Command) {
        node.removeAnimation(forKey: key(for: command))
        node.removeAction(forKey: key(for: command))
    }
    
    /// Runs the animation, if one exists, for the specified type. Returns the duration.
    func performRandom(action: ActorAction) {
        performRandom(action: action, withSpeed: actor.commandSpeed)
    }
    
    func performRandom(action: ActorAction, withSpeed: Float) {
        // Optional implementation
    }
    
    func perform(action: ActorAction, atIndex index: Int, speed: Float) {
        // Optional implementation
    }
}
