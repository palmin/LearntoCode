// 
//  CommandPerformer.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import Foundation

/// An `CommandPerformer` associates a command with the actor that can perform that command.
public struct CommandPerformer {
    unowned let commandable: Commandable
    let command: Command
    
    init(commandable: Commandable, command: Command) {
        self.commandable = commandable
        self.command = command
    }
    
    // MARK:
    
    func applyStateChange(inReverse reversed: Bool = false) {
        let command = reversed ? self.command.reversed : self.command
        commandable.applyStateChange(for: command)
    }
    
    /// Convenience to run the command against the `commandable`.
    func perform() {
        commandable.perform(command)
    }
    
    func cancel() {
        commandable.cancel(command)
    }
}

extension CommandPerformer: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(commandable.dynamicType): \(command)"
    }
}
