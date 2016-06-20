// 
//  StartMarker.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public final class StartMarker: WorldNode, NodeConstructible {
    
    // MARK: Static
    
    static var template: SCNNode = {
        let url = Bundle.main().urlForResource(WorldConfiguration.propsDir + "zon_prop_startTile_c", withExtension: "dae")!
        
        let scene = try! SCNScene(url: url, options: nil)
        let node = scene.rootNode.childNodes[0]
        node.name = WorldNodeIdentifier.startMarker.rawValue
        return node
    }()
    
    override var verticalOffset: SCNFloat {
        return 0.01 // Slight offset to avoid z-fighting.
    }
    
    let type: ActorType
    
    init(type: ActorType) {
        self.type = type
        super.init(node: StartMarker.template.clone())!
    }
    
    override init?(node: SCNNode) {
        guard node.identifier == .startMarker
            && node.identifierComponents.count >= 2 else { return nil }
        guard let type = ActorType(rawValue: node.identifierComponents[1]) else { return nil }
        
        self.type = type
        
        super.init(node: node)
    }
}
