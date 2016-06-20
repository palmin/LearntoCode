// 
//  AudioComponent.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import SceneKit

class AudioComponent: ActorComponent {
    
    // MARK: Properties
    
    unowned let actor: Actor
    
    var soundsForType = [ActorAction: [SCNAudioSource]]()
    
    required init(actor: Actor) {
        self.actor = actor
        
        
        // Load all sounds for applicable identifiers.
        for (key, identifiers) in ActorAction.allIdentifiersByType {
            for identifier in identifiers {
                let directory = actor.type.resourceFilePathPrefix
                guard let url = Bundle.main().urlForResource(identifier, withExtension: "wav", subdirectory: directory),
                        let audioSource = SCNAudioSource(url: url) else { continue }
                
                audioSource.load()
                soundsForType[key] = [audioSource] + (soundsForType[key] ?? [])
            }
        }
    }

    // MARK: CommandPerformer
    
    func cancel(_: Command) {
        node.removeAllAudioPlayers()
    }
    
    func performRandom(action: ActorAction, withSpeed speed: Float) {
        let rndIndex = soundsForType[action]?.randomIndex ?? 0
        perform(action: action, atIndex: rndIndex, speed: speed)
    }
    
    func perform(action: ActorAction, atIndex index: Int, speed: Float) {
        // Don't allow the audio component to block other components.
        actor.commandableFinished(self)
        
        guard let sounds = soundsForType[action] where sounds.indices.contains(index) else {
            log(message: "Failed to find \(action) audio file.")
            return
        }
        
        // Grab the `SCNAudioSource`
        let source = sounds[index]
        source.rate = speed
        
        // Positional sound
        let player = SCNAudioPlayer(source: source)
        node.addAudioPlayer(player)
    }
}
