// 
//  WorldActionComponent.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import SceneKit

class WorldActionComponent: ActorComponent {
    
    // MARK: Properties
    
    unowned let actor: Actor
    weak var world: GridWorld?
    
    private var animationDuration: TimeInterval {
        let animationComponent = actor.componentForType(AnimationComponent.self)
        return animationComponent?.currentAnimationDuration ?? 1.0
    }
    
    // MARK: Initializers
    
    required init(actor: Actor) {
        self.actor = actor
    }
    
    // MARK: CommandPerformer
    
    func applyStateChange(for command: Command) {
        switch command {
        case let .move(start, end):
            moveItemsBetween(start: start, end: end, animated: false)
            
        case .place(let nodes):
            for node in nodes {
                world?.add(node)
            }
            
        case .remove(let nodes):
            for node in nodes {
                world?.remove(node)
            }
            
        case let .toggleSwitch(coordinate, on):
            guard let switchNode = world?.existingNode(ofType: Switch.self, at: coordinate) else { break }
            // Mark that the switch should not be animated for this state change.
            
            world?.isAnimated = false
            switchNode.isOn = on
            world?.isAnimated = true
            
        case let .control(lock, isMovingUp):
            isMovingUp ? lock.raisePlatforms() : lock.lowerPlatforms()
            
        default:
            break
        }
    }
    
    func perform(_ command: Command) {
        // Unpack command. 
        switch command {
        case let .move(start, end):
            moveItemsBetween(start: start, end: end, animated: true)
            
        case let .teleport(from: start, end):
            teleportActorFrom(start, to: end)
        
        case let .toggleSwitch(coordinate, on):
            guard let switchNode = world?.existingNode(ofType: Switch.self, at: coordinate) else { break }
            switchNode.isOn = on

        case let .remove(nodes):
            guard let gem = nodes.first as? Gem else { fatalError("Actor cannot remove nodes other than gems. \(nodes)") }
            gem.collect(withDuration: animationDuration)
            
        case let .control(lock, isMovingUp):
            let movementDuration = animationDuration / 2
            let wait = SCNAction.wait(forDuration: animationDuration / 2)
            let movePlatforms = SCNAction.run { _ in
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = movementDuration
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                
                isMovingUp ? lock.raisePlatforms() : lock.lowerPlatforms()
                
                SCNTransaction.commit()
            }
            
            lock.node.run(.sequence([wait, movePlatforms]))
            
        default:
            break
        }
        actor.commandableFinished(self)
    }
    
    func cancel(_ command: Command) {
        switch command {
        case let .remove(nodes):
            nodes.first?.node.removeAllActions()
            
        default:
            node.removeAction(forKey: command.key)
        }
    }
    
    func moveItemsBetween(start: SCNVector3, end destination: SCNVector3, animated: Bool) {
        guard let world = world else { return }
        
        func moveGems(at coordinate: Coordinate, up: Bool) {
            let items = world.existingNodes(ofType: Gem.self, at: [coordinate])
            
            let duration = animated ? animationDuration : 0.0
            for item in items {
                item.move(up: up, withDuration: duration)
            }
        }

        // Raise upcoming gems.
        let incomingCoordinate = Coordinate(destination)
        moveGems(at: incomingCoordinate, up: true)
        
        // Lower passed gems.
        let leavingCoordinate = Coordinate(start)
        moveGems(at: leavingCoordinate, up: false)
    }
    
    // MARK: Teleportation
    
    func teleportActorFrom(_ position: SCNVector3, to newPosition: SCNVector3) {
        guard let world = world,
            startingPortal = world.existingNode(ofType: Portal.self, at: Coordinate(position)),
            endingPortal = world.existingNode(ofType: Portal.self, at: Coordinate(newPosition)) else { return }
        
        startingPortal.enter(atSpeed: actor.commandSpeed)
        endingPortal.exit(atSpeed: actor.commandSpeed)
    
        let halfWait = SCNAction.wait(forDuration: animationDuration / 2.0)
        let moveActor = SCNAction.move(to: newPosition, duration: 0.0)
        node.run(SCNAction.sequence([halfWait, moveActor]))
    }
}
