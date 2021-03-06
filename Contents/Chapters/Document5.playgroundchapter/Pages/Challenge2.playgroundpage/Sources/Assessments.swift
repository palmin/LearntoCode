// 
//  Assessments.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

let solution: String? = "```swift\nfunc checkSquare() {\n    if isOnGem {\n        collectGem()\n    } else if isOnClosedSwitch {\n        toggleSwitch()\n    }\n}\n\nfunc completeCorner() {\n    checkSquare()\n    moveForward()\n    checkSquare()\n    turnRight()\n    moveForward()\n}\n\nmoveForward()\nturnRight()\nfor i in 1...4 {\n    completeCorner()\n}"


import PlaygroundSupport
public func assessmentPoint() -> AssessmentResults {
    let checker = ContentsChecker(contents: PlaygroundPage.current.text)
    pageIdentifier = "Boxed_In"

    var hints = [
        "Any tile in the square could have a gem, an open switch, or a closed switch. First, write a function called `checkTile()` to check for each possibility on a single tile.",
        "You'll need to use your function to check every tile. Is there an easy way to do that?",
        "Try using a loop that repeats a set of commands to complete one corner of the puzzle each time.",
        
        ]
    
    let success: String
    if checker.didUseForLoop == false && checker.numberOfStatements > 12 {
        success = "### Oops! \nYou completed the puzzle, but you forgot to include a [for loop](glossary://for%20loop). You ran \(checker.numberOfStatements) lines of code, but with a for loop, you’d need only 12. \n\nYou can try again or move on. \n\n[Next Page](@next)."
    }
    else if checker.didUseForLoop == true && checker.didUseConditionalStatement == false {
        success = "Congrats! \nYou managed to solve the puzzle by using a [for loop](glossary://for%20loop), but you didn’t include [conditional code](glossary://conditional%20code). Using `if` statements makes your code more intelligent and allows it to respond to changes in your environment. \n\nYou can try again or move on. \n\n[Next Page](@next)."
    }
    else if checker.didUseForLoop == true && checker.didUseConditionalStatement == true  && checker.numberOfStatements >= 14 {
        success = "### Great work! \nYour solution used both for loops and [conditional code](glossary://conditional%20code), incredible tools that make your code more intelligent and let you avoid repeating the same set of commands many times. But you used \(checker.numberOfStatements) lines of code. You could move on but can you solve this challenge with fewer lines of code? (Hint: functions are your friend!) \n\n[Next Page](@next)"
    } else {
        success = "### Fantastic! \nYour solution is incredible. You've come a long way, learning conditional code and combining your new skills with functions and `for` loops! \n\n[Next Page](@next)"
    }
    
    
//    switch currentPageRunCount() {
//        
//    case 3..<6:
//        hints[0] = "### Remember, this is a challenge! \nYou can skip it and come back later."
//    case 6..<12:
//        solution = "```swift\nfunc checkSquare() {\n    if isOnGem {\n        collectGem()\n    } else if isOnClosedSwitch {\n        toggleSwitch()\n    }\n}\n\nfunc completeCorner() {\n    checkSquare()\n    moveForward()\n    checkSquare()\n    turnRight()\n    moveForward()\n}\n\nmoveForward()\nturnRight()\nfor i in 1...4 {\n    completeCorner()\n}"
//    default:
//        break
//        
//    }
    
    return updateAssessment(successMessage: success, failureHints: hints, solution: solution)
}




