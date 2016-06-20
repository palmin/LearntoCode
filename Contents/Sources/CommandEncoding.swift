// 
//  CommandEncoding.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import PlaygroundSupport
import SceneKit

/*
 Command message structure:
 
 [
  "Commandable": <Commandable_ID>,
  "Command": <Command_Name>,
  "Args": [PlaygroundValue]
 ]
*/

struct EncodingKey {
    static let command = "Command"
    static let commandable = "Commandable"
    static let arguments = "Arguments"
}

final class CommandEncoder {
    unowned let world: GridWorld
    
    init(world: GridWorld) {
        self.world = world
    }
    
    // MARK: Live view message
    
    func createMessage(from performer: CommandPerformer) -> PlaygroundValue {
        // Start with the command dictionary.
        var message = encode(command: performer.command)
        
        // Add the id of the `commandable`.
        message[EncodingKey.commandable] = .integer(performer.commandable.id)
        
        return .dictionary(message)
    }
    
    func encode(command: Command) -> [String: PlaygroundValue] {
        let args: Entry
        
        switch command {
        case let .move(from, to):
            args = arguments([from, to])
            
        case let .teleport(from: from, to):
            args = arguments([from, to])
            
        case let .turn(from, to, clockwise):
            args = arguments([from, to, clockwise])
            
        case let .place(nodes):
            let nonCrashingArray = nodes.map { $0 as MessageConstructor }
            args = arguments(nonCrashingArray)
            
        case let .remove(nodes):
            let nonCrashingArray = nodes.map { $0 as MessageConstructor }
            args = arguments(nonCrashingArray)
            
        case let .toggleSwitch(coordinate, state):
            args = arguments([coordinate, state])
            
        default:
            // Default args for incorrect commands.
            args = arguments([false])
        }
        
        let fullCommand = [commandEntry(from: command), args].map { $0 }
        
        return fullCommand
    }
    
    // MARK: Entires
    
    typealias Entry = (String, PlaygroundValue)
    
    func commandEntry(from command: Command) -> Entry {
        return (EncodingKey.command, .string(command.key))
    }
    
    private func arguments(_ args: [MessageConstructor]) -> Entry {
        let argMessages = args.map { $0.message }
        return (EncodingKey.arguments, .array(argMessages))
    }
}

final class CommandDecoder {
    unowned let world: GridWorld
    
    init(world: GridWorld) {
        self.world = world
    }
    
    // MARK: Live view message
    
    func commandable(from message: PlaygroundValue) -> Commandable? {
        guard case let .dictionary(dict) = message else { return nil }
        guard case let .integer(id)? = dict[EncodingKey.commandable] else { return nil }
        
        let eligibleActors = world.grid.actors.filter {
            $0.worldIndex == id
        }
        
        assert(eligibleActors.count <= 1, "The same command cannot apply to multiple actors.")
        
        // If the command does not apply to any of the actors, assume it's a world command. 
        return eligibleActors.first ?? world
    }
    
    func command(from message: PlaygroundValue) -> Command? {
        guard case let .dictionary(dict) = message else { return nil }
        guard case let .string(command)? = dict[EncodingKey.command] else { return nil }
        guard case let .array(args)? = dict[EncodingKey.arguments] else { return nil }

        
        switch command {
        case "Move":
            guard args.count == 2 else { return nil }
            guard let from = SCNVector3(message: args[0]),
                    to = SCNVector3(message: args[1]) else { return nil }
            
            return .move(from: from, to: to)
        
        case "Teleport":
            guard args.count == 2 else { return nil }
            guard let from = SCNVector3(message: args[0]),
                to = SCNVector3(message: args[1]) else { return nil }
            
            return .teleport(from: from, to: to)
            
        case "Turn":
            guard args.count == 3 else { return nil }
            guard let from = SCNFloat(message: args[0]),
                to = SCNFloat(message: args[1]),
                clkwise = Bool(message: args[2]) else { return nil }
            
            return .turn(from: from, to: to, clockwise: clkwise)
            
        case "ToggleSwitch":
            guard args.count == 2 else { return nil }
            guard let coor = Coordinate(message: args[0]),
                state = Bool(message: args[1]) else { return nil }
            
            return .toggleSwitch(at: coor, on: state)
            
        case "Place":
            let nodes = args.flatMap { nodeMessage -> WorldNode? in
                guard let node = NodeFactory.make(from: nodeMessage, within: world) else { return nil }
                return node
            }
            
            return .place(nodes)
        
        case "Remove":
            let nodes = args.flatMap { nodeMesage -> WorldNode? in
                guard let node = NodeFactory.make(from: nodeMesage, within: world) else { return nil }
                return node
            }
            
            return .remove(nodes)
            
        case "IncorrectPickUp":
            return .incorrectPickUp
            
        case "IncorrectToggleSwitch":
            return .incorrectToggleSwitch
            
        case "IncorrectOffEdge":
            return .incorrectOffEdge
            
        case "IncorrectIntoWall":
            return .incorrectIntoWall
            
        default:
            return nil
        }
    }
}

protocol MessageConstructor {
    var message: PlaygroundValue { get }
}

protocol MessageConstructible: MessageConstructor {
    init?(message: PlaygroundValue)
}

// MARK: MessageConstructible Extensions

extension SCNVector3: MessageConstructible {
    var message: PlaygroundValue {
        return .data(NSKeyedArchiver.archivedData(withRootObject: NSValue(scnVector3: self)))
    }
    
    init?(message: PlaygroundValue) {
        guard case let .data(data) = message else { return nil }
        let value = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSValue
        
        self = value.scnVector3Value
    }
}

extension SCNFloat: MessageConstructible {
    var message: PlaygroundValue {
        return .floatingPoint(Double(self))
    }
    
    init?(message: PlaygroundValue) {
        guard case let .floatingPoint(value) = message else { return nil }
        self = SCNFloat(value)
    }
}

extension Coordinate: MessageConstructible {
    var message: PlaygroundValue {
        return .array([.integer(column), .integer(row)])
    }
    
    init?(message: PlaygroundValue) {
        guard case let .array(values) = message where values.count == 2 else { return nil }
        
        guard case let .integer(col) = values[0],
            case let .integer(row) = values[1] else { return nil }
        
        self = Coordinate(column: col, row: row)
    }
}

extension Bool: MessageConstructible {
    var message: PlaygroundValue {
        return .boolean(self)
    }
    
    init?(message: PlaygroundValue) {
        guard case let .boolean(value) = message else { return nil }
        self = value
    }
}

extension Command {
    var key: String {
        switch self {
        case .move(_): return "Move"
        case .teleport(from: _): return "Teleport"
        case .turn(_): return "Turn"
        case .place(_): return "Place"
        case .remove(_): return "Remove"
        case .toggleSwitch(_): return "ToggleSwitch"
        case .control(_): return "Control"
        case .incorrectPickUp: return "IncorrectPickUp"
        case .incorrectToggleSwitch: return "IncorrectToggleSwitch"
        case .incorrectOffEdge: return "IncorrectOffEdge"
        case .incorrectIntoWall: return "IncorrectIntoWall"
        }
    }
}

extension Array {
    func map<K, V>(transform: (Element) -> (key: K, value: V)) -> Dictionary<K, V> {
        return reduce([:]) { combiningDict, elem in
            var dict = combiningDict
            let (key, value) = transform(elem)
            dict[key] = value
            
            return dict
        }
    }
}
