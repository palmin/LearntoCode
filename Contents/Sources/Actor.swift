// 
//  Actor.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import SceneKit

public class Actor: WorldNode, NodeConstructible {
    
    static let worldIdentifier: WorldNodeIdentifier = .actor
    
    var type: ActorType
    
    override weak var world: GridWorld? {
        didSet {
            removeComponent(WorldActionComponent.self)
            addComponent(WorldActionComponent.self)
            
            let worldComponent = componentForType(WorldActionComponent.self)
            worldComponent?.world = world
            
            commandDelegate = world
        }
    }
    
    /// Convenience accessor for world's `commandSpeed`
    var commandSpeed: Float {
        return world?.commandSpeed ?? 1.0
    }
    
    var components = [ActorComponent]()
    var runningComponents = [ActorComponent]()
    
    weak var commandDelegate: CommandCompletionDelegate? = nil
    
    lazy var actorCamera: SCNNode = {
        // Programmatically add an actor camera.
        let actorCamera = SCNNode()
        actorCamera.position = SCNVector3Make(0, 0.785, 3.25)
        actorCamera.eulerAngles.x = -0.1530727
        actorCamera.camera = SCNCamera()
        actorCamera.name = "actorCamera"
        self.node.addChildNode(actorCamera)
        
        return actorCamera
    }()
    
    /// If the `Character` is not provided, the saved `Character` will be used.
    public init(name: CharacterName? = nil) {
        self.type = name?.type ?? ActorType.loadDefault()
        super.init(node: type.createNode())!
        
        addComponent(AnimationComponent.self)
//        addComponent(AudioComponent.self)
        
        node.categoryBitMask = WorldConfiguration.characterLightBitMask
    }
    
    
    public override required init?(node: SCNNode) {
        guard node.identifier == .actor
            && node.identifierComponents.count >= 2 else { return nil }
        guard let type = ActorType(rawValue: node.identifierComponents[1]) else { return nil }
        self.type = type
        
        super.init(node: node)
        
        addComponent(AnimationComponent.self)
        //        addComponent(AudioComponent.self)
        
        node.categoryBitMask = WorldConfiguration.characterLightBitMask
    }
    
    // MARK: CommandPerformer Components
    
    func addComponent(_ performer: ActorComponent.Type) {
        components.append(performer.init(actor: self))
    }
    
    func componentForType<T : ActorComponent>(_ componentType: T.Type) -> T? {
        for component in components where component is T {
            return component as? T
        }
        return nil
    }
    
    func removeComponent<T : ActorComponent>(_ componentType: T.Type) {
        guard let index = components.index(where: { $0 is T }) else { return }
        components.remove(at: index)
    }
    
    // MARK: 
    
    /**
    Instructs the character to jump forward and either up or down one block. If the block the character is facing is one block higher than the block the character is standing on, the character will jump on top of it. If the block the character is facing is one block lower than the block the character is standing on, the character will jump down to that block.
     */
    public func jump() -> Coordinate {
        guard let world = world else { return Coordinate(column: 0, row: 0) }
        
        let nextCoordinate = nextCoordinateInCurrentDirection
        guard world.existingNode(ofType: Block.self, at: nextCoordinate) != nil else {
            add(command: .incorrectOffEdge)
            return coordinate
        }
        
        let deltaY = heightDisplacementMoving(to: nextCoordinate)
        guard (abs(deltaY) - 0.001) < WorldConfiguration.levelHeight else {
            add(command: .incorrectIntoWall)
            return coordinate
        }
        
        let point = nextCoordinate.position
        let yDisplacement: SCNFloat
        if deltaY.isClose(to: 0) || deltaY.isClose(to: WorldConfiguration.levelHeight) {
            // Jump up
            yDisplacement = position.y + deltaY
        }
        else {
            // Jump down
            yDisplacement = position.y - deltaY
        }
        
        let destination = SCNVector3Make(point.x, yDisplacement, point.z)
        add(command: .move(from: position, to: destination))
        
        return nextCoordinate
    }
}

// MARK: Movement Commands

