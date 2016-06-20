// 
//  ActorAction.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import Foundation

/// The different states that an animated actor can be in.
enum ActorAction: String {
    case `default`
    case idle, happyIdle
    case turnLeft, turnRight
    case pickUp
    case toggleSwitch
    
    case walk
    case walkUpStairs
    case walkDownStairs
    case run, runUpStairs, runDownStairs

    case teleport
    
    case turnLockLeft, turnLockRight
    
    case bumpIntoWall
    case almostFallOffEdge
    
    case defeat
    case victory, celebration
    
    case leave, arrive
    case pickerReactLeft, pickerReactRight
    
    static var allIdentifiersByType: [ActorAction: [String]] {
        return [
            .default: ["BreathingIdle"],
            .happyIdle: ["HappyIdle"],
            .idle: ["Idle01", "Idle02", "Idle03", "BreatheLookAround"],
            .turnLeft: ["TurnLeft",],
            .turnRight: ["TurnRight",],
            .pickUp: ["GemTouch",],
            .toggleSwitch: ["Switch"],
            
            .walk: ["Walk", "Walk02"],
            .walkUpStairs: ["StairsUp", "StairsUp02"],
            .walkDownStairs: ["StairsDown", "StairsDown02"],
            .run: ["RunFast01", "RunFast02"],
            .runDownStairs: ["StairsDownFast"],
            .runUpStairs: ["StairsUpFast"],
            
            .teleport: ["Portal"],
            .turnLockLeft: ["LockPick01"],
            .turnLockRight: ["LockPick03"],
            
            .bumpIntoWall: ["BumpIntoWall",],
            .almostFallOffEdge: ["AlmostFallOffEdge",],
            
            .defeat: ["Defeat", "Defeat02", "HeadScratch"],
            .victory: ["Victory", "Victory02"],
            .celebration: ["CelebrationDance"],
            .leave: ["LeavePicker"],
            .arrive: ["ArrivePicker"],
            .pickerReactLeft: ["PickerReactLeft"],
            .pickerReactRight: ["PickerReactRight"],
        ]
    }
    
    // MARK: Static Properties
    
    static var levelCompleteActions: [ActorAction] {
        return [.victory, .celebration, .happyIdle, .defeat]
    }
    
    static var walkingActions: [ActorAction] {
        return [ .walk, .walkUpStairs, .walkDownStairs, .turnLeft, .turnRight ]
    }
    
    var fastVariation: ActorAction? {
        switch self {
        case .walk: return .run
        case .walkUpStairs: return .runUpStairs
        case .walkDownStairs: return .runDownStairs
        
        default:
            return nil
        }
    }
}
