// 
//  Assessments.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
let success = "### Fantastic! \nYou used the right commands, in the right order, to make Byte complete the task. You’ve got this! \n\n[Next Page](@next)"

let solution = "```swift\nmoveForward()\nmoveForward()\nturnLeft()\nmoveForward()\ncollectGem()\nmoveForward()\nturnLeft()\nmoveForward()\nmoveForward()\ntoggleSwitch()\n```"

import PlaygroundSupport
public func assessmentPoint() -> AssessmentResults {
    let checker = ContentsChecker(contents: PlaygroundPage.current.text)
    
var hints = [
    "Find the switch—it’s the tile at the top of the second staircase.",
    "Use `moveForward()`, `turnLeft()`, and `collectGem()` just like you did before. When you reach the switch, tell Byte to toggle it using the `toggleSwitch()` command."
]


    if checker.functionCallCount(forName: "toggleSwitch") == 0 {
        hints[0] = "Collect the gem, then move Byte to the switch (the tile at the top of the second staircase). Then use `toggleSwitch()` to turn it on."
    } else if checker.functionCallCount(forName: "collectGem") == 0 {
        hints[0] = "Don't forget to collect the gem!"
    } else if checker.numberOfStatements < 9 {
        hints[0] = "Remember, each `moveForward()` command moves your character one tile forward. This is true even if you move up or down a staircase!"
    }
    
    
    
    return updateAssessment(successMessage: success, failureHints: hints, solution: solution)
}



