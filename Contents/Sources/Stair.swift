// 
//  Stair.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public final class Stair: WorldNode, LocationConstructible, NodeConstructible {
    // MARK: Static
    
    static var template: SCNNode = {
        let url = Bundle.main().urlForResource(WorldConfiguration.resourcesDir + "blocks/zon_stairs_a_half", withExtension: "dae")!
        
        let scene = try! SCNScene(url: url, options: nil)
        let node = scene.rootNode.childNodes[0]
        node.position.y = -WorldConfiguration.levelHeight
        return node
    }()
    
    override var isStackable: Bool {
        return true
    }
    
    override var verticalOffset: SCNFloat {
        return WorldConfiguration.levelHeight
    }
    
    public init() {
        super.init(identifier: .stair)
    
        node.addChildNode(Stair.template.clone())
    }
    
    override init?(node: SCNNode) {
        guard node.identifier == .stair else { return nil }
        super.init(node: node)
    }
}
