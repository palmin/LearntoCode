// 
//  Scene.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import SceneKit

@objc protocol BitmaskForFloorReflection {
    func reflectionCategoryBitMask() -> UInt
    func setReflectionCategoryBitMask(_ value: UInt)
}

extension NSObject: BitmaskForFloorReflection {
    func reflectionCategoryBitMask() -> UInt {
        log(message: "Should not reach this code")
        return 0
    }
    
    func setReflectionCategoryBitMask(_ value: UInt) {
        log(message: "Should not reach this code")
    }
}

/// Reports changes to the worlds state.
protocol SceneStateDelegate: class {
    func scene(_ scene: Scene, didEnterState: Scene.State)
}

// Notifications mainly used by _AssessmentUtilities.swift.
public let GridWorldStateDidChangeNotification = "GridWorldStateDidChange"
public let GridWorldDidUpdateDiffNotification = "GridWorldDidUpdateDiff"

public final class Scene: NSObject, SCNSceneRendererDelegate {
    
    enum State {
        case initial
        case built
        case ready
        case run
        case done
    }
    
    private let source: SCNSceneSource

    let gridWorld: GridWorld
    
    /// The queue which all commands are added to before being run.
    
    public var commandQueue: CommandQueue {
        return gridWorld.commandQueue
    }
    
    lazy var scnScene: SCNScene = {
        let scene: SCNScene
        do {
            scene = try self.source.scene(options: nil)
        }
        catch {
            presentAlert(title: "Failed To Load Scene.", message: "\(error)")
            fatalError("Failed To Load Scene.\n\(error)")
        }
        
        // Remove the old grid node that exists in loaded scenes. 
        scene.rootNode.childNode(withName: GridNodeName, recursively: false)?.removeFromParentNode()
        scene.rootNode.addChildNode(self.gridWorld.grid.node)
        
        // Give the `rootNode` a name for easy lookup.
        scene.rootNode.name = "rootNode"
        
        // Load the skybox. 
        let skyBoxPath = WorldConfiguration.texturesDir + "zon_bg_skyBox_a_DIFF"
        scene.background.contents = Bundle.main().urlForResource(skyBoxPath, withExtension: "png") as? AnyObject
        
        
//        self.positionCameraToFitGrid()
//        self.adjustDirectionalLight()
        self.cleanupScene(scene)
        
        
        scene.rootNode.childNode(withName: "Templates", recursively: false)?.removeFromParentNode()
        return scene
    }()
    
    var rootNode: SCNNode {
        return scnScene.rootNode
    }
    
    weak var delegate: SceneStateDelegate?
    
    ///  Actors operating within this scene.
    var actors: [Actor] {
        return gridWorld.grid.actors
    }
    
    var mainActor: Actor? {
        return actors.first
    }
    
    /// If `true` the diff will display red tiles when complete.
    public var shouldDisplayIncorrectDiffResults = true
    
    /// Marks if the scene was loaded as a "Dressed Worlds".
    let sceneWasUnarchived: Bool
    
    var resetDuration: TimeInterval = 0.0
    
    internal(set) var state: State = .initial {
        didSet {
            switch state {
            case .built:
                // Never animate `built` steps.
                gridWorld.applyChanges() {
                    gridWorld.verifyNodePositions()
                    
                    // Add block geometry if the scene was built.
                    if !sceneWasUnarchived {
                        gridWorld.buildPatteredBlockStacks()
                    }
                }
                
            case .ready:
                for actor in actors {
                    guard let animationComponent = actor.componentForType(AnimationComponent.self) else { continue }
                    animationComponent.runDefaultAnimationIndefinitely()
                }
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = resetDuration
                // Reset the state of the world for playback.
                commandQueue.reset()
                SCNTransaction.commit()
                
                // Remove quads between blocks.
                gridWorld.removeHiddenQuads()
                gridWorld.calculateRowColumnCount()
                
            case .run:
                // Add a slight delay before running the first command.
                dispatch_after(seconds: WorldConfiguration.Scene.actorPause) { [unowned self] in
                    // Ensure that we still intend to run the scene.
                    guard self.state == .run else { return }
                    
                    self.commandQueue.runMode = .continuous
                    self.commandQueue.runCommand(atIndex: 0)
                }
                
            case .done:
                // Recalculate the dimensions of the world for any placed items. 
                gridWorld.calculateRowColumnCount()
                
            default:
                break
            }
            
            delegate?.scene(self, didEnterState: state)
            NotificationCenter.default().post(name: Notification.Name(rawValue: GridWorldStateDidChangeNotification), object: self)
        }
    }
    
    // MARK: Initialization
    
    public init(world: GridWorld) {
        sceneWasUnarchived = false
        gridWorld = world
        
        // Load template scene.
        let worldTemplatePath = WorldConfiguration.customDir + "WorldTemplate"
        let worldURL = Bundle.main().urlForResource(worldTemplatePath, withExtension: "scn")!
        source = SCNSceneSource(url: worldURL, options: nil)!
    }
    
