// 
//  CommandQueue.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import Foundation

enum RunMode {
    case continuous
    case randomAccess
    
    var isDiscrete: Bool {
        return self == .randomAccess
    }
}

protocol CommandQueueDelegate: class {
    func commandQueue(_ queue: CommandQueue, added command: CommandPerformer)
}

/**
    CommandQueue is a single queue in which all commands are added
    so that top level code always executers in order, one command at
    at time.
*/
public class CommandQueue {
    var runMode: RunMode = .continuous
    
    /// A flag used to enable/disable delegate calls depending on what process the queue is in.
    var reportsAddedCommands: Bool = true
    weak var delegate: CommandQueueDelegate?
    weak var overflowDelegate: CommandQueueDelegate?
    
    var isFinished: Bool {
        return currentIndex == endIndex
    }
    
    /// Includes all commands yet to run, as well as the current command.
    var pendingCommands: ArraySlice<CommandPerformer> {
        let index = currentClampedIndex + 1
        guard index <= endIndex else { return [] }
        return commands.suffix(from: index)
    }
    
    /// Includes all commands that have been run.
    var completeCommands: ArraySlice<CommandPerformer> {
        guard !isEmpty else { return [] }
        return commands.prefix(through: currentClampedIndex)
    }
    
    /// The command that is currently being run.
    var currentCommand: CommandPerformer? {
        guard isValidIndex(currentIndex) else { return nil }
        return commands[currentIndex]
    }
    
    /// Return an index that clamps `currentCommandIndex` to 0..<commands.count.
    var currentClampedIndex: Int {
        return currentIndex.clamp(min: 0, max: commands.count - 1)
    }
    
    /// Underlying commands may only be mutated by accessor methods. @see `addCommand(_:)`
    private var commands = [CommandPerformer]()

    /// Lock around `currentCommandIndex`.
    private let commandIndexQueue = DispatchQueue(label: "com.MicroWorlds.CommandQueue")
    
    /// -1 initially because it points at the currently running instruction (None initially).
    private var _currentIndex = -1
    private var currentIndex: Int {
        get {
            return _currentIndex
        }
        set {
            commandIndexQueue.synchronously {
                _currentIndex = newValue
            }
        }
    }
    
    // MARK: Methods
    
    private func isValidIndex(_ index: Int) -> Bool {
        return commands.count > index && index >= 0
    }
    
    // MARK: Add Commands

    func add(performer: CommandPerformer, applyingState: Bool = false) {
        commands.append(performer)
        
        if applyingState {
            applyStateAdvancingCurrentIndex()
        }
        
        if reportsAddedCommands {
            delegate?.commandQueue(self, added: performer)
            overflowDelegate?.commandQueue(self, added: performer)
        }
    }
    
    // Currently all commands are enqueued before being reversed
    // and played back. Whenever a new command is added,
    // apply the current state to update the world for future
    // calculations.
    func applyStateAdvancingCurrentIndex() {
        let newIndex = commands.index(before: endIndex)
        assert(abs(newIndex - currentIndex) == 1, "Should only be applying state for one command in advance. Hitting this likely means that there is a lingering `add(performer:)` call without a state update.")
        
        currentIndex = newIndex
        
        if let command = currentCommand {
            command.applyStateChange()
        }
    }
    
    // MARK: Run Commands
    
    @discardableResult
    func runNextCommand() -> CommandPerformer? {
        return runCommand(atIndex: commands.index(after: currentIndex))
    }
    
    /// Returns the command if the index is valid and can be run.
    @discardableResult
    func runCommand(atIndex index: Int) -> CommandPerformer? {
        // Reset index for invalid indices.
        guard index < commands.count else { currentIndex = commands.count; return nil }
        guard index >= 0 else { currentIndex = -1; return nil }
        
        // Adjust runMode for the requested index. (Makes it easier on the caller).
        if index > commands.index(after: currentIndex) || index < commands.index(before: currentIndex) {
            runMode = .randomAccess
        }
        
        if runMode.isDiscrete {
            // Cancel the current command before running another command.
            currentCommand?.cancel()
            
            // If not accessing commands in order, the world state has to updated.
            correctState(between: currentIndex, and: index)
        }
        
        // Set the current index before running the command, otherwise it's possible to loop continuously.
        currentIndex = index
        
        let commandPerformer = commands[index]
        commandPerformer.perform()
        
        return commandPerformer
    }
    
