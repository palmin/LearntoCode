// 
//  Platform.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public final class Platform: WorldNode, NodeConstructible {
    // MARK: Static
    
    static var template: SCNNode = {
        let url = Bundle.main().urlForResource(WorldConfiguration.platformDir + "zon_prop_platform_a", withExtension: "dae")!
        
        let scene = try! SCNScene(url: url, options: nil)
        let node = scene.rootNode.childNodes[0]
        // Offset in container. 0.005 less than the levelHeight to avoid z-fighting when in water.
        node.position.y = -(WorldConfiguration.levelHeight - 0.005)
        
        return node
    }()
    
    private var glyphNode: SCNNode? {
        return node.childNode(withName: "zon_prop_platformSign_a_GEO", recursively: true)
    }
    
    private lazy var glyphMaterial: SCNMaterial? = {
        // Create a copy of the underlying material.
        let geoCopy = self.glyphNode?.createUniqueFirstGeometry()
        let materialCopy = geoCopy?.firstMaterial?.copy() as? SCNMaterial
        geoCopy?.firstMaterial = materialCopy
        self.glyphNode?.geometry = geoCopy
        
        return self.glyphNode?.firstGeometry?.firstMaterial
    }()
    
    override var isStackable: Bool {
        return true
    }
    
    override var verticalOffset: SCNFloat {
        return SCNFloat(startingLevel - 1) * WorldConfiguration.levelHeight
    }
    
    // MARK: Properties
    
    // Not public. Color can only be modified on the lock.
    var color = Color.yellow {
        didSet {
           setColor()
        }
    }
    
    var startingLevel: Int
    public weak var lock: PlatformLock? = nil {
        didSet {
            // Configure the reverse connection.
            lock?.platforms.insert(self)
        }
    }
    
    public init(onLevel level: Int = 0, controlledBy lock: PlatformLock) {
        self.startingLevel = level
        self.lock = lock
        
        super.init(identifier: .platform)
        
        // Configure the reverse connection.
        lock.platforms.insert(self)

        let child = Platform.template.clone()
        node.addChildNode(child)
        
        // Grab color from lock. 
        self.color = lock.color
        setColor()
    }
    
    override init?(node: SCNNode) {
        guard node.identifier == .platform else { return nil }
        self.startingLevel = Int(round(node.position.y / WorldConfiguration.levelHeight))
        
        super.init(node: node)
    }
    
    // MARK: Methods
    
    func setColor() {
        glyphMaterial?.diffuse.contents = color.rawValue
        
        // Remove shadows for children.
        glyphNode?.castsShadow = false
    }
}
