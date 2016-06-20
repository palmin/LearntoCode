// 
//  Command.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

enum Command {
    case move(from: SCNVector3, to: SCNVector3)
    case teleport(from: SCNVector3, to: SCNVector3)
    
    /// The angle must be specified in radians.
    case turn(from: SCNFloat, to: SCNFloat, clockwise: Bool)
    
    case place([WorldNode])
    case remove([WorldNode])
    case toggleSwitch(at: Coordinate, on: Bool)
    case control(lock: PlatformLock, movingUp: Bool)
    
    case incorrectPickUp
    case incorrectToggleSwitch
    case incorrectOffEdge // Off edge/ into obstacle
    case incorrectIntoWall // Raised tile, wall, lock
    
    /// Provides a mapping of the command to a less specific `ActorAction`.
    var action: ActorAction? {
        switch self {
        case let .move(from, to):
            if from.y.isClose(to: to.y, epiValue: WorldConfiguration.heightTolerance) {
                return .walk
            }
            return from.y < to.y ? .walkUpStairs : .walkDownStairs
            
        case .teleport(_):
            return .teleport
            
        case .turn(_, _, let clockwise):
            return clockwise ? .turnRight : .turnLeft
            
        case .toggleSwitch(_):
            return .toggleSwitch
            
        case .control(_, let isMovingUp):
            return isMovingUp ? .turnLockRight : .turnLockLeft
            
        case .remove(_):
            return .pickUp
            
        case .incorrectOffEdge:
            return .almostFallOffEdge
            
        case .incorrectIntoWall:
            return .bumpIntoWall
            
        case .incorrectPickUp:
            return .pickUp
            
        case .incorrectToggleSwitch:
            return .toggleSwitch
            
        default:
            return nil
        }
    }
}

extension Command {
    
    var isPickUpCommand: Bool {
        if case .remove(_) = self {
            return true
        }
        return false
    }
    
    var reversed: Command {
        switch self {
        case let .move(to, from):
            return .move(from: from, to: to)
        
        case let .teleport(start, end):
            return .teleport(from: end, to: start)
            
        case let .turn(from, to, clkwise):
            return .turn(from: to, to: from, clockwise: clkwise)
            
        case let .remove(nodes):
            return .place(nodes)

        case let .place(nodes):
            return .remove(nodes)
            
        case let .toggleSwitch(coordinate, on):
            return .toggleSwitch(at: coordinate, on: !on)
            
        case let .control(lock, isMovingUp):
            return .control(lock: lock, movingUp: !isMovingUp)
            
        default:
            return self
        }
    }
}

extension Command: Equatable {}
func ==(lhs: Command, rhs: Command) -> Bool {
    switch (lhs, rhs) {
    case (let .move(to1, from1), let .move(to2, from2)):
        return Coordinate(to1) == Coordinate(to2)
        && Coordinate(from1) == Coordinate(from2)
        
    case (let .turn(deg1), let .turn(deg2)):
        return deg1 == deg2
        
    case (let .remove(nodes1), let .remove(nodes2)):
        return nodes1 == nodes2
        
    case (let .toggleSwitch(coor1), let .toggleSwitch(coor2)):
        return coor1 == coor2
        
    case (.incorrectPickUp, _), (.incorrectOffEdge, _), (.incorrectIntoWall, _):
        return lhs.action == rhs.action
        
    default: return false
    }
}

extension Command {
    var speakableDescription: String {
        switch self {
        case let .move(from, to):
            let coordinate = Coordinate(to)
            
            if from.y.isClose(to: to.y) {
                let prefix = "moved forward to "
                return prefix + coordinate.description
            }
            let isAscending = from.y < to.y
            let prefix = "moved \(isAscending ? "up" : "down") stairs to "
            return prefix + coordinate.description
            
        case .teleport(_, let end):
            let coordinate = Coordinate(end)
            
            let prefix = "moved forward into portal, ended up at "
            return prefix + coordinate.description
            
        case .place(let nodes):
            guard !nodes.isEmpty else { return "" }
            return "placed node at" + Coordinate(nodes[0].position).description
            
        case .control(_, let movingUp):
            return "turn lock to move platforms \(movingUp ? "up" : "down")"
            
        case .remove(let nodes):
            guard !nodes.isEmpty else { return "" }
            return "picked up item at" + Coordinate(nodes[0].position).description
            
        case let .toggleSwitch(coordinate, on):
            return "toggled switch \(on ? "open" : "closed") at" + coordinate.description
            
        case .turn(_, let rads, let clkwise):
            let turnDirection = clkwise ? "Right" : "Left"
            let facingDirection = Direction(radians: rads).rawValue
            return "turned" + turnDirection + ", now facing " + facingDirection
            
        case .incorrectPickUp:
            return "tried to pick up, no item found"
            
        case .incorrectToggleSwitch:
            return "tried to toggle switch, but no switch was present"
            
        case .incorrectIntoWall:
            return "failed to move forward, hit wall"
            
        case .incorrectOffEdge:
            return "failed to move forward, almost fell off edge"
        }
    }
}
