// 
//  Assessments.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
let success = "### Well done! \nYou're figuring this out quickly-keep it up! \n\n[Next Page](@next)"
let hints = [
    "[Initialize](glossary://initialization) your expert, but don't change the [constant](glossary://constant) name, `expert`.",
    "Use [dot notation](glossary://dot%20notation) to code a solution for the rest of the puzzle."

]


let solution: String? = nil

public func assessmentPoint() -> AssessmentResults {
    return updateAssessment(successMessage: success, failureHints: hints, solution: solution)
}
