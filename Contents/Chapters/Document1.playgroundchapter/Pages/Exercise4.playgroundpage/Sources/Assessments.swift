// 
//  Assessments.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
let success = "### Congratulations! \nYou found a bug in the code. All the right commands were written down, but they were in the wrong order. You “debugged” this code by rearranging the commands until you solved the puzzle. \n\n[Next Page](@next) "


let solution = "```swift\nmoveForward()\nmoveForward()\nturnLeft()\nmoveForward()\ncollectGem()\nmoveForward()\ntoggleSwitch()\n```"

import PlaygroundSupport
public func assessmentPoint() -> AssessmentResults {
    let checker = ContentsChecker(contents: PlaygroundPage.current.text)
    
    var hints = [
        "Take a minute to think through what the correct sequence of commands would be, and rearrange the existing code to match that sequence.",
        "Fix the bug by changing the order of commands so that Byte collects the gem and toggles open the switch.",
        ]
    
    let defaultContents = [
        "moveForward",
        "turnLeft",
        "moveForward",
        "moveForward",
        "collectGem",
        "moveForward",
        "toggleSwitch"
    ]

    if checker.numberOfStatements > 7 {
        hints[0] = "You've added more commands than you need. To rearrange existing code, tap once on a command to select it, then tap and drag it to a new location."
    } else if checker.functionCallCount(forName: "collectGem") == 0 {
        hints[0] = "Remember to collect the gem!"
    } else if checker.calledFunctions == defaultContents {
        hints[0] = "Did you notice when the bug occurred? To rearrange your code, tap once on a command to select it, then tap and drag it to a new location."
        
    }
    

    return updateAssessment(successMessage: success, failureHints: hints, solution: solution)
}




