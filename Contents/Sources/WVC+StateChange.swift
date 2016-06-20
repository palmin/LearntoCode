// 
//  WVC+StateChange.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

/// Used to mark actions that are run as part of scene completion.
/// These actions should all be mutually exclusive.
private let sceneCompletionActionKey = "SceneComplete"

extension WorldViewController: SceneStateDelegate {
    
    // MARK: GridWorldStateDelegate
    
    func scene(_ scene: Scene, didEnterState state: Scene.State) {
        
        if case .done = state {
            guard !isDisplayingEndState else { return }
            isDisplayingEndState = true
            
            sceneCompleted(scene: scene)
        }
    }
    
    // MARK: End State
    
    func sceneCompleted(scene: Scene) {
        let evaluationQueue = OperationQueue()
        
        evaluationQueue.addOperation { [unowned self] in
            let diff = scene.gridWorld.calculateResults()
        
            OperationQueue.main().addOperation { [unowned self] in
                // Setting the diff will trigger a notification to alert any assessment code.
                scene.gridWorld.diff = diff

                // Determine if there is anything interesting to show.
                let hasCommands = !scene.commandQueue.commandsFor(actor: scene.mainActor).isEmpty
                
                guard hasCommands else {
                    self.showContinuousIdle()
                    return
                }
                
                if diff.passesCriteria {
                    self.showSuccessState()
                } else {
                     self.showDefeatedState()
                }
            }
        }
    }
    
    // MARK: Animations
    
    var fadeDuration: CGFloat {
        return 0.3
    }

    func showContinuousIdle() {
        // Otherwise show a bored character.
        for actor in scene.actors {
            let actorAnimations = ActionAnimations(type: actor.type)
            guard let idleAnimation = actorAnimations[.idle].randomElement else { continue }

            idleAnimation.fadeInDuration = fadeDuration
            idleAnimation.fadeOutDuration = fadeDuration
            
            let actorIdle = SCNAction.animate(with: idleAnimation, forKey: "Idle")
            let wait = SCNAction.wait(forDuration: 5, withRange: 3)
            let repeatAction = SCNAction.run { [weak self] _ in
                
                // Start the entire sequence over with a new random animation. 
                self?.showContinuousIdle()
            }
            
            actor.node.run(.sequence([wait, actorIdle, repeatAction]), forKey: sceneCompletionActionKey)
        }
    }
    
    func showDefeatedState() {
        // Show the character defeated.
        for actor in scene.actors {
            let actorAnimations = ActionAnimations(type: actor.type)
            guard let defeatAnimation = actorAnimations[.defeat].randomElement else { continue }
            
            defeatAnimation.fadeInDuration = fadeDuration
            defeatAnimation.fadeOutDuration = fadeDuration
            
            let animate = SCNAction.animate(with: defeatAnimation, speed: 0.7)
            
            let wait = SCNAction.wait(forDuration: 0.5)
            let idleContinuously = SCNAction.run { [unowned self] _ in
                // Idle after looking defeated.
                self.showContinuousIdle()
            }
            
            actor.node.run(.sequence([animate, wait, idleContinuously]), forKey: sceneCompletionActionKey)
        }
        
        let defeatMessage = "The level is incomplete, Byte looks sad."
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, defeatMessage)
    }

    func showSuccessState() {
        guard let actor = scene.mainActor else { return }

        // Disable gesture recognizers while camera pans.
        view.gesturesEnabled = false
        
        let (duration, _) = cameraController?.performFlyover(toFace: actor.rotation) ?? (0, 0)
//        cameraController?.zoomCamera(byYFov: 15, duration: duration)
        
        let delayAction = SCNAction.wait(forDuration: duration * 0.65)
        
        for actor in scene.actors {
            let actorAnimations = ActionAnimations(type: actor.type)
            var actions = [delayAction]
            
            if let celebrationAnimation = actorAnimations[.celebration].first {
                celebrationAnimation.fadeOutDuration = fadeDuration
                actions.append(.animate(with: celebrationAnimation))
            }
            
            if let victoryAnimation = actorAnimations[.victory].randomElement {
                victoryAnimation.fadeInDuration = fadeDuration
                victoryAnimation.fadeOutDuration = fadeDuration
                actions.append(.animate(with: victoryAnimation, speed: 0.7))
            }
            
            if let happyIdleAnimation = actorAnimations[.happyIdle].first {
                happyIdleAnimation.speed = 0.65
                
                let fadeHappy = happyIdleAnimation.copy() as! CAAnimation
                fadeHappy.fadeInDuration = fadeDuration
                
                let initialHappy = SCNAction.animate(with: fadeHappy)
                
                // Repeat the happy animation without the fade duration to prevent
                // the character from continually opening it's mouth.
                let repeatingHappy = SCNAction.animate(with: happyIdleAnimation)
                
                actions.append(.sequence([initialHappy, .repeatForever(repeatingHappy)]))
            }

            
            actor.node.run(.sequence(actions), forKey: sceneCompletionActionKey)
        }
        
        let cameraWait = SCNAction.wait(forDuration: duration)
        scene.rootNode.run(cameraWait) { [unowned self] in
            // Re-enable gestures after camera pan completes.
                self.view.gesturesEnabled = true
        }
    }
}
