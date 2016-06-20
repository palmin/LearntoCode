// 
//  RandomNode.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public final class RandomNode: WorldNode, NodeConstructible {
    // MARK: Static
    
    static let supportedRandomIds: [WorldNodeIdentifier] = [.block, .stair, .item, .switch]
    static let names = ["zon_prop_block_RAND", "zon_prop_stairs_RAND", "zon_prop_gem_RAND", "zon_prop_switchON_RAND", "zon_prop_switchOFF_RAND"]
    
    static var templates: [SCNNode] = {
        return names.map {
            RandomNode.template(for: $0)
        }
    }()
    
    static func template(for name: String) -> SCNNode {
        let url = Bundle.main().urlForResource(WorldConfiguration.randomElementsDir + name, withExtension: "dae")!
        let scene = try! SCNScene(url: url, options: nil)
        let node = scene.rootNode.childNodes[0]
        node.position.y = 0.01 // Slight offset to avoid z-fighting.
        return node
    }
    
    // MARK:
    
    let resemblingIdentifier: WorldNodeIdentifier
    let isResemblingStackable: Bool
    
    override var isStackable: Bool {
        
        return false // isResemblingStackable
    }
    
    // Use the offset of the node type this `RandomNode` represents.
    private let resemblingNodeOffset: SCNFloat
    override var verticalOffset: SCNFloat {
        return resemblingNodeOffset
    }
    
    public init(resembling node: WorldNode) {
        isResemblingStackable = node.isStackable
        resemblingNodeOffset = node.verticalOffset
        resemblingIdentifier = node.identifier
        
        let templateIndex: Int
        switch node.identifier {
        case .block: templateIndex = 0
        case .stair: templateIndex = 1
        case .item: templateIndex = 2
        case .switch where (node as! Switch).isOn: templateIndex = 3
        case .switch: templateIndex = 4
        default: templateIndex = -1
        }
        
        
        let template = templateIndex >= 0 ? RandomNode.templates[templateIndex] : SCNNode()
        
        super.init(identifier: .randomNode)
        template.name = WorldNodeIdentifier.randomNode.rawValue + "-" + node.identifier.rawValue
        template.position.y = -resemblingNodeOffset
        
        self.node.addChildNode(template.clone())
    }
    
    override init?(node: SCNNode) {
        guard node.identifier == .randomNode else { return nil }
        isResemblingStackable = true
        resemblingNodeOffset = 0.0
        resemblingIdentifier = .block // It doesn't matter for loaded nodes. Could be reconstructed from the name. 
        
        super.init(node: node)
    }
    
    // MARK: Animations
    
    override func removeAction(withDuration duration: TimeInterval) -> SCNAction {
        let fifthDuration = duration / 5
        
        let wait = SCNAction.wait(forDuration: fifthDuration)
        let scaleUp = SCNAction.scale(to: 1.2, duration: fifthDuration * 3)
        let scaleZer0 = SCNAction.scale(to: 0.0, duration: fifthDuration)
        
        return SCNAction.sequence([wait, scaleUp, scaleZer0])
    }
}
