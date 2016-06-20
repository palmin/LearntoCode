// 
//  Gem.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public final class Gem: WorldNode, LocationConstructible, NodeConstructible {
    
    // MARK: Static
    
    static let moveUpKey = "MoveGem-Up"
    static let moveDownKey = "MoveGem-Down"
    static let spinKey = "Spin"
    
    static var template: SCNNode = {
        let gemPath = WorldConfiguration.gemDir + "NeutralPose"
        let url = Bundle.main().urlForResource(gemPath, withExtension: "scn")!
        
        let scene = try! SCNScene(url: url, options: nil)
        let node = scene.rootNode.childNodes[0]
    
        // Remove the existing spin animation to add our own (random offset).
        node.removeAllAnimations()
        
        return node
    }()
    
    static var popEmitter: SCNNode = {
        let popAnimationPath = WorldConfiguration.gemDir + "PopAnimation"
        let url = Bundle.main().urlForResource(popAnimationPath, withExtension: "scn")!
        
        let scene = try! SCNScene(url: url, options: nil)
        let node = scene.rootNode.childNodes[0]
        node.position.y += 0.2
        
        return node
    }()
    
    // MARK: Initialization
    
    public init() {
        super.init(identifier: .item)
        
        let gem = Gem.template.clone()
        node.addChildNode(gem)

        node.add(.spinAnimation(), forKey: Gem.spinKey)
    }
    
    override init?(node: SCNNode) {
        guard node.identifier == .item else { return nil }
        super.init(node: node)
        
        node.add(.spinAnimation(), forKey: Gem.spinKey)
    }
    
    /// Animates the removal of the gem from the world.
    func collect(withDuration animationDuration: TimeInterval) {
        guard isInWorld else {
            log(message: "Attempting to collect a gem \(self) which is not in a world.")
            return
        }
        
        // Remove the gem from the world immediately.
        world = nil
        
        let halfDuration = animationDuration / 2
        let wait = SCNAction.wait(forDuration: halfDuration)
        let scale = SCNAction.scale(to: 0.0, duration: halfDuration / 2)
        let wait2 = SCNAction.wait(forDuration: halfDuration / 2)

        let emitterNode = Gem.popEmitter
        let emitterDuration = CGFloat(halfDuration)

        let system = emitterNode.particleSystems![0]
        system.emissionDuration = emitterDuration
        system.birthRate = emitterDuration
        system.particleLifeSpan = emitterDuration
        
        node.addChildNode(emitterNode)

        guard let innerGeo = node.childNodes.first else {
            log(message: "Failed to find inner geo for gem: \(self).")
            return
        }
        
        innerGeo.run(.sequence([wait, scale, wait2])) { [unowned self] _ in
            self.node.removeFromParentNode()
            
            // Restore the node.
            emitterNode.removeFromParentNode()
            innerGeo.scale = SCNVector3Make(1, 1, 1)
        }
    }
    
    func move(up: Bool, withDuration duration: TimeInterval) {
        guard let world = world else { return }
        let key = up ? Gem.moveUpKey : Gem.moveDownKey

        // Ensure starting position of the gem is correct.
        let height = world.height(at: coordinate)
        let startHeight = up ? height : height + WorldConfiguration.gemDisplacement
        let endHeight = up ? height + WorldConfiguration.gemDisplacement : height
        
        guard !duration.isLessThanOrEqualTo(0.0) else {
            // If the `duration` is <= 0, move the gem immediately and remove existing animations.
            node.removeAnimation(forKey: Gem.moveUpKey)
            node.removeAnimation(forKey: Gem.moveDownKey)
            position.y = endHeight
            return
        }
        
        let move = CABasicAnimation(keyPath: "position.y")
        move.isRemovedOnCompletion = false
        move.fillMode = kCAFillModeForwards
        
        move.duration = duration
        move.fromValue = startHeight as AnyObject
        move.toValue = endHeight as AnyObject
        
        let offsetFactor = up ? 0 : CACurrentMediaTime() + duration / 6
        move.beginTime = offsetFactor
        
        let timingFunction = up ? kCAMediaTimingFunctionEaseOut : kCAMediaTimingFunctionEaseIn
        move.timingFunction = CAMediaTimingFunction(name: timingFunction)
        
        node.add(move, forKey: key)
    }
    
    // MARK: Animations
    
    override func placeAction(withDuration duration: TimeInterval) -> SCNAction {
        node.scale = SCNVector3Zero
        node.opacity = 0.0
        
        return .group([.scale(to: 1.0, duration: duration), .fadeIn(withDuration: duration)])
    }
}
