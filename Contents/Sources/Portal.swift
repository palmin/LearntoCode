// 
//  Portal.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public final class Portal: WorldNode, NodeConstructible {
    // MARK: Static
    
    static let enterAnimation: CAAnimation = {
        return loadAnimation(WorldConfiguration.portalDir + "PortalEnter")!
    }()
    
    static let exitAnimation: CAAnimation = {
        return loadAnimation(WorldConfiguration.portalDir + "PortalExit")!
    }()
    
    // MARK: Private
    
    private let activateKey = "PortalActivation-Key"
    
    private var animationNode: SCNNode {
        return node.childNode(withName: "CHARACTER_PortalA", recursively: true) ?? node
    }
    
    private var lightNode: SCNNode? {
        return node.childNode(withName: "glowPointLight", recursively: true)
    }
    
    private var glyphMaterial: SCNMaterial? {
        return node.childNode(withName: "glyphGEO", recursively: true)?.firstGeometry?.firstMaterial
    }
    
    private var eyebrowMaterial: SCNMaterial? {
        return node.childNode(withName: "eyebrowGEO", recursively: true)?.firstGeometry?.firstMaterial
    }
    
    private var innerFlare: SCNMaterial? {
        return node.childNode(withName: "innerFlareGEO", recursively: true)?.firstGeometry?.firstMaterial
    }
    
    private var outterFlare: SCNMaterial? {
        return node.childNode(withName: "outterFlareGEO", recursively: true)?.firstGeometry?.firstMaterial
    }
    
    private var portalFlare: SCNMaterial? {
        return node.childNode(withName: "portalFlareGEO", recursively: true)?.firstGeometry?.firstMaterial
    }
    
    private var crackGlow01: SCNMaterial? {
        return node.childNode(withName: "crackGlowGEO1", recursively: true)?.firstGeometry?.firstMaterial
    }
    
    private var crackGlow02: SCNMaterial? {
        return node.childNode(withName: "crackGlowGEO2", recursively: true)?.firstGeometry?.firstMaterial
    }
    
    private var crackGlow03: SCNMaterial? {
        return node.childNode(withName: "crackGlowGEO3", recursively: true)?.firstGeometry?.firstMaterial
    }
    
    // MARK: Properties
    
    public var linkedPortal: Portal? {
        didSet {
            // Automatically set the reverse link.
            linkedPortal?.linkedPortal = self
            linkedPortal?.color = color
            
            if let coordinate = linkedPortal?.coordinate {
                node.setName(forCoordinate: coordinate)
            }
        }
    }

    public var isActive = true {
        didSet {
            linkedPortal?.isActive = isActive
        }
    }
    
    public var color: Color {
        didSet {
            setColor()
        }
    }
    
    public init(color: Color) {
        self.color = color

        let node = SCNNode()
        node.name = WorldNodeIdentifier.portal.rawValue
        super.init(node: node)!
        
        loadGeometry()
        setColor()
        
        lightNode?.light?.categoryBitMask = WorldConfiguration.characterLightBitMask
    }
    
    override init?(node: SCNNode) {
        guard node.identifier == .portal else { return nil }
        self.color = .blue

        super.init(node: node)
        
        let loadedColor = innerFlare?.emission.contents as? _Color ?? _Color.blue()
        self.color = Color(loadedColor)
    }
    
    func enter(atSpeed speed: Float = 1.0) {
        let animation = Portal.enterAnimation
        animation.speed = speed
        animationNode.add(animation, forKey: activateKey)
    }
    
    func exit(atSpeed speed: Float = 1.0) {
        let animation = Portal.exitAnimation
        animation.speed = speed
        animationNode.add(animation, forKey: activateKey)
    }
    
    // MARK: 
    
    func setColor() {
        innerFlare?.diffuse.contents = color.rawValue
        outterFlare?.diffuse.contents = color.rawValue
        portalFlare?.diffuse.contents = color.rawValue

        glyphMaterial?.diffuse.contents = color.rawValue
        eyebrowMaterial?.diffuse.contents = color.rawValue
        crackGlow01?.diffuse.contents = color.rawValue
        crackGlow02?.diffuse.contents = color.rawValue
        crackGlow03?.diffuse.contents = color.rawValue
    }
    
    func loadGeometry() {
        let switchURL = Bundle.main().urlForResource(WorldConfiguration.portalDir + "NeutralPose", withExtension: "dae")!
        
        guard let scene = try? SCNScene(url: switchURL, options: nil) else { return }
        let firstChild = scene.rootNode.childNodes[0]
        node.addChildNode(firstChild)
    }
    
    // MARK: Animation
    
    override func placeAction(withDuration duration: TimeInterval) -> SCNAction {
        node.opacity = 0.0
        let fadeIn = SCNAction.fadeIn(withDuration: duration)
        
        // Remove tops of blocks where the portal will be.
        let removeTop = SCNAction.run { [unowned self] _ in
            self.world?.removeTop(at: self.coordinate, fadeDuration: duration)
        }
        
        return .group([removeTop, fadeIn])
    }
    
    override func removeAction(withDuration duration: TimeInterval) -> SCNAction {
        
        let topBlock = world?.topBlock(at: coordinate)
        topBlock?.addTop()
        
        return .fadeOut(withDuration: duration)
    }
}
