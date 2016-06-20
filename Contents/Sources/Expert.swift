// 
//  Expert.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public final class Expert: Actor {
    
    public convenience init() {
        let node = ActorType.expert.createNode()
        node.name! += "-" + ActorType.expert.rawValue
        
        self.init(node: node)!
    }
    
    public required init?(node: SCNNode) {
        super.init(node: node)
    }
    
    @available(*, unavailable, message:"Oops! The Expert cannot jump 😕. Only the Character type can call the jump() method.")
    public override func jump() -> Coordinate {
        return coordinate
    }
}

extension Expert {
    
    /**
    Method that turns a lock up, causing all linked platforms to rise the height of one block.
     */
    public func turnLockUp() {
        guard let lock = world?.existingNode(ofType: PlatformLock.self, at: nextCoordinateInCurrentDirection)
            where lock.level == self.level else {
            
            return
        }
                
        add(command: .control(lock: lock, movingUp: true))
    }
    
    /**
     Method that turns a lock down, causing all linked platforms to fall the height of one block.
     */
    public func turnLockDown() {
        guard let lock = world?.existingNode(ofType: PlatformLock.self, at: nextCoordinateInCurrentDirection)
            where lock.level == self.level else {
            
            return
        }
        
        add(command: .control(lock: lock, movingUp: false))
    }
    
    /**
     Method that turns a lock either up or down a certain number of times.
     */
    public func turnLock(up: Bool, numberOfTimes: Int) {
        if up == true {
            for _ in 1...numberOfTimes {
                turnLockUp()
            }
        } else {
            for _ in 1...numberOfTimes {
                turnLockDown()
            }
        }
    }
}
