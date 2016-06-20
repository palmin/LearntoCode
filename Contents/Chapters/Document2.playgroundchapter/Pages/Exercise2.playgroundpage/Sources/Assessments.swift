// 
//  Assessments.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

let solution = "```swift\nfunc turnRight() {\n    turnLeft()\n    turnLeft()\n    turnLeft()\n}\n\nmoveForward()\nturnLeft()\nmoveForward()\nmoveForward()\nturnRight()\nmoveForward()\nmoveForward()\nturnRight()\nmoveForward()\nmoveForward()\nturnRight()\nmoveForward()\nmoveForward()\nmoveForward()\nturnLeft()\nmoveForward()\ntoggleSwitch()\n"

import PlaygroundSupport
func evaluateContents(_ contents: String) -> (success: String, hints: [String]) {
    let checker = ContentsChecker(contents: contents)
    
    var hints = [
        "Remember, `turnRight()` is a combination of three left turns.",
        "Use `turnRight()` any time you want to make a right turn.",
        
        ]
    
    var success = "### You just wrote your first [function](glossary://function)! \nYou can now use functions to create new abilities. To create a new [function](glossary://function), give it a name, [define](glossary://define) it by giving it a set of commands, then [call](glossary://call) it and it will run. \n\n[Next Page](@next)"
    
    let expectedContents = [
        "turnLeft",
        "turnLeft",
        "turnLeft"
    ]
    
    if !checker.function("turnRight", matchesCalls: expectedContents) {
        hints[0] = "First you need to [define](glossary://define) `turnRight()` correctly. To do this, tap within the curly braces of `turnRight()` and add three `turnLeft()` commands. Then use `turnRight()` to complete the puzzle."
        success = "### Good work! \nYou were able to solve the puzzle, but you didn't correctly [define](glossary://define) `turnRight()`! To improve your coding skills, go back and redefine `turnRight()` using three `turnLeft()` commands, then solve the puzzle again."
    } else if checker.functionCallCount(forName: "turnLeft") >= 4 {
        hints[0] = "After you define `turnRight()` you won't need to use `turnLeft()` in your code at all! Instead, call `turnRight()` whenever you need Byte to make a right turn."
    } else if checker.functionCallCount(forName: "turnRight") < 4 {
        hints[0] = "Byte must first move toward the gem, then turn right and move into the portal. On the other side, Byte should turn right and move down the stairs to toggle open the switch."
    } else if checker.functionCallCount(forName: "toggleSwitch") > 1 {
        hints[0] = "Remember, we want all the switches toggled open! If a switch is already open, just leave it as it is."
    }
    return (success, hints)
}
public func assessmentPoint() -> AssessmentResults {

    let (success, hints) = evaluateContents(PlaygroundPage.current.text)
    
    return updateAssessment(successMessage: success, failureHints: hints, solution: solution)
}
