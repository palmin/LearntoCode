// 
//  _AlwaysOn.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import PlaygroundSupport
import SceneKit

private var _isLiveViewConnectionOpen = false

extension PlaygroundPage {
    var isLiveViewConnectionOpen: Bool {
        return _isLiveViewConnectionOpen
    }
}

extension WorldViewController: PlaygroundLiveViewMessageHandler {
    // MARK: PlaygroundLiveViewMessageHandler
    
    public func liveViewMessageConnectionOpened() {
        _isLiveViewConnectionOpen = true
        
        scene.resetDuration = 0.5
        scene.state = .ready
        
        // Remove all commands from previous run. 
        scene.commandQueue.clear()
        
        // In the LiveView process clear the commandQueue delegates.
        // Overflow from infinite loops will be checked in the user process, 
        // Randomized Queue Observation will also take place in the user process.
        scene.commandQueue.reportsAddedCommands = false
    }
    
    public func receive(_ message: PlaygroundValue) {
        guard case let .dictionary(dict) = message else {
            log(message: "Received invalid message: \(message).")
            return
        }
        
        if case .boolean(_)? = dict[LiveViewMessageKey.finishedSendingCommands] {
            startPlayback()
            return
        }
        
        let world = scene.gridWorld
        let decoder = CommandDecoder(world: world)
        guard let command = decoder.command(from: message),
             commandable = decoder.commandable(from: message) else {
            log(message: "Failed to decode message: \(message).")
            return
        }
        
        // Directly add the performer. 
        let performer = CommandPerformer(commandable: commandable, command: command)
        world.commandQueue.add(performer: performer)
    }
    
    public func liveViewMessageConnectionClosed() {
        _isLiveViewConnectionOpen = false
        
        // Stop running the command queue.
        scene.commandQueue.runMode = .randomAccess
        scene.state = .initial
    }
}
