// 
//  NodeFactory.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit
import PlaygroundSupport

struct NodeFactory {
    static let worldNodeTypes: [NodeConstructible.Type] = [
        Block.self, Water.self, Stair.self,
        Wall.self, Portal.self, StartMarker.self,
        Gem.self, Switch.self, Actor.self,
        PlatformLock.self, Platform.self,
        RandomNode.self
    ]
    
    static func make(from node: SCNNode) -> WorldNode? {
        for nodeType in worldNodeTypes {
            if let worldNode = nodeType.init(node: node) as? WorldNode {
                return worldNode
            }
        }
        return nil
    }
    
    static func make(from message: PlaygroundValue, within world: GridWorld) -> WorldNode? {
        guard case let .array(args) = message where args.count > 3 else { return nil }
        guard case let .string(id) = args[0], let identifier = WorldNodeIdentifier(rawValue: id),
            case let .integer(index) = args[1],
            let position = SCNVector3(message: args[2]),
            let rotation = SCNFloat(message: args[3])
            else {
                log(message: "Failed to find the necessary info to reconstruct a WorldNode from: \(message).")
                return nil
        }
        
        /// Search for an exiting node with that identifier.
        let searchCoordinate = Coordinate(position)
        let grid = world.grid
        
        var possibleNode: WorldNode?

        for existingNode in grid.nodes(at: searchCoordinate) where existingNode.worldIndex == index {
            assert(existingNode.identifier == identifier, "\(existingNode), \(identifier) \(index)")
            possibleNode = existingNode
        }
        
        if possibleNode == nil {
            // If the node is not in the world, it's possible it's yet to be added. Check the command queue. 
            let queueNodes = world.commandQueue.pendingCommands.reduce([WorldNode]()) { nodesToBePlaced, performer in
                if case let .place(nodes) = performer.command {
                    return nodesToBePlaced + nodes
                }
                return nodesToBePlaced
            }
            
            for node in queueNodes where node.worldIndex == index {
                assert(node.identifier == identifier, "\(node), \(identifier) \(index)")
                possibleNode = node
            }
        }
        
        if possibleNode == nil {
            // If no existing nodes could be found, try to create one.
            let stateInfo: [PlaygroundValue] = args.count > 4 ? Array(args.suffix(from: 4)) : []
            possibleNode = make(with: identifier, from: stateInfo)
        }
        
        guard let node = possibleNode else {
            log(message: "Failed to find find or create a WorldNode from: \(message).")
            return nil
        }
        
        // Set the `id` explicitly so that this world is synchronized with the user process.
        node.worldIndex = index
        node.rotation = rotation
        node.position = position
        
        node.world = world

        return node
    }
    
    static func make(with identifier: WorldNodeIdentifier, from stateInfo: [PlaygroundValue]) -> WorldNode? {
        let node: WorldNode
        
        switch identifier {
        case .block:
            node = Block()
            
        case .stair:
            node = Stair()
            
        case .wall:
            guard case let .integer(edges)? = stateInfo.first else { return nil }
            node = Wall(edges: Edge(rawValue: UInt(edges)))
            
        case .water:
            node = Water()
            
        case .item:
            node = Gem()
            
        case .switch:
            guard case let .boolean(on)? = stateInfo.first else { return nil }
            let s = Switch()
            s.isOn = on
            node = s
            
        case .portal:
            guard case let .boolean(on)? = stateInfo.first,
                case let .data(colorData)? = stateInfo.last,
                let color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? _Color
                else { return nil }
            
            let portal = Portal(color: Color(color))
            portal.isActive = on
            node = portal
            
        case .platformLock:
            
            return nil
            
        case .platform:
            
            return nil
            
        case .randomNode:
            
            return nil
            
        case .startMarker:
            guard case let .string(typeId)? = stateInfo.first,
                let type = ActorType(rawValue: typeId) else { return nil }
            
            node = StartMarker(type: type)
            
        case .actor:
            guard case let .string(typeId)? = stateInfo.first else { return nil }
            
            if let name = CharacterName(rawValue: typeId) {
                node = Actor(name: name)
            }
            else {
                node = Expert()
            }
        }
        
        return node
    }
}
