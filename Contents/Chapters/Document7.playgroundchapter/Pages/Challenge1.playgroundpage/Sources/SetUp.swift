// 
//  SetUp.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import Foundation

// MARK: Globals
let world: GridWorld = loadGridWorld(named: "7.4")
public let actor = Actor()

public func playgroundPrologue() {
    
    placeActor()
    placeItems()
    placePortals()
    

    // Must be called in `playgroundPrologue()` to update with the current page contents.
    registerAssessment(world, assessment: assessmentPoint)
    
    //// ----
    // Any items added or removed after this call will be animated.
    finalizeWorldBuilding(for: world)
    //// ----
}

// Called from LiveView.swift to initially set the LiveView.
public func presentWorld() {
    setUpLiveViewWith(world)
    
}

// MARK: Epilogue

public func playgroundEpilogue() {
    sendCommands(for: world)
}

func placeItems() {
    let items = [
                    Coordinate(column: 0, row: 4),
                    Coordinate(column: 1, row: 3),
                    Coordinate(column: 3, row: 4),
                    Coordinate(column: 3, row: 1),
                    ]
    let switchNodes = world.place(nodeOfType: Switch.self, at: items)
    for switchNode in switchNodes {
        if arc4random_uniform(6) % 2 == 0 {
            switchNode.isOn = true
        } else {
            switchNode.isOn = false
        }
    }
}

func placePortals() {
    world.place(Portal(color: .blue), between: Coordinate(column: 1, row: 1), and: Coordinate(column: 2, row: 3))
}

func placeActor() {
    world.place(actor, facing: north, at: Coordinate(column: 0, row: 1))
}

func placeBlocks() {
    let obstacles = [
                        Coordinate(column: 1, row: 2),
                        Coordinate(column: 2, row: 2),
                        ]
    world.removeNodes(at: obstacles)
    world.placeWater(at: obstacles)
    
    let tiers = [
                    Coordinate(column: 2, row: 4),
                    Coordinate(column: 3, row: 4),
                    Coordinate(column: 4, row: 4),
                    
                    Coordinate(column: 1, row: 3),
                    Coordinate(column: 2, row: 3),
                    Coordinate(column: 1, row: 3),
                    Coordinate(column: 2, row: 3),
                    Coordinate(column: 3, row: 3),
                    
                    Coordinate(column: 3, row: 2),
                    
                    Coordinate(column: 1, row: 1),
                    Coordinate(column: 2, row: 1),
                    Coordinate(column: 3, row: 1),
                    Coordinate(column: 3, row: 1),
                    Coordinate(column: 3, row: 0),
                    Coordinate(column: 3, row: 0),
                    
                    Coordinate(column: 0, row: 1),
                    Coordinate(column: 0, row: 2),
                    ]
    world.placeBlocks(at: tiers)
    
    world.place(Stair(), facing: north, at: Coordinate(column: 0, row: 3))
    world.place(Stair(), facing: west, at: Coordinate(column: 1, row: 4))
    world.place(Stair(), facing: west, at: Coordinate(column: 2, row: 1))
    world.place(Stair(), facing: north, at: Coordinate(column: 3, row: 2))
}
