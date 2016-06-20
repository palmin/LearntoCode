// 
//  SetUp.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import Foundation

// MARK: Globals
//public let world = GridWorld(columns: 8, rows: 8)
public let world = loadGridWorld(named: "11.4")
public func playgroundPrologue() {
//    placeBlocks()
    placeExtraItems() // this is stuff that's added post dressing from Buck
    placeItems()
    placePortals()
    placeLocks()
    presentWorld()

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
    startPlayback()
}

public func placeExtraItems() {
    world.place(Block(), at: Coordinate(column: 5, row: 2))
}

func placeBlocks() {
    world.removeNodes(at: world.allPossibleCoordinates)
    
    
    world.placeBlocks(at: world.coordinates(inColumns: 0...3, intersectingRows: [1,3]))
    
    world.placeWater(at: world.coordinates(inColumns: 0...3, intersectingRows: [2]))
    
    world.placeBlocks(at: world.coordinates(inColumns: [5,6,7], intersectingRows: [0,1,2]))
    
    world.placeBlocks(at: world.coordinates(inColumns: 2...5, intersectingRows: 5...7))
    world.placeBlocks(at: world.coordinates(inColumns: 2...5, intersectingRows: 5...7))
    world.placeBlocks(at: world.coordinates(inColumns: 2...4, intersectingRows: [7]))
    
    world.removeNodes(at: Coordinate(column: 6, row: 2))
    
    world.placeBlocks(at: world.coordinates(inColumns: [5,6,7], intersectingRows: [0]))
    world.placeBlocks(at: [Coordinate(column: 7, row: 1), Coordinate(column: 7, row: 2)])
    world.placeBlocks(at: [Coordinate(column: 7, row: 1), Coordinate(column: 7, row: 2)])
    world.placeBlocks(at: [Coordinate(column: 7, row: 2)])
    
    world.place(Stair(), facing:  south, at: Coordinate(column: 2, row: 6))

}

func placeItems() {
    world.placeGems(at: [Coordinate(column: 2, row: 1), Coordinate(column: 6, row: 2)])
}

func placePortals() {
    world.place(Portal(color: .blue), between: Coordinate(column: 1, row: 3), and: Coordinate(column: 5, row: 2))
}
    
func placeLocks() {
    
    let lock = PlatformLock()
    world.place(lock, facing: west, at: Coordinate(column: 4, row: 7))
    let platform1 = Platform(onLevel: 0, controlledBy: lock)
    world.place(platform1, at: Coordinate(column: 1, row: 2))
    let platform2 = Platform(onLevel: 3, controlledBy: lock)
    world.place(platform2, at: Coordinate(column: 6, row: 2))
}

