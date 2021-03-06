// 
//  SetUp.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import Foundation

// MARK: Globals
//public let world = GridWorld(columns: 5, rows: 7)
public let world = loadGridWorld(named: "12.8")

public func playgroundPrologue() {
//    addStaticElements()
    addGameNodes()
    
    presentWorld()

    // Must be called in `playgroundPrologue()` to update with the current page contents.
    registerAssessment(world, assessment: assessmentPoint)
    
    //// ----
    // Any items added or removed after this call will be animated.
    finalizeWorldBuilding(for: world)
    //// ----
}

public func presentWorld() {
    setUpLiveViewWith(world)
    
}

// MARK: Epilogue

public func playgroundEpilogue() {
    startPlayback()
}

func addStaticElements() {
    world.removeNodes(at: world.coordinates(inRows:[5]))
    world.placeWater(at: world.coordinates(inRows:[5]))
    
    world.removeNodes(at: world.coordinates(inColumns: [2], intersectingRows: [0,1]))
    world.removeNodes(at: world.coordinates(inColumns: [2,3,4], intersectingRows: [2]))
    world.placeWater(at: world.coordinates(inColumns: [2], intersectingRows: [0,1]))
    world.placeWater(at: world.coordinates(inColumns: [2,3,4], intersectingRows: [2]))
    
    
    world.placeBlocks(at: world.coordinates(inColumns: [0,1], intersectingRows: [1,3]))
    
    world.placeBlocks(at: world.coordinates(inColumns: [0,1,2,3], intersectingRows: [6]))
    world.placeBlocks(at: world.coordinates(inColumns: [0,1,2,3], intersectingRows: [6]))
    world.placeBlocks(at: world.coordinates(inColumns: [2,3], intersectingRows: [3, 4]))
    world.placeBlocks(at: world.coordinates(inColumns: [2], intersectingRows: [3, 4, 6]))
    world.placeBlocks(at: world.coordinates(inColumns: [1], intersectingRows: [4]))
}

func addGameNodes() {
    world.placeGems(at: world.coordinates(inColumns: [0], intersectingRows: [0,2,4]))
    world.placeGems(at: world.coordinates(inColumns: [4], intersectingRows: [4,6]))
    world.placeGems(at: world.coordinates(inColumns: [2], intersectingRows: [4]))
    
    world.place(Switch(), at: Coordinate(column: 3, row: 0))
    
    let lock = PlatformLock(color: .red)
    world.place(lock, at: Coordinate(column: 3, row: 1))
    world.place(Platform(controlledBy: lock), at: Coordinate(column: 4, row: 5))
}
