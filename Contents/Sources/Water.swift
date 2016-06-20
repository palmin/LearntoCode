// 
//  Water.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import SceneKit

public final class Water: WorldNode, LocationConstructible, NodeConstructible {
    // MARK: Static
    
    static var template: SCNNode = {
        let url = Bundle.main().urlForResource(WorldConfiguration.resourcesDir + "barrier/zon_barrier_water_1x1", withExtension: "scn")!
        
        let scene = try! SCNScene(url: url, options: nil)
        let node = scene.rootNode.childNodes[0]
        node.name = WorldNodeIdentifier.water.rawValue
        //        node.position.y = -WorldConfiguration.levelHeight
        return node
    }()
    
    override var isStackable: Bool {
        return true
    }
    
    public init() {
        super.init(node: Water.template.clone())!
    }
    
    override init?(node: SCNNode) {
        // Support maps exported with blocks named "Obstacle".
        guard node.identifier == .water
            || node.identifierComponents.first == "Obstacle" else { return nil }
        
        super.init(node: node)
    }
    
    //    override func placeAction(withDuration duration: NSTimeInterval) -> SCNAction {
    //        node.position.y += 5
    //        return .moveBy(x: 0, y: -5, z: 0, duration: duration)
    //    }
}
