// 
//  Wall.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public final class Wall: WorldNode, LocationConstructible, NodeConstructible {
    // MARK: Static
    
    static var template: SCNNode = {
        let url = Bundle.main().urlForResource(WorldConfiguration.propsDir + "zon_prop_fence_pebble_b", withExtension: "dae")!
        
        let scene = try! SCNScene(url: url, options: nil)
        let node = scene.rootNode.childNodes[0]
        
        // Adjust the node's piviot point so that the wall sits in the center of the node.
        let pivotNode = SCNNode()
        node.position.x += WorldConfiguration.coordinateLength / 2
        pivotNode.addChildNode(node)
        
        return pivotNode //.flattenedClone()
    }()
    
    // MARK: 
    
    let edges: Edge
    
    public convenience init() {
        self.init(edges: .top)
    }
    
    public init(edges: Edge) {
        self.edges = edges
        super.init(identifier: .wall)
        
        addWallNodes(for: edges)
    }
    
    override init?(node: SCNNode) {
        guard node.identifier == .wall else { return nil }
        
        // Maps the old wall format (based on rotation and offset) to the new edge based format.
        // π offset to make edge correctly align with node after rotation.
        let direction = Direction(radians: node.eulerAngles.y + π)
        switch direction {
        case .north, .south:
            let offset = node.position.x.truncatingRemainder(dividingBy: 1)
            edges = abs(offset) < 0.5 ? .top : .bottom
            
        case .east, .west:
            let offset = node.position.z.truncatingRemainder(dividingBy: 1)
            edges = abs(offset) < 0.5 ? .left : .right
        }

        super.init(node: node)
    }
    
    func addWallNodes(for edge: Edge) {
        let template = Wall.template
        let offset = WorldConfiguration.coordinateLength / 2 - 0.01
        
        if edge.contains(.top) {
            let top = template.clone()
            top.position.z += -offset
            top.eulerAngles.y = SCNFloat(M_PI_2)
            node.addChildNode(top)
        }
        
        if edge.contains(.bottom) {
            let bottom = template.clone()
            bottom.position.z += offset
            bottom.eulerAngles.y = SCNFloat(M_PI_2)
            node.addChildNode(bottom)
        }
        
        if edge.contains(.left) {
            let left = template.clone()
            left.position.x += -offset
            left.eulerAngles.y = 0
            node.addChildNode(left)
        }
        
        if edge.contains(.right) {
            let right = template.clone()
            right.position.x += offset
            right.eulerAngles.y = 0
            node.addChildNode(right)
        }
    }
    
    // MARK: 
    
    public func blocksMovement(from start: Coordinate, to end: Coordinate) -> Bool {
        let translationDirection = Direction(from: start, to: end)
        let direction: Direction = coordinate == start ? translationDirection : Direction(radians: translationDirection.radians + π) // Opposite direction
        
        // Account for base node rotation. 
        let rotatedDirection = Direction(radians: direction.radians + rotation)
        
        switch rotatedDirection {
        case .north: return edges.contains(.top)
        case .south: return edges.contains(.bottom)
        case .east: return edges.contains(.right)
        case .west: return edges.contains(.left)
        }
    }
}
