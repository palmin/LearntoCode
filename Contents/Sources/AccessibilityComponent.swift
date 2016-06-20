// 
//  AccessibilityComponent.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import AVFoundation

class AccessibilityComponent: NSObject, ActorComponent, AVSpeechSynthesizerDelegate {
    // MARK: Properties
    
    unowned let actor: Actor
    
    let synthesizer = AVSpeechSynthesizer()
    
    required init(actor: Actor) {
        self.actor = actor
    }
    
    // MARK: CommandPerformer
    
    func perform(_ command: Command) {
        let speed = actor.world?.commandSpeed ?? 1.0
        
        /// Speak the command.
        let utterance = AVSpeechUtterance(string:  "\(actor.speakableName) " + command.speakableDescription + ".")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate + (0.25 * (speed - 1 ))
        
        synthesizer.delegate = self
        synthesizer.speak(utterance)
    }
    
    func cancel(_: Command) {
        synthesizer.stopSpeaking(at: .word)
    }
    
    // MARK: AVSpeechSynthesizerDelegate
    
    @objc(speechSynthesizer:didFinishSpeechUtterance:)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Mark this component as finished when speech is complete.
        actor.commandableFinished(self)
    }
    
    @objc(speechSynthesizer:didCancelSpeechUtterance:)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        actor.commandableFinished(self)
    }
}
