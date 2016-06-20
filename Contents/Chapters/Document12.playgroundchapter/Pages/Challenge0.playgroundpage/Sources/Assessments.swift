// 
//  Assessments.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
let success = "### Great Job! \nNow that you’ve learned how to create functions with [parameters](glossary://parameter), find out how to use parameters to place a character in a specific location in the puzzle world. \n\n[Next Page](@next)"
let hints = [
"Remember, you can use both the `move(distance: Int)` and `turnLock(up: Bool, numberOfTimes: Int)` methods to solve this puzzle.",
]

let solution: String? = nil


public func assessmentPoint() -> AssessmentResults {
    return updateAssessment(successMessage: success, failureHints: hints, solution: solution)
}
