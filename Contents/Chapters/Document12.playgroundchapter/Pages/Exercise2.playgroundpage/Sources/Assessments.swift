// 
//  Assessments.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
let success = "### Awesome! \nYou've now created two functions that take [parameters](glossary://parameter). That’s a huge step toward creating generalizable functions. When a function takes multiple parameters, you can customize multiple parts of that function's behavior. You now have access to both the `move` and `turnLock` functions for future puzzles. Use them any time you want! \n\n[Next Page](@next)"
let hints = [
    "First, you’ll need to define the `turnLock` function so that it uses the `up` [parameter](glossary://parameter) to tell the expert which direction to turn the lock. Then use `numberOfTimes` to set the number of times to turn the lock.",
    "The `up` parameter takes an input of type Bool ([Boolean](glossary://Boolean)). You can check the Boolean value with an `if` statement, and then run `turnLockUp()` if true and `turnLockDown()` if false."
]

let solution = "```swift\nfunc turnLock(up up: Bool, numberOfTimes: Int) {\n    for _ in 1...numberOfTimes {\n        if up == true {\n            expert.turnLockUp()\n        } else {\n            expert.turnLockDown()\n        }\n    }\n}\n\nfunc expertTurnAround() {\n    expert.turnLeft()\n    expert.turnLeft()\n}\n\nfunc characterTurnAround() {\n    character.turnLeft()\n    character.turnLeft()\n}\n\nexpert.turnLock(up: true, numberOfTimes: 4)\nexpertTurnAround()\nexpert.turnLock(up: true, numberOfTimes: 4)\ncharacter.move(distance: 3)\ncharacter.collectGem()\ncharacter.TurnAround()\ncharacter.moveFoward()\nexpert.turnLockUp()\ncharacter.turnRight()\ncharacter.moveForward()\ncharacter.collectGem()\ncharacterTurnAround()\ncharacter.move(distance: 2)\nexpert.turnLock(up: false, numberOfTimes: 3)\ncharacter.turnRight()\ncharacter.moveForward()\ncharacter.turnLeft()\ncharacter.moveForward()\ncharacter.collectGem()\ncharacterTurnAround()\ncharacter.move(distance: 2)\nexpertTurnAround()\nexpert.turnLockDown()\ncharacter.moveForward()\ncharacter.collectGem()\n"

public func assessmentPoint() -> AssessmentResults {
    return updateAssessment(successMessage: success, failureHints: hints, solution: solution)
}
