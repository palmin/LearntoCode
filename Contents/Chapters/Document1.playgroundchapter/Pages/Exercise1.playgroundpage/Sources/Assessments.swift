// 
//  Assessments.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

let solution = "```swift\nmoveForward()\nmoveForward()\nmoveForward()\ncollectGem()\n```"


let success = "### Congratulations! \nYou’ve written your first lines of [Swift](glossary://Swift) code. \n\nByte performed the commands you wrote and did exactly what you asked, in exactly the order that you specified. \n\n[Next Page](@next)"


import PlaygroundSupport
public func assessmentPoint() -> AssessmentResults {
let checker = ContentsChecker(contents: PlaygroundPage.current.text)

    var hints = [
        "Remember, you need to make your character move forward and collect the gem, using commands in the shortcut bar.",
        "First tap `moveForward()` three times, and then tap `collectGem()`. If you have problems with your code, you can start over by tapping the three dot icon at the top of the page and then tapping Reset."
    ]


    
    
    if checker.numberOfStatements == 0 {
        hints[0] = "You need to enter some commands. First tap the area that says \"Tap to enter code\" then use `moveForward()` and `collectGem()` to solve the puzzle."
    } else if checker.numberOfStatements < 3 {
        hints[0] = "Oops! Every `moveForward()` command moves your character forward only one tile. To move forward three tiles, you need **three** `moveForward()` commands."
    } else if checker.functionCallCount(forName: "collectGem") == 0 {
        hints[0] = "You forgot to collect the gem. When you are on the tile with the gem, use `collectGem()` to collect it."
    }
    
    if world.commandQueue.containsIncorrectCollectGemCommand() {
        hints[0] = "Your character needs to be on the tile with the gem for the `collectGem()` command to work."
    }
    
    return updateAssessment(successMessage: success, failureHints: hints, solution: solution)
}