extension Actor {
    
    /**
     Moves the character forward one tile.
     */
    @discardableResult
    public func moveForward() -> Coordinate {
        guard let world = world else { return Coordinate(column: 0, row: 0) }
        let movementResult = world.movementResult(heading: heading, from: position)
        
        switch movementResult {
        case .valid:
            let nextCoordinate = nextCoordinateInCurrentDirection
            
            // Check for stairs.
            let yDisplacement = position.y + heightDisplacementMoving(to: nextCoordinate)
            let point = nextCoordinate.position
            
            let destination = SCNVector3Make(point.x, yDisplacement, point.z)
            add(command: .move(from: position, to: destination))
            
            // Check for portals.
            let portal = world.existingNode(ofType: Portal.self, at: nextCoordinate)
            if let destinationPortal = portal?.linkedPortal where portal!.isActive {
                add(command: .teleport(from: destination, to: destinationPortal.position))
            }
            
        case .edge, .obstacle:
            add(command: .incorrectOffEdge)
            
        case .wall, .raisedTile, .occupied:
            add(command: .incorrectIntoWall)
        }
        
        return Coordinate(position)
    }
    
    /**
     Turns the character left.
     */
    public func turnLeft() {
        turnBy(90)
    }
    
    /**
     Turns the character right.
     */
    public func turnRight() {
        turnBy(-90)
    }
    
    /**
     Moves the character forward by a certain number of tiles, as determined by the `distance` parameter.
     */
    public func move(distance: Int) {
        for _ in 1...distance {
            self.moveForward()
        }
    }
    
    // MARK: Command Helpers
    
    /**
     Rotates the actor by `degrees` around the y-axis.
     
     - turnLeft() = 90
     - turnRight() = -90/ 270
     */
    @discardableResult
    func turnBy(_ degrees: Int) -> SCNFloat {
        // Convert degrees to radians.
        let nextDirection = (rotation + degrees.toRadians).truncatingRemainder(dividingBy: 2 * π)
        
        let currentDir = Direction(radians: rotation)
        let nextDir = Direction(radians: nextDirection)
        
        let clockwise = currentDir.angle(to: nextDir) < 0
        add(command: .turn(from: rotation, to: nextDirection, clockwise: clockwise))
        
        return nextDirection
    }
    
    /// Returns the next coordinate moving forward 1 tile in the actors `currentDirection`.
    var nextCoordinateInCurrentDirection: Coordinate {
        return coordinateInCurrentDirection(displacement: 1)
    }
    
    func coordinateInCurrentDirection(displacement: Int) -> Coordinate {
        let heading = Direction(radians: rotation)
        let coordinate = Coordinate(position)
        
        return coordinate.advanced(by: displacement, inDirection: heading)
    }
    
    func heightDisplacementMoving(to coordinate: Coordinate) -> SCNFloat {
        guard let world = world else { return 0 }
        let startHeight = position.y
        let endHeight = world.height(at: coordinate)
        
        return endHeight - startHeight
    }
}

// MARK: Item Commands

extension Actor {
    
    /**
     Instructs the character to collect a gem on the current tile.
     */
    public func collectGem() {
        guard let world = world else { return }
        let coordinate = Coordinate(position)
        
        if let item = world.existingGems(at: [coordinate]).first {
            add(command: .remove([item]))
        }
        else {
            add(command: .incorrectPickUp)
        }
    }
    
    /**
     Instructs the character to toggle a switch on the current tile.
     */
    public func toggleSwitch() {
        guard let world = world else { return }
        let coordinate = Coordinate(position)
        
        if let switchNode = world.existingNode(ofType: Switch.self, at: coordinate) {
            // Toggle switch to the opposite of it's original value. 
            let oldValue = switchNode.isOn
            add(command: .toggleSwitch(at: coordinate, on: !oldValue))
        }
        else {
            // Add the same command do that the actor still looks like they tried to toggle the switch even if non is present.
            add(command: .incorrectToggleSwitch)
        }
    }
}

// MARK: Boolean Commands

extension Actor {
    