    // MARK: Reset Commands
    
    @discardableResult
    func resetActorToPreviousCommandState() -> CommandPerformer? {
        runMode = .randomAccess
        currentCommand?.cancel()
        
        // The world state has to updated for the command that is being reset.
        let zeroClampedIndex = Swift.max(commands.index(before: currentIndex), 0)
        correctState(between: currentIndex, and: zeroClampedIndex)
        
        // Decrement the index only if it's within a valid range.
        if currentIndex >= 0 {
            currentIndex -= 1
        }
        
        return currentCommand
    }
    
    /// Resets the queue's state back to the start
    /// from the `currentIndex`.
    func reset() {
        let index = self.index(after: currentIndex)
        
        // Corrects the state for completed commands.
        correctState(between: index, and: startIndex)
        currentIndex = -1
    }
    
    /// Clears the queue and resets all necessary state.
    func clear() {
        currentCommand?.cancel()
        
        reset()
        commands = []
    }
    
    /**
        Adjusts the world state to match commands between the provided indices.
     
        e.g. calling `correctState(between: endIndex, end: 0)`
        rewinds the worlds state back to before the first command was executed.
    */
    private func correctState(between start: Int, and end: Int) {
        guard !commands.isEmpty else { return }
        
        let maxIndex = endIndex - 1
        let startClamped = start.clamp(min: 0, max: maxIndex)
        let endClamped = end.clamp(min: 0, max: maxIndex)
        
        let isReversing = endClamped <= startClamped
        let commandsRange = isReversing ? endClamped...startClamped : startClamped...endClamped
        let stateIndices: [Int] = isReversing ? Array(commandsRange).reversed() : Array(commandsRange)
        
        for index in stateIndices {
            let commandPerformer = commands[index]
            commandPerformer.applyStateChange(inReverse: isReversing)
        }
    }
}

// MARK: Collection 

extension CommandQueue: Collection {
    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return commands.count
    }
    
    public subscript(position: Int) -> CommandPerformer {
        return commands[position]
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
}

extension CommandQueue: CustomDebugStringConvertible {
    public var debugDescription: String {
        let commandsDesc = commands.reduce("") { str, command in
            str + "\(command)\n"
        }
        
        return "\(count) commands\nIndex: \(currentIndex)\n" + commandsDesc
    }
}

// MARK: Assessment

extension CommandQueue {
    public func containsIncorrectMoveForwardCommand(forActor actor: Actor? = nil) -> Bool {
        let commands: [Command] = commandsFor(actor: actor)
        
        let incorrectMoveForwardCommands: [Command] = [
            .incorrectOffEdge,
            .incorrectIntoWall
        ]
        
        return commands.contains { incorrectMoveForwardCommands.contains($0) }
    }
    
    public func containsIncorrectCollectGemCommand(forActor actor: Actor? = nil) -> Bool {
        let commands: [Command] = commandsFor(actor: actor)
        return commands.contains(.incorrectPickUp)
    }
    
    public func containsIncorrectToggleCommand(forActor actor: Actor? = nil) -> Bool {
        let commands: [Command] = commandsFor(actor: actor)
        
        return commands.contains(.incorrectToggleSwitch)
        
    }
    
    public func closedAnOpenSwitch(forActor actor: Actor? = nil) -> Bool {
        let commands: [Command] = commandsFor(actor: actor)
        
        return commands.contains {
            if case let .toggleSwitch(_, on) = $0  {
                return !on
            }
            return false
        }
        
    }
    
    public func triedToMoveOffEdge(forActor actor: Actor? = nil) -> Bool {
        let commands: [Command] = commandsFor(actor: actor)
        
        return commands.contains(.incorrectOffEdge)
    }
    
    public func triedToMoveIntoWall(forActor actor: Actor? = nil) -> Bool {
        let commands: [Command] = commandsFor(actor: actor)
        
        return commands.contains(.incorrectIntoWall)
    }
    
    func commandsFor(actor: Actor?) -> [Command] {
        return self.flatMap { actorCommand in
            guard let actor = actor else {
                return actorCommand.command
            }
            
            if (actorCommand.commandable as? Actor)?.node == actor.node {
                return actorCommand.command
            }
            return nil
        }
    }
    

}
