/*:
 **Goal:** Use the AND operator to combine two conditions and adjust Byte's path if both are true.
 
The [logical AND operator (&&)](glossary://logical%20AND%20operator) combines two [Boolean](glossary://Boolean) conditions and runs your code only if *both* are true. For example, in the following code, `isBlocked` AND `isOnClosedSwitch` must both be true.
 
    if isBlocked && isOnClosedSwitch {
        toggleSwitch()
    }
 
  * callout(New Condition!):

     The [Boolean](glossary://Boolean) condition `isBlockedLeft` is **true** if Byte *can’t* move forward 1 tile to the left and **false** if Byte can make that move.
 
1. steps: Add an `if` statement in the `for` loop, then add a condition to check whether Byte is on a gem. 
2. Use the keyboard to add a space. In the UCB tap **`&&`**, then add a second condition.
3. If Byte is on a gem AND blocked on the left, turn right and collect the gem. Otherwise, if Byte is on a gem, collect it.
*/
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, show, isOnOpenSwitch, moveForward(), turnLeft(), turnRight(), collectGem(), toggleSwitch(), isOnGem, isOnClosedSwitch, isBlocked, isBlockedLeft, if, func, for, !, &&)
//#-hidden-code
playgroundPrologue()
//#-end-hidden-code
//#-editable-code Tap to enter code
for i in 1...7 {
    moveForward()    
}
//#-end-editable-code


//#-hidden-code
playgroundEpilogue()
//#-end-hidden-code
//#-hidden-code
//
//  Contents.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
//#-end-hidden-code
