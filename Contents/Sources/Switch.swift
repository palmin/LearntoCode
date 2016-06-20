// 
//  Switch.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit
import PlaygroundSupport

public final class Switch: WorldNode, LocationConstructible, NodeConstructible {
    // MARK: Static

    static let turnOnAnimation: CAAnimation = {
        let animation = loadAnimation(WorldConfiguration.switchDir + "SwitchOn")!
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        
        return animation
    }()
    
    static let turnOffAnimation: CAAnimation = {
        let animation = loadAnimation(WorldConfiguration.switchDir + "SwitchOff")!
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        
        return animation
    }()
    
    private var animationSpeed: Float {
        // 1000 so that the state change does not appear animated, but we need the correct NeutralPose.
        return world?.isAnimated == true ? world!.commandSpeed : 1000
    }
    
    public var isOn = false {
        didSet {
            guard isOn != oldValue else { return }
            
            if isOn {
                let animation = Switch.turnOnAnimation
                animation.speed = animationSpeed
                animationNode.add(animation, forKey: onKey)
            }
            else {
                let animation = Switch.turnOffAnimation
                animation.speed = animationSpeed
                animationNode.add(animation, forKey: offKey)
            }
        }
    }
    
    private let onKey = "Switch-On"
    private let offKey = "Switch-Off"
    
    private var animationNode: SCNNode {
        return node.childNode(withName: "CHARACTER_Switch", recursively: true) ?? node
    }
    
    public init() {
        super.init(identifier: .switch)
        
        loadGeometry()
    }
    
    override init?(node: SCNNode) {
        guard let identifier = node.identifier where identifier == .switch else { return nil }
        super.init(node: node)
    }
    
    func toggle() {
        isOn = !isOn
    }
    
    func loadGeometry() {
        let switchURL = Bundle.main().urlForResource(WorldConfiguration.switchDir + "NeutralPose", withExtension: "dae")!
        
        guard let scene = try? SCNScene(url: switchURL, options: nil) else { return }
        let firstChild = scene.rootNode.childNodes[0]
        firstChild.position.y = 0.02
        node.addChildNode(firstChild)
    }
    
    // MARK: MessageConstructor
    
    override var stateInfo: PlaygroundValue {
        return .boolean(isOn)
    }
}
