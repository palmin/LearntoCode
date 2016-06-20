// 
//  WorldViewController.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import SceneKit
import UIKit

@objc(WorldViewController)
public class WorldViewController: UIViewController {
    @IBOutlet weak var speedAdjustButton: UIButton!
    
    @IBOutlet weak var posterImageView: UIImageView! {
        didSet {
            posterImageView?.image = UIImage(named: "LiveViewPoster.jpg")
        }
    }
    
    @IBOutlet var scnView: SCNView!
    
    var characterPickerController : CharacterPickerController?
    
    public var scene: Scene! {
        didSet {
            scene.delegate = self
        }
    }
    
    let loadingQueue = OperationQueue()
    var cameraController: CameraController?
    
    // End-State
    var isDisplayingEndState = false
    
//    let backgroundAudioNode = SCNAudioSource(url: Bundle.main().urlForResource("Background", withExtension: "wav", subdirectory: "Audio")!)!
    
    // MARK: Factory Initialization
    
    public class func makeController(with scene: Scene) -> WorldViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main())
        let sceneController = storyboard.instantiateViewController(withIdentifier: "WorldViewController") as! WorldViewController
        
        sceneController.scene = scene
        
        // At this point the world is fully built.
        scene.state = .built
        
        return sceneController
    }
    
    // MARK: View Controller Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.bringSubview(toFront: posterImageView)
        
        /// Loading
        loadingQueue.qualityOfService = .userInitiated
        loadingQueue.addOperation { [unowned self] in
            self.scnView.scene = self.scene.scnScene
        }
        
        /*
         Register as an `SCNRender` to receive updates.
         (Used to determine when the LiveViewPoster should be removed).
         */
        scnView?.delegate = self
        
        // Register for accessibility notifications to update view if 
        // VoiceOver status changes while level is running.
        registerForAccessibilityNotifications()
        
        speedAdjustButton.isHidden = true
        
        // Grab the device from the scene view and interrogate it.
        if let defaultDevice = scnView.device {
            if (defaultDevice.supportsFeatureSet(MTLFeatureSet.iOS_GPUFamily2_v2)) {
                scnView.antialiasingMode = .multisampling2X
            } else {
                scnView.contentScaleFactor = 1.5
                scnView.preferredFramesPerSecond = 30
            }
        } else {
            // Assume we're in GL-land 
            scnView.contentScaleFactor = 1.5
            scnView.preferredFramesPerSecond = 30
        }
        scnView.contentMode = .center
        scnView.backgroundColor = .clear()
        self.characterPickerController = CharacterPickerController(worldViewController: self)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Play background music.
        
        //        backgroundAudioNode.loops = true
        //        let sound = SCNAction.playAudioSource(backgroundAudioNode, waitForCompletion: true)
        //        scene.rootNode.runAction(sound)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Reconfigure the view for the current VoiceOver status whenever
        // the layout changes.
        setVoiceOverForCurrentStatus()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        unregisterForAccessibilityNotifications()
    }
    
    // MARK: Start
    
    func startPlayback() {
        // Remove any remaining actions on the actor (from WVC+StateChange.swift).
        for actor in scene.actors {
            actor.node.removeAllActions()
        }
        
        // Prepare the scene for playback.
        if case .built = scene.state {
            scene.state = .ready
        }
        
        beginLoadingAnimations()
        startRunningSceneIfReady()
        
        // Reset end state.
        isDisplayingEndState = false
    }
    
    /// Set after the first call to `startRunningSceneIfReady()`.
    private var isLoading = false
    func startRunningSceneIfReady() {
        // Ensure that the scene is not already running or in the process of loading.
        guard scene.state != .run && !isLoading else { return }
        isLoading = true
                
        let readyOperation = BlockOperation  { [unowned self] in
            self.isLoading = false

            // Verify that the LiveViewPoster has been removed.
            guard self.posterImageView?.superview == nil else { return }
            
            // Set controller after scene has been initialized on `scnView`.
            self.cameraController = CameraController(view: self.scnView)
            self.cameraController?.setInitialCameraPosition()
            
            // After the scene is prepared, and all animations are loaded, transition to the run state.
            self.scene.state = .run
        }
        
        for operation in loadingQueue.operations {
            readyOperation.addDependency(operation)
        }
        OperationQueue.main().addOperation(readyOperation)
    }
    
    /// NOTE: This can be run off the main queue.
    func saveLiveViewPoster() {
        scene.state = .initial
        scene.commandQueue.runMode = .randomAccess

        // Prevent animations from running.
        for actor in self.scene.actors {
            actor.node.removeFromParentNode()
            actor.removeComponent(AnimationComponent.self)
        }
        
        dispatch_after(seconds: 3.5) {
            let image = self.scnView.snapshot()
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let filePath = "\(paths[0])/LiveViewPoster.png"
            
            // Save image to be retrieved by UIApplication tests.
            do {
                try UIImagePNGRepresentation(image)?.write(to: URL(fileURLWithPath: filePath), options: [])
            } catch {
                log(message: "Unable to save live view poster")
            }
        }
    }
    
    // MARK: Loading
    
    /// Loads a base set of animation for every actor that has been added to the scene, as well as
    /// the animations necessary to carry out each command in the `commandQueue`.
    /// Uses `loadingQueue` to start loading all shared animations.
    func beginLoadingAnimations() {
        guard !isLoading else { return }
        
        var actionsForType = [ActorType: [ActorAction]]()
        // Add in a set of base animations to load for each actor.
        let baseActions: [ActorAction] = scene.commandQueue.isEmpty ? [.idle] : ActorAction.levelCompleteActions
        
        for actor in scene.actors {
            let type = actor.type
            actionsForType[type] = [.default] + baseActions
        }
        
        // Load only the additional actions which were used for every actor.
        for command in scene.commandQueue {
            guard let actor = command.commandable as? Actor else { continue }
            let actorType = actor.type
            guard let action = command.command.action else {
                fatalError("A command has been assigned to Actor without a corresponding action.")
            }
            
            let existingActions = actionsForType[actorType] ?? []
            actionsForType[actorType] = [action] + existingActions
        }

        let actorLoader = BlockOperation {
            for (actorType, actions) in actionsForType {
                ActionAnimations.loadAnimations(for: actorType, actions: actions)
                
//                AudioComponent.loadAudio(for: actorType, actions: actions)
            }
        }
        loadingQueue.addOperation(actorLoader)

        let worldAnimationsLoader = BlockOperation {
            // Warm up the `SwitchNode` animations.
//            let _ = Switch.turnOnAnimation
//            let _ = Switch.turnOffAnimation
        }
        loadingQueue.addOperation(worldAnimationsLoader)
    }
}

