// 
//  AccessibilityExtensions.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import UIKit
import SceneKit

class CoordinateAccessibilityElement: UIAccessibilityElement {
    
    let coordinate: Coordinate
    unowned let world: GridWorld
    
    /// Override `accessibilityLabel` to always return updated information about world state.
    override var accessibilityLabel: String? {
        get {
            return world.speakableContentsOf(coordinate)
        }
        set {}
    }
    
    init(coordinate: Coordinate, inWorld world: GridWorld, view: UIView) {
        self.coordinate = coordinate
        self.world = world
        super.init(accessibilityContainer: view)
    }
    
}

// MARK: WorldViewController Accessibility

extension WorldViewController {
    
    func registerForAccessibilityNotifications() {
        NotificationCenter.default().addObserver(self, selector: #selector(voiceOverStatusChanged), name: Notification.Name(rawValue: UIAccessibilityVoiceOverStatusChanged), object: nil)
    }
    
    func unregisterForAccessibilityNotifications() {
        NotificationCenter.default().removeObserver(self, name: Notification.Name(rawValue: UIAccessibilityVoiceOverStatusChanged), object: nil)
    }
    
    func voiceOverStatusChanged() {
        DispatchQueue.main.asynchronously { [unowned self] in
            self.setVoiceOverForCurrentStatus()
        }
    }
    
    func setVoiceOverForCurrentStatus() {
        if UIAccessibilityIsVoiceOverRunning() {
            scnView.gesturesEnabled = false

            cameraController?.switchToOverheadView()
            configureAccessibilityElementsForGrid()
            
            // Add speedAdjust button manually because grid takes over view's `accessibilityElements`.
            speedAdjustButton.accessibilityLabel = "Speed adjustment"
            view.accessibilityElements?.append(speedAdjustButton)
            
            // Add an AccessibiilityComponenet to each actor.
            for actor in scene.actors {
                actor.addComponent(AccessibilityComponent.self)
            }
            
            if scene.commandQueue.isEmpty {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, scene.gridWorld.speakableDescription as AnyObject?)
            }
        }
        else {
            // Set for UITesting. 
            view.isAccessibilityElement = true
            view.accessibilityLabel = "The world is running."
            
            scnView.gesturesEnabled = true
            cameraController?.resetFromVoiceOver()
            
            for actor in scene.actors {
                actor.removeComponent(AccessibilityComponent.self)
            }
            
            for test in self.view.subviews {
                if test.tag == 37 {
                    test.removeFromSuperview()
                }
            }
        }
    }
    
    func configureAccessibilityElementsForGrid() {
        view.isAccessibilityElement = false
        view.accessibilityElements = []
        
        for coordinate in scene.gridWorld.columnRowSortedCoordinates {
            let gridPosition = coordinate.position
            let rootPosition = scene.gridWorld.grid.node.convertPosition(gridPosition, to: nil)
            
            let offset = WorldConfiguration.coordinateLength / 2
            let upperLeft = scnView.projectPoint(SCNVector3Make(rootPosition.x - offset, rootPosition.y, rootPosition.z - offset))
            let lowerRight = scnView.projectPoint(SCNVector3Make(rootPosition.x + offset, rootPosition.y, rootPosition.z + offset))
            
            let point = CGPoint(x: CGFloat(upperLeft.x), y: CGFloat(upperLeft.y))
            let size = CGSize (width: CGFloat(lowerRight.x - upperLeft.x), height: CGFloat(lowerRight.y - upperLeft.y))
            
            let element = CoordinateAccessibilityElement(coordinate: coordinate, inWorld: scene.gridWorld, view: view)
            element.accessibilityFrame = CGRect(origin: point, size: size)
            view.accessibilityElements?.append(element)

            // Testing only.
//            let dummyView = UIView(frame: CGRect(origin: CGRect(origin: point, size: size).origin, size: CGSize(width: 20, height: 20)))
//            dummyView.backgroundColor = .blue()
//            dummyView.tag = 37
//            view.addSubview(dummyView)
        }
    }
}

extension GridWorld {

    func speakableContentsOf(_ coordinate: Coordinate) -> String {
        var prefix = coordinate.description
        
        let contents = excludingNodes(ofType: Block.self, at: coordinate).reduce("") { str, node in
            var tileDescription = str
            
            if node.identifier == .actor {
                let actor = node as? Actor
                
                
//                let name = actor?.type.rawValue ?? "Actor"
//                tileDescription.append("\(name), ")
                
                switch actor?.type {
                case .expert?:
                    tileDescription.append("Expert, ")
                    
                default:
                    tileDescription.append("Byte, ")
                }
            }
            else {
                tileDescription.append(node.identifier.rawValue)
                tileDescription.append(", ")
            }
            
            return tileDescription
        }
        let suffix = contents.characters.isEmpty ? " is empty." : " contains \(contents)."
        
        prefix.append(suffix)
        
        return prefix
    }
    
    var columnRowSortedCoordinates: [Coordinate] {
        return allPossibleCoordinates.sorted { coor1, coor2 in
            if coor1.column == coor2.column {
                return coor1.row < coor2.row
            }
            return coor1.column < coor2.column
        }
    }
    
    var speakableDescription: String {
        var description = "The world is \(columnCount) columns by \(rowCount) rows. "
        
        for columnIndex in 0..<columnCount {
            description += "Column \(columnIndex) contains "
            
            let coordinates = self.coordinates(inColumns: [columnIndex], intersectingRows: 0..<self.rowCount)
            let nodes = excludingNodes(ofTypes: [Block.self], at: Array(coordinates)).sorted { node1, node2 in
                node1.coordinate.row < node2.coordinate.row // Sort by row.
            }
            
            for node in nodes {
                switch node.identifier.rawValue {
                case "Actor":
                    description += "Byte facing \(node.heading) at row \(node.coordinate.row), "
                default:
                    description += node.identifier.rawValue + " at row \(node.coordinate.row), "
                }
                
            }
            description += ". "
        }
        
        return description
    }
}

extension Actor {
    
    var speakableName: String {
        return type.rawValue
    }
}

