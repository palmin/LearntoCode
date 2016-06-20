// 
//  PlatformLock.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public final class PlatformLock: WorldNode, NodeConstructible {
    // MARK: Static
    
    static var template: SCNNode = {
        let url = Bundle.main().urlForResource(WorldConfiguration.resourcesDir + "Lock/NeutralPose", withExtension: "dae")!
        
        let scene = try! SCNScene(url: url, options: nil)
        let node = scene.rootNode.childNodes[0]
        
        return node
    }()
    
    // MARK: Private
    
    private var glyphMaterial: SCNMaterial? {
        return node.childNode(withName: "lockAlpha_0001", recursively: true)?.firstGeometry?.firstMaterial
    }
    
    // MARK: Properties
    
    public var color: Color {
        didSet {
            setColor()
        }
    }
    
    var platforms = Set<Platform>()
    
    /// 0-4
    public var platformIndex = 0 {
        didSet {
            platformIndex = platformIndex.clamp(min: 0, max: 4)
        }
    }
    
    public init(color: Color = .yellow) {
        self.color = color

        super.init(identifier: .platformLock)
        
        loadGeometry()
        setColor()
    }
    
    override init?(node: SCNNode) {
        guard node.identifier == .platformLock else { return nil }
        self.color = .yellow
        super.init(node: node)
    }
    
    // MARK: 
    
    public func raisePlatforms() {
        guard let world = world else { return }

        for platform in platforms {
            platform.position.y += WorldConfiguration.levelHeight
            
            world.percolateNodes(at: platform.coordinate)
        }
    }
    
    public func lowerPlatforms() {
        guard let world = world else { return }

        for platform in platforms {
            platform.position.y -= WorldConfiguration.levelHeight
            
            world.percolateNodes(at: platform.coordinate)
        }
    }
    
    func setColor() {
        glyphMaterial?.diffuse.contents = color.rawValue
        
        for platform in platforms {
            platform.color = color
        }
    }
    
    func loadGeometry() {
        let url = Bundle.main().urlForResource(WorldConfiguration.lockDir + "NeutralPose", withExtension: "dae")!
        
        let scene = try! SCNScene(url: url, options: nil)
        let child = scene.rootNode.childNodes[0]
        node.addChildNode(child)
    }
}
