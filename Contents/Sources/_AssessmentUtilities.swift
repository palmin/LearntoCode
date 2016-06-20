// 
//  _AssessmentUtilities.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import Foundation
import PlaygroundSupport

public typealias AssessmentResults = PlaygroundPage.AssessmentStatus

// MARK: Assessment Hooks

var assessmentObserver: AssessmentGridWorldObserver?
var overflowHandler: QueueOverflowHandler?

private var overrideSuccess = false

public func registerAssessment(_ world: GridWorld, assessment: () -> AssessmentResults) {
    overflowHandler = QueueOverflowHandler(world: world)
    assessmentObserver = AssessmentGridWorldObserver(world: world)
    
    registerAssessment(assessment)
}

public func registerAssessment(_ assessment: () -> AssessmentResults) {
    let page = PlaygroundPage.current
    
    // Mark the page as needing indefinite execution to wait for assessment.
    page.needsIndefiniteExecution = true
    
    let proxy = page.liveView as? PlaygroundRemoteLiveViewProxy
    proxy?.delegate = assessmentObserver
    
    assessmentObserver?.assessmentFunction = assessment
    
    #if DEBUG
    mockProxy.delegate = assessmentObserver
    #endif
}

class AssessmentGridWorldObserver: PlaygroundRemoteLiveViewProxyDelegate {
    unowned let gridWorld: GridWorld

    var observer: NSObjectProtocol!
    var assessmentFunction: (() -> AssessmentResults)?
    
    init(world: GridWorld) {
        self.gridWorld = world
        
        let updateNotification = Notification.Name(rawValue: GridWorldDidUpdateDiffNotification)
        self.observer = NotificationCenter.default().addObserver(forName: updateNotification, object: world, queue: OperationQueue.main()) { [weak self] notification in
            
            // If an AlwaysOn connection is open, send assessment status to the other process.
            if PlaygroundPage.current.isLiveViewConnectionOpen {
                self?.sendAssessmentMessage()
            }
            else if let result = self?.assessmentFunction?() {
                // Set the `assessmentStatus` here when NOT using AlwaysOn.
                PlaygroundPage.current.assessmentStatus = result
            }
        }
    }
    
    deinit {
        NotificationCenter.default().removeObserver(self.observer)
    }
    
    func sendAssessmentMessage() {
        // Double Check that the connection is open.
        guard PlaygroundPage.current.isLiveViewConnectionOpen else {
            log(message: "Attempting to send assessment message, but the connection is closed.")
            return
        }
        
        let pass: Bool
        if let worldResults = gridWorld.diff {
            pass = worldResults.passesCriteria
        } else {
            pass = false
        }
        
        let liveView = PlaygroundPage.current.liveView
        guard let liveViewMessageHandler = liveView as? PlaygroundLiveViewMessageHandler else { return }
        
        let message: PlaygroundValue = .dictionary([LiveViewMessageKey.finishedEvaluating: .boolean(pass)])
        liveViewMessageHandler.send(message)
    }
    
    // MARK: PlaygroundRemoteLiveViewProxyDelegate
    
    func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {
        // Kill user process if LiveView process closed.
        PlaygroundPage.current.finishExecution()
    }
    
    func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy, received message: PlaygroundValue) {
        guard case let .dictionary(dict) = message else { return }
        
        if case let .boolean(success)? = dict[LiveViewMessageKey.finishedEvaluating] {            
            evaluate(success: success)
        }
    }
    
    func evaluate(success: Bool) {
        overrideSuccess = success

        PlaygroundPage.current.assessmentStatus = assessmentFunction?()
        PlaygroundPage.current.finishExecution()
    }
}

/// Uses the global `assessmentObserver` to set the `assessmentStatus` on the current page.
func setAssessmentStatus() {
    PlaygroundPage.current.assessmentStatus = assessmentObserver?.assessmentFunction?()
}

// MARK: Update Assessment

public func updateAssessment(successMessage: String, failureHints: [String], solution: String?) -> AssessmentResults {
    
    if overrideSuccess {
        return .pass(message: successMessage)
    }
    
    guard let diffResults = assessmentObserver?.gridWorld.diff else {
        return .fail(hints: failureHints, solution: solution)
    }
    
    // Check that there were no failures, and at least something has been done in the world.
    if diffResults.passesCriteria {
        return .pass(message: successMessage)
    }
    else {
        return .fail(hints: failureHints, solution: solution)
    }
}
