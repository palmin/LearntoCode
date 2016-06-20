// 
//  WorldNodes.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit
import PlaygroundSupport

/// A type which can be expressed with just a location and rotation upon placement.
public protocol LocationConstructible {
    init()
}

protocol NodeConstructible {
    init?(node: SCNNode)
}

protocol Animatable {
    /// Each `WorldNode` describes it's own actions.
    func placeAction(withDuration duration: TimeInterval) -> SCNAction
    func removeAction(withDuration duration: TimeInterval) -> SCNAction
}

public class WorldNode: Animatable, MessageConstructor {
    weak var world: GridWorld? = nil

    let identifier: WorldNodeIdentifier
    let node: SCNNode
    
    var isStackable: Bool {
        return false
    }
    
    var verticalOffset: SCNFloat {
        return 0
    }
    
    var position: SCNVector3 {
        get {
            return node.position
        }
        set {
            node.position = newValue
        }
    }
    
    /// Manually calculate the rotation to ensure `w` component is correctly calculated.
    var rotation: SCNFloat {
        get {
            
            return node.rotation.y * node.rotation.w
        }
        set {
            node.rotation = SCNVector4(0, 1, 0, newValue)
        }
    }
    
    public var heading: Direction {
        return Direction(radians: rotation)
    }
    
    public var coordinate: Coordinate {
        return Coordinate(node.position)
    }
    
    public var level: Int {
        return Int(round(position.y / WorldConfiguration.levelHeight))
    }
    
    /// If the node has been added to a `GridWorld` the node will be
    /// suffixed with a unique index. This index is used to encode nodes when
    /// sending and receiving commands.
    var worldIndex = -1
    
    var isInWorld: Bool {
        return world != nil && node.parent != nil
    }
    
    init(identifier: WorldNodeIdentifier) {
        self.identifier = identifier
        node = SCNNode()
        node.name = identifier.rawValue
    }

    init?(node: SCNNode) {
        guard let identifier = node.identifier else { return nil }
        self.identifier = identifier
        self.node = node
    }

    public func removeFromWorld() {
        world?.remove(self)
    }
    
    // MARK: Animatable
    
    /// Restore animatable state of the SCNNode.
    func reset() {
        node.opacity = 1.0
        node.scale = SCNVector3(x: 1, y: 1, z: 1)
    }
    
    func placeAction(withDuration duration: TimeInterval) -> SCNAction {
        node.opacity = 0.0
        return .fadeIn(withDuration: duration)
    }
    
    func removeAction(withDuration duration: TimeInterval) -> SCNAction {
        return .fadeOut(withDuration: duration)
    }
    
    // MARK: MessageConstructor
    
    /*
     [
     <WorldNodeIdentifier>,
     <WorldIndex>,
     <Position>,
     <Rotation>,
     <stateInfo>
     ]
     */
    var message: PlaygroundValue {
        return .array([
            .string(identifier.rawValue),
            .integer(worldIndex),
            position.message,
            rotation.message,
            stateInfo
            ])
    }
    
    var stateInfo: PlaygroundValue {
        // WorldNode requires no additional info.
        return .string("")
    }
}

extension WorldNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        let coordinateDescription = " at: " + coordinate.description
        let suffix = world == nil ? " (not in world)" : ""
        return "<\(worldIndex)> " + (node.name ?? "") + coordinateDescription + suffix
    }
}

extension WorldNode: Hashable {
    public var hashValue: Int {
        return node.hashValue
    }
}

public func ==(lhs: WorldNode, rhs: WorldNode) -> Bool {
    return lhs.node == rhs.node
}
