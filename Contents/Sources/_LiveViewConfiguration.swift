// 
//  _LiveViewConfiguration.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import PlaygroundSupport

// MARK: Scene Loading

private var _scene: Scene? = nil

public func loadGridWorld(named name: String) -> GridWorld {
    do {
        _scene = try Scene(named: name)
    }
    catch {
        presentAlert(title: "Failed To Load `\(name)`", message: "\(error)")
        return GridWorld(columns: 0, rows: 0)
    }
    
    return _scene!.gridWorld
}

// Use a typealias to refer to the Actor type with Character
public typealias Character = Actor

// Use a typealias to refer to the WorldNode type with Item
public typealias Item = WorldNode

// MARK: Scene Presentation

/**:
    Used to present the world as the `currentPage`'s liveView.

    Note: This is not included in the project target and is only
    used within the Playground to present the liveView.
*/
private var sceneController: WorldViewController!
public func setUpLiveViewWith(_ gridWorld: GridWorld) {
    let loadedScene = _scene ?? Scene(world: gridWorld)
    _scene = nil
    
    // Create the controller, but don't display it until `startPlayback`.
    sceneController = WorldViewController.makeController(with: loadedScene)
}

public func finalizeWorldBuilding(for world: GridWorld, collapsingCommands: (() -> Void)? = nil) {
    // Animate any additional world elements that are added or removed.
    world.isAnimated = true
    
    collapsingCommands?()
    
    // Add commands to remove the random nodes after the world is built.
    world.removeRandomNodes()
}

public func startPlayback() {
    // Increment the execution count.
    let store = PlaygroundPage.current.keyValueStore
    store[KeyValueStoreKey.executionCount] = .integer(currentPageRunCount() + 1)

    PlaygroundPage.current.liveView = sceneController
    sceneController.startPlayback()
}

public func sendCommands(for world: GridWorld) {
    let liveView = PlaygroundPage.current.liveView
    guard let liveViewMessageHandler = liveView as? PlaygroundLiveViewMessageHandler else {
        log(message: "Attempting to send commands, but the connection is closed.")
        return
    }
    
    guard world.isAnimated else {
        presentAlert(title: "Failed To Send Commands.", message: "Missing call to `finalizeWorldBuilding(for: world)` in page sources.")
        return
    }
    
    // Reset the queue to reset state items like Switches, Portals, etc. 
    world.commandQueue.reset()
    
    let encoder = CommandEncoder(world: world)
    
    for command in world.commandQueue {
        let message = encoder.createMessage(from: command)
        liveViewMessageHandler.send(message)
        
        #if DEBUG
        // Testing in app.
        let appDelegate = (UIApplication.shared().delegate as! AppDelegate).rootVC
        appDelegate?.receive(message)
        #endif
    }
    
    // Mark that all the commands have been sent.
    let finished = PlaygroundValue.boolean(true)
    let finalMessage = [LiveViewMessageKey.finishedSendingCommands: finished]
    liveViewMessageHandler.send(.dictionary(finalMessage))
    
    #if DEBUG
    let appDelegate = (UIApplication.shared().delegate as! AppDelegate).rootVC
    appDelegate?.receive(.dictionary(finalMessage))
    #endif
}

// MARK: Alerts

#if os(iOS)
import UIKit

func presentAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .`default`, handler: nil))
    
    let vc = UIViewController()
    PlaygroundPage.current.liveView = vc
    vc.present(alert, animated: true, completion: nil)
}
#elseif os(OSX)
import AppKit

func presentAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.addButton(withTitle: "OK")
    alert.messageText = title + "\n" + message
    alert.runModal()
}

#endif