    /**
     Condition that checks if the character is currently on a tile with a gem on it.
     */
    public var isBlocked: Bool {
        guard let world = world else { return false }
        return !world.isValidActorTranslation(heading: heading, from: position)
    }
    
    /**
     Condition that checks if the character is blocked on the left.
     */
    public var isBlockedLeft: Bool {
        return isBlocked(heading: .west)
    }
    
    /**
     Condition that checks if the character is blocked on the right.
     */
    public var isBlockedRight: Bool {
        return isBlocked(heading: .east)
    }
    
    func isBlocked(heading: Direction) -> Bool {
        guard let world = world else { return false }
        let blockedCheckDir = Direction(radians: rotation - heading.radians)
        
        return !world.isValidActorTranslation(heading: blockedCheckDir, from: position)
    }
    
    // MARK: isOn
    
    /**
     Condition that checks if the character is currently on a tile with that contains a WorldNode of a specific type.
     */
    public func isOnNode(ofType type: WorldNode.Type) -> Bool {
        return nodeAtCurrentPosition(ofType: type) != nil
    }
    
    /**
     Condition that checks if the character is currently on a tile with a gem on it.
     */
    public var isOnGem: Bool {
        return isOnNode(ofType: Gem.self)
    }
    
    /**
     Condition that checks if the character is currently on a tile with an open switch on it.
     */
    public var isOnOpenSwitch: Bool {
        if let switchNode = nodeAtCurrentPosition(ofType: Switch.self) {
            return switchNode.isOn
        }
        return false
    }
    
    /**
     Condition that checks if the character is currently on a tile with a closed switch on it.
     */
    public var isOnClosedSwitch: Bool {
        if let switchNode = nodeAtCurrentPosition(ofType: Switch.self) {
            return !switchNode.isOn
        }
        return false
    }
    
    func nodeAtCurrentPosition<Node: WorldNode>(ofType type: Node.Type) -> Node?  {
        guard let world = world else { return nil }
        let coordinate = Coordinate(position)
        return world.existingNode(ofType: type, at: coordinate)
    }
}

// MARK: Commandable

extension Actor: Commandable {
    
    var id: Int {
        return worldIndex
    }
    
    var isRunning: Bool {
        return !runningComponents.isEmpty
    }
    
    func applyStateChange(for command: Command) {
        for performer in components {
            performer.applyStateChange(for: command)
        }
    }
    
    /// Cycles through the actors components allowing each component to respond to the command.
    func perform(_ command: Command) {
        if !runningComponents.isEmpty {
            for performer in runningComponents {
                performer.cancel(command)
            }
        }
        runningComponents = self.components
        
        for performer in runningComponents {
            performer.perform(command)
        }
    }
    
    func cancel(_ command: Command) {
        // Cancel all components.
        // A lot of components don't hold as running, but need to be reset with cancel.
        for performer in components {
            performer.cancel(command)
        }
    }
    
    /// Convenience to create an `CommandPerformer` by bundling in `self` with the provided command.
    func add(command: Command) {
        guard let world = world else { return }
        let performer = CommandPerformer(commandable: self, command: command)
        world.commandQueue.add(performer: performer, applyingState: true)
    }
}

// MARK: CommandCompletionDelegate

extension Actor: CommandCompletionDelegate {
    
    func commandableFinished(_ commandable: Commandable) {
        
        assert(Thread.isMainThread())
        
        let addressPredicate: (ActorComponent) -> Bool = { unsafeAddress(of: $0) == unsafeAddress(of: commandable) }
        guard let index = runningComponents.index(where: addressPredicate) else { return }
        
        runningComponents.remove(at: index)
        if runningComponents.isEmpty {
            commandDelegate?.commandableFinished(self)
        }
    }
}

// MARK: Swap
extension Actor {
    
    func swap(with actor: Actor) {
        actor.node.removeAllAnimations()
        actor.node.removeAllActions()
        self.type = actor.type
        
        for child in node.childNodes { child.removeFromParentNode() }
        for child in actor.node.childNodes { node.addChildNode(child) }
        
    }
    
}