private var renderedFrameCount = 0
extension WorldViewController: SCNSceneRendererDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, didRenderScene _: SCNScene, atTime time: TimeInterval) {
        renderedFrameCount += 1
        guard renderedFrameCount > WorldConfiguration.Scene.warmupFrameCount else { return }
        
        /*
         Swap the scene in as the render delegate to receive future updates.
         (Used to determine when world is complete `scene.state == .done`).
         */
        scnView?.delegate = scene

        DispatchQueue.main.asynchronously { [unowned self] in
            // Remove the poster now that we know the scene is rendered.
            UIView.animate(withDuration: 0.5, animations: { [unowned self] in
                self.posterImageView?.alpha = 0.0
            }, completion: { [unowned self] _ in
                self.posterImageView?.removeFromSuperview()

                self.startRunningSceneIfReady()
            })
        }
    }
}

extension WorldViewController {
    // MARK: Debug options
    
    var showsCenterMarker: Bool {
        set {
            if newValue == false {
                let centerNode = scene.rootNode.childNode(withName: #function, recursively: true)
                centerNode?.removeFromParentNode()
            }
            else {
                let centerNode = SCNNode(geometry: SCNCylinder(radius: 0.01, height: 2))
                centerNode.position = SCNVector3Make(0, 0, 0)
                centerNode.geometry!.firstMaterial!.diffuse.contents = UIColor.red()
                centerNode.name = #function
                scene.rootNode.addChildNode(centerNode)
            }
        }
        get {
            return scene.rootNode.childNode(withName: #function, recursively: true) != nil
        }
    }
}
