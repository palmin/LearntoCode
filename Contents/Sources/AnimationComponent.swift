// 
//  AnimationComponent.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

class AnimationComponent: NSObject, ActorComponent {
    // MARK: Properties
    
    unowned let actor: Actor
    
    var actionAnimations: ActionAnimations {
            return ActionAnimations(type: self.actor.type)
    }

    /// The command that is currently running, if any.
    private var currentCommand: Command?
    
    private var animationIndex = 0
    
    var currentAnimationDuration = 0.0
    
    let defaultAnimationKey = "DefaultAnimation-Key"
    
    // MARK: Initializers
    
    required init(actor: Actor) {
        self.actor = actor
        super.init()
    }
    
    func runDefaultAnimationIndefinitely() {
        guard let defaultAnimation = actionAnimations[.default].first else { return }
        node.removeAllAnimations()
        
        defaultAnimation.repeatCount = Float.infinity
        defaultAnimation.fadeInDuration = 0.3
        defaultAnimation.fadeOutDuration = 0.3
        node.add(defaultAnimation, forKey: defaultAnimationKey)
    }
    
    // MARK: CommandPerformer
    
    func applyStateChange(for command: Command) {
        switch command {
        case .move(_, let destination): actor.position = destination
        case .turn(_, let rotation, _): actor.rotation = rotation
        case .teleport(_, let destination): actor.position = destination
        default: break
        }
    }
    
    func perform(_ command: Command) {
        // Not all commands apply to the actor, return immediately if there is no action.
        guard let action = command.action else { return }
        
        currentCommand = command
        performRandom(action: action, withSpeed: actor.commandSpeed)
    }
    
    func performRandom(action: ActorAction, withSpeed speed: Float) {
        let animations = self.actionAnimations[action]
        
        perform(action: action, atIndex: animations.randomIndex, speed: speed)
    }
    
    func perform(action: ActorAction, atIndex index: Int, speed: Float) {
        let animation: CAAnimation?
        
        // Look for a faster variation of the requested action to play at speeds above `WorldConfiguration.Actor.walkRunSpeed`.
        if speed > WorldConfiguration.Actor.walkRunSpeed,
            let fastVariation = action.fastVariation,
            fastAnimation = actionAnimations.animation(for: fastVariation, index: animationIndex) {
            
            animation = fastAnimation
            animationIndex = animationIndex == 0 ? 1 : 0
        }
        else {
            animation = actionAnimations.animation(for: action, index: index)
            animation?.speed = ActorAction.walkingActions.contains(action) ? speed : 1.0
        }
        
        guard let readyAnimation = animation else { return }
        readyAnimation.delegate = self
        
        removeCommandAnimations()
        node.add(readyAnimation, forKey: action.rawValue)
        
        // Set the current animation duration.
        currentAnimationDuration = readyAnimation.duration / Double(readyAnimation.speed)
    }
    
    func cancel(_: Command) {
        removeCommandAnimations()
        currentCommand = nil
    }
    
    func removeCommandAnimations() {
        // Remove all animations, but the default.
        for key in actor.node.animationKeys where key != defaultAnimationKey {
            node.removeAnimation(forKey: key)
        }
    }
    
    // MARK: CAAnimation Delegate
    
    override func animationDidStop(_: CAAnimation, finished isFinished: Bool) {
        // Move the character after the animation completes.
        if isFinished {
            completeCurrentCommand()
        }
    }
    
    /// Translates the character based on the type of command.
    private func completeCurrentCommand() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.0
        
        if let command = currentCommand {
            // Update the node's position.
            applyStateChange(for: command)
        }
        
        removeCommandAnimations()
        #if DEBUG
        //assert(actor.node.animationKeys.count < 3, "There should never be more than the default and current command animations on the actor.")
        #endif
        
        // Cleanup current state. 
        currentCommand = nil
        currentAnimationDuration = 0.0
        
        SCNTransaction.commit()
        
        // Fire off the next animation.
        markCommandableFinished()
    }
    
    func markCommandableFinished() {
        DispatchQueue.main.asynchronously {
            self.actor.commandableFinished(self)
        }
    }
}

func loadAnimation(_ name: String) -> CAAnimationGroup? {
    guard let sceneURL = Bundle.main().urlForResource(name, withExtension: "dae") else {
        log(message: "1: Failed to find \(name) animation")
        return nil
    }
    guard let sceneSource = SCNSceneSource(url: sceneURL, options: nil) else {
        log(message: "2: Failed to load scene source from \(sceneURL).")
        return nil
    }
    
    let animationIdentifier = sceneSource.identifiersOfEntries(with: CAAnimation.self)
    guard let groupedAnimation = animationIdentifier.first else {
        log(message: "3: Failed to grab CAAnimation from \(sceneSource).")
        return nil
    }
    let animation = sceneSource.entryWithIdentifier(groupedAnimation, withClass: CAAnimation.self) as? CAAnimationGroup
        
    animation?.setDefaultAnimationValues()

    return animation
}