    public init(source: SCNSceneSource) throws {
        sceneWasUnarchived = true
        self.source = source
        
        // Check for `GridNodeName` node.
        guard let baseGridNode = source.entry(withID: GridNodeName, ofType: SCNNode.self) else {
            throw GridLoadingError.missingGridNode(GridNodeName)
        }

        let grid = GridNode(node: baseGridNode)
        gridWorld = GridWorld(node: grid)
        
        super.init()
        
        // Ensure at least one tile node is contained in the scene as the floor node.
        guard !gridWorld.existingNodes(ofType: Block.self, at: gridWorld.allPossibleCoordinates).isEmpty else {
            throw GridLoadingError.missingFloor("No nodes of with name `Block` were found.")
        }
        
        let cols = gridWorld.columnCount
        let rows = gridWorld.rowCount
        guard cols > 0 && rows > 0 else { throw GridLoadingError.invalidDimensions(cols, rows) }

        }
    
    /// Expects an ".scn" scene.
    public convenience init(named sceneName: String) throws {
        let path = WorldConfiguration.resourcesDir + "_Scenes/" + sceneName
    
        guard
            let sceneURL = Bundle.main().urlForResource(path, withExtension: "scn"),
            let source = SCNSceneSource(url: sceneURL, options: nil) else {
                throw GridLoadingError.invalidSceneName(sceneName)
        }
        
        try self.init(source: source)
    }
    
    func adjustDirectionalLight() {
        guard let light = scnScene.rootNode.childNode(withName: DirectionalLightName, recursively: true)?.light else { return }
        
        
        light.shadowSampleCount = 4
        light.shadowMapSize = CGSize(width:  2048, height:  2048) //CGSize(width:  1024, height:  1024)
                
        var childNodes = Set(rootNode.childNodes)
        childNodes.subtract([gridWorld.grid.node])
        for node in childNodes {
            node.enumerateChildNodes { child, _ in
                child.castsShadow = false
            }
        }
    }
    
    func positionCameraToFitGrid() {
        // Set up the camera.
        let cameraNode = rootNode.childNode(withName: "camera", recursively: true)!
        if let gridRootNode = rootNode.childNode(withName: "Scenery", recursively: true)?.childNode(withName: "base", recursively: true) {
            var center = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
            var sceneWidth = CGFloat(0.0)
            gridRootNode.getBoundingSphereCenter(&center, radius: &sceneWidth)
            sceneWidth *= 2.5 // expand to 300% so we make sure to get the whole thing with a bit of overlap
            // set original FOV, camera FOV and current FOV
            
            let cameraDistance = Double(cameraNode.position.z)
            let halfSceneWidth = Double(sceneWidth / 2.0)
            let distanceToEdge = sqrt(cameraDistance * cameraDistance + halfSceneWidth * halfSceneWidth)
            let cos = cameraDistance / distanceToEdge
            let sin = halfSceneWidth / distanceToEdge
            let halfAngle = atan2(sin, cos)
            
            cameraNode.camera?.yFov = 2.0 * halfAngle * 180.0 / M_PI
            
        } else {
            let dominateDimension = SCNFloat(max(gridWorld.rowCount, gridWorld.columnCount))
            // Formula calculated from linear regression of 7 maps.
            cameraNode.position.z = 3.8488 * dominateDimension - 9.5
        }
    }
    
    /// Removes unnecessary adornments in scene file.
    func cleanupScene(_ scene: SCNScene) {
        let root = scene.rootNode
        
        let bokeh = root.childNode(withName: "bokeh particles", recursively: true)
        bokeh?.removeFromParentNode()
        
        let reflectionPlane = root.childNode(withName: "reflections", recursively: true)
        reflectionPlane?.removeFromParentNode()
        
        let reflectionGeo = reflectionPlane?.geometry
        reflectionGeo?.setReflectionCategoryBitMask(UInt(WorldConfiguration.reflectsBitMask))
        
        let smokeParticles = root.childNodes { node, _ in
            return node.name == "p_smoke_small"
        }
        
        for particle in smokeParticles {
            particle.categoryBitMask &= ~WorldConfiguration.reflectsBitMask
        }
    }
    
    // MARK: SCNSceneRendererDelegate
    
    /// Called before each frame is rendered.
    public func renderer(_: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateAtTime(time: time)
    }
    
    // Stubbed out for testing (Can't create a raw `SCNSceneRenderer`).
    func updateAtTime(time: TimeInterval) {
        guard state == .run else { return }
        
        // Poll to see if the `commandQueue` has pending commands to run.
        if commandQueue.isFinished {
            DispatchQueue.main.asynchronously {
                self.state = .done
            }
        }
    }
}
