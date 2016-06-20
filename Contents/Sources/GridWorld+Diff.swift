// 
//  GridWorld+Diff.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

func coordinatesFromResults(_ results: Set<DiffResult>) -> [Coordinate] {
    return results.map { $0.coordinate }
}

extension GridWorld {    
    // MARK: Diff Calculation
    
    /**
     Checks for the following:
        - Gems in the final world have been removed. (Adds non-removed gems to `missedActions`)
        - Counts the number of collected gems. (`pickupCount`)
        - All switches in the final world are on. (`openedSwitchCount`)
    */
    func calculateResults() -> GridWorldResults {
        // Collect the results for any neglected gems or closed switches.
        var missedActions = Set<DiffResult>()
        
        //--- Search the world for gems that were not collected.
        let gems = existingGems(at: allPossibleCoordinates)
        for gem in gems {
            
            missedActions.insert(DiffResult(coordinate: gem.coordinate, foundNodes: [gem.node], type: .failedToPickUpGoal))
        }
        
        let pickupCount = commandQueue.completeCommands.reduce(0) { count, performer in
            guard performer.commandable is Actor else { return count }
            
            let command = performer.command
            
            if case .remove(let items) = command where items.first is Gem {
                return count + 1
            }
            return count
        }
        
        //--- Check on/off state for all switches in the current world
        var openedSwitchCount: Int = 0
        
        for switchNode in existingNodes(ofType: Switch.self, at: allPossibleCoordinates) {
            let coordinate = switchNode.coordinate
            
            if switchNode.isOn {
                openedSwitchCount += 1
            }
            else {
                missedActions.insert(DiffResult(coordinate: coordinate, foundNodes: [switchNode.node], type: .incorrectSwitchState))
            }
        }
        
        let criteria = self.successCriteria ?? GridWorldSuccessCriteria()
        return GridWorldResults(criteria: criteria, missedActions: missedActions, collectedGems: pickupCount, openSwitches: openedSwitchCount)
    }
}
