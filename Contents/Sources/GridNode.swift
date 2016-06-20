// 
//  GridNode.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

extension GridWorld {
    
    /// Only exposing this method to ensure the world is set and the
    /// node is added to the scene graph
    /// when placing a node.
    func add(_ worldNode: WorldNode) {
        // Reset the node when it's added to the world.
        worldNode.reset()

        worldNode.world = self
        grid.addNode(worldNode)
    }
    
    func remove(_ worldNode: WorldNode) {
        worldNode.world = nil
        worldNode.node.removeFromParentNode()
    }
}

class GridNode {
    
    let node: SCNNode
    
    private var nodesForCoordinate = [Coordinate: [WorldNode]]()
    
    /// The index appended to every node when it is added to the world.
    /// 0 is reserved for the GridNode.
    private var runningNodeIndex = 1
    
    /// A special coordinate which groups nodes that move between coordinates (actors for now).
    private let dynamicCoordinate = Coordinate(column: -1, row: -1)
    
    var allNodes: [WorldNode] {
        var ns: [WorldNode] = []
        for (_, nodes) in nodesForCoordinate {
            ns += nodes
        }
        return ns
    }
    
    var actors: [Actor] {
        let dynamicNodes = nodesForCoordinate[dynamicCoordinate] ?? []
        
        return dynamicNodes.flatMap { node in
            if let actor = node as? Actor where node.isInWorld {
                return actor
            }
            return nil
        }
    }
    
    init(node: SCNNode) {
        self.node = node
        node.name = GridNodeName
        
        // Ensure the node is not hidden.
        node.isHidden = false
        
        // Map the node's children to `WorldNode`s.
        for child in node.childNodes {
            guard let worldNode = NodeFactory.make(from: child) else {
                log(message: "Non-game node `\(child.name ?? "")` found in GridNode.")
                continue
            }
            addNode(worldNode)
        }
    }
    
    init() {
        self.node = SCNNode()
        node.name = GridNodeName
    }
    
    func nodes(at coordinate: Coordinate) -> [WorldNode] {
        let nodes = nodesInWorld(at: coordinate)
        
        // Lazy removal of nodes NOT in the world.
        nodesForCoordinate[coordinate] = nodes
        
        return nodes + dynamicNodes(at: coordinate)
    }
    
    private func dynamicNodes(at coordinate: Coordinate) -> [WorldNode] {
        let children = nodesForCoordinate[dynamicCoordinate] ?? []
        
        return children.filter {
            $0.isInWorld && $0.coordinate == coordinate
        }
    }
    
    private func addNode(_ child: WorldNode) {
        let coordinate: Coordinate
        if child is Actor {
            coordinate = dynamicCoordinate
        }
        else {
            coordinate = Coordinate(child.position)
        }
        
        // Avoid adding the nodes twice.
        let nodes = nodesForCoordinate[coordinate] ?? []
        if !nodes.contains(child) {
            nodesForCoordinate[coordinate] = nodes + [child]
        }
        
        // Check if an index has already been assigned for this node. 
        // When rolling back changes it's important to replace the node
        // rather than creating a new one.
        if child.worldIndex < 0 {
            // Add a unique index to every node in the grid.
            child.worldIndex = runningNodeIndex
            runningNodeIndex += 1
        }
        
        node.addChildNode(child.node)
    }
    
    func removeNodes(at coordinate: Coordinate) {
        for animatable in nodes(at: coordinate) {
            animatable.removeFromWorld()
        }
        nodesForCoordinate[coordinate] = []
    }
    
    // MARK:
    
    /// Returns a `GridNode` with only the game marker nodes (no geometry).
    func copyMarkerNodes() -> GridNode {
        let grid = GridNode()
        
        for (_, nodes) in nodesForCoordinate {
            for node in nodes {
                let scnNodeCopy = node.node.copy() as! SCNNode
                guard let worldNode = NodeFactory.make(from: scnNodeCopy) else { continue }
                grid.addNode(worldNode)
            }
        }
        
        return grid
    }
    
    // MARK: 
    
    /// Returns only the STATIC nodes contained in the world at the specified coordinate.
    private func nodesInWorld(at coordinate: Coordinate) -> [WorldNode] {
        var children = nodesForCoordinate[coordinate] ?? []

        let allNodes = children
        for worldNode in allNodes where !worldNode.isInWorld {
            let index = children.index(of: worldNode)!
            children.remove(at: index)
        }
        
        return children
    }
}
