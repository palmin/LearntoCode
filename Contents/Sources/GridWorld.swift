// 
//  GridWorld.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
import SceneKit

public class GridWorld {
    
    public var columnCount = 0
    
    public var rowCount = 0
    
    /// The node which all game nodes are added to (Blocks, Water, Gems, etc.)
    let grid: GridNode
    
    /// Indicates if adding/ removing additional `WorldNode`s should be animated.
    var isAnimated = false
    
    public var commandSpeed: Float = 1.0
    public let commandQueue = CommandQueue()
    
    public var placeStartMarkerUnderActor = true
    
    /**
     Returns all the possible coordinates (not accounting for those
     that may have been removed) within the grid.
     */
    public var allPossibleCoordinates: [Coordinate] {
        return coordinates(inColumns: 0..<columnCount, intersectingRows: 0..<rowCount)
    }
    
    public var successCriteria: GridWorldSuccessCriteria?
    
    /// Latest diff produced by calling `calculateResults()`.
    public internal(set) var diff: GridWorldResults? {
        didSet {
            NotificationCenter.default().post(name: Notification.Name(rawValue: GridWorldDidUpdateDiffNotification), object: self)
        }
    }
    
    // MARK: Initializers
    
    public init(columns: Int, rows: Int) {
        columnCount = columns
        rowCount = rows

        grid = GridNode()

        buildGridInScene()
    }
    
    init(node: GridNode) {
        grid = node
        
        for node in grid.allNodes {
            // Set the world as these already exist in the GridWorld.
            node.world = self
        }
        
        calculateRowColumnCount()
        
        // Link existing portals. 
        for portal in existingNodes(ofType: Portal.self, at: allPossibleCoordinates) {
            guard let connectingCoordinate = portal.node.coordinateFromName else {
                log(message: "Failed to establish portal connection for: \(portal)")
                continue
            }
            
            let linkedPortal = existingNode(ofType: Portal.self, at: connectingCoordinate)
            portal.linkedPortal = linkedPortal
        }
        
        
        for gem in existingNodes(ofType: Gem.self, at: allPossibleCoordinates) {
            place(Gem(), at: gem.coordinate)
            gem.removeFromWorld()
        }
        
        for s in existingNodes(ofType: Switch.self, at: allPossibleCoordinates) {
            topBlock(at: s.coordinate)?.position.y -= WorldConfiguration.levelHeight
            let block = Block()
            place(block, at: s.coordinate)
            for child in block.node.childNodes where child.name != "Top" {
                child.removeFromParentNode()
            }
            
            place(Switch(), at: s.coordinate)
            s.removeFromWorld()
        }
    }
    
    func calculateRowColumnCount() {
        var maxColumn = 0
        var maxRow = 0
        for node in grid.allNodes {
            if node.coordinate.row > maxRow {
                maxRow = node.coordinate.row
            }
            if node.coordinate.column > maxColumn {
                maxColumn = node.coordinate.column
            }
        }
        
        // +1 for zero based indices.
        columnCount = maxColumn + 1
        rowCount = maxRow + 1
    }
    
    func buildGridInScene() {
        // Place tiles in the root `grid`.
        for column in 0..<columnCount {
            let x = SCNFloat(column) * WorldConfiguration.coordinateLength
            
            for row in 0..<rowCount {
                let z = -SCNFloat(row) * WorldConfiguration.coordinateLength
                
                // Only place marker nodes initially, wait for final geo placement.
                let marker = SCNNode()
                marker.name = WorldNodeIdentifier.block.rawValue
                let block = Block(node: marker)!
                let position = SCNVector3(x: x, y: 0, z: z)
                place(block, at: Coordinate(position))
                block.position.y = 0 // Start the floor at zero.
            }
        }
        
        // Center the `grid` in the scene.
        let dx = -WorldConfiguration.coordinateLength * SCNFloat(columnCount - 1) / 2
        let dz = WorldConfiguration.coordinateLength * SCNFloat(rowCount - 1) / 2
        grid.node.position = SCNVector3Make(dx, 0, dz)
    }
    
    // MARK: Block Patterning
    
    func buildPatteredBlockStacks() {
        
        // Place all tile stacks (if the scene was created).
        for coordinate in allPossibleCoordinates {
            for block in existingNodes(ofType: Block.self, at: [coordinate]) {
                block.addPatterenedGeo()
            }
            
            let coordinateNeedsTop = existingNode(ofType: Portal.self, at: coordinate) == nil
            guard let topBlock = topBlock(at: coordinate)
                where coordinateNeedsTop
                else { continue }
            
            topBlock.addTop()
        }
    }
    
    func removeHiddenQuads() {
        let blocksRemoved = commandQueue.contains {
            // HACK: The Remove(_:) command is mapped to a `.PickUp` actor action.
            return $0.commandable is GridWorld && $0.command.action == .pickUp
        }
        guard !blocksRemoved else { return }
        
        for block in existingNodes(ofType: Block.self, at: allPossibleCoordinates) {
            block.removeHiddenQuads()
        }
    }
    
    // MARK: Node Verification

    /// Ensures that the world is configured correctly.
    func verifyNodePositions() {
        for coordinate in allPossibleCoordinates {
            percolateNodes(at: coordinate)
        }
        
        if placeStartMarkerUnderActor {
            for actor in existingNodes(ofType: Actor.self, at: allPossibleCoordinates) {
                guard existingNode(ofType: StartMarker.self, at: actor.coordinate) == nil else { continue }

                let marker = StartMarker(type: actor.type)
                place(marker, facing: actor.heading, at: actor.coordinate)
            }
        }        
    }
    
    func removeRandomNodes() {
        let randomNodes = existingNodes(ofType: RandomNode.self, at: allPossibleCoordinates)
        if !randomNodes.isEmpty {
            remove(nodes: randomNodes)
        }
    }
    
    func percolateNodes(at coordinate: Coordinate) {
        let nodes = grid.nodes(at: coordinate)
        let contactHeight = height(at: coordinate)

        // Ignore the stackable nodes to avoid double stacking on top of the same nodes contact (Stair at 0.5 -> 1.0).
        for node in nodes where !node.isStackable && node.dynamicType != RandomNode.self {
            node.position.y = contactHeight + node.verticalOffset
        }
        
        // Move gem if actor is underneath. 
        if let gem = nodes.filter({ $0 is Gem}).first where nodes.contains({ $0 is Actor}) {
            gem.position.y = contactHeight + WorldConfiguration.gemDisplacement
        }
    }
}

extension GridWorld {
    
    // MARK: World Probing
    
    /// Returns the first occurrence of the specified type at the coordinate.
    public func existingNode<Node: WorldNode>(ofType type: Node.Type, at coordinate: Coordinate) -> Node? {
        return existingNodes(ofType: type, at: [coordinate]).first
    }
    
    /// Returns all nodes with the provided identifier that exist at the specified coordinates.
    public func existingNodes<Node: WorldNode>(ofType type: Node.Type, at coordinates: [Coordinate]) -> [Node] {
        
        return coordinates.flatMap { coordinate -> [Node] in
            let candidateChildren = grid.nodes(at: coordinate)
            
            let nodes = candidateChildren.flatMap { node -> Node? in
                if node.dynamicType == type {
                    return node as? Node
                }
                return nil
            }
            
            return nodes
        }
    }
    
    /// Returns all nodes except the provided identifiers that exist at the specified coordinates.
    func excludingNodes<Node: WorldNode>(ofTypes types: [Node.Type], at coordinates: [Coordinate]) -> [WorldNode] {
        return coordinates.flatMap { coordinate -> [WorldNode] in
            let candidateChildren = grid.nodes(at: coordinate)
            
            return candidateChildren.filter { child in
                return !types.contains {
                    $0 == child.dynamicType
                }
            }
        }
    }
    
    func excludingNodes<Node: WorldNode>(ofType type: Node.Type, at coordinate: Coordinate) -> [WorldNode] {
        return excludingNodes(ofTypes: [type], at: [coordinate])
    }
    
    // MARK: World Placement

    public func place(_ node: WorldNode, facing: Direction = .south, at coordinate: Coordinate) {
//            precondition(gridContains(coordinate), "Cannot place nodes outside of grid dimensions")
        
        // Search for the top contact to stack this node on.
        let baseHeight = height(at: coordinate)
        let position = coordinate.position
        node.position = SCNVector3(position.x, node.verticalOffset + baseHeight, position.z)
        node.rotation = facing.radians
        
        if isAnimated {
            add(command: .place([node]))
        }
        else {
            // Add the node directly to the world.
            add(node)
        }
    }
    
    /// Places a node of the specified type at the provided coordinates.
    @discardableResult
    public func place<Node: WorldNode where Node: LocationConstructible>(nodeOfType type: Node.Type, facing: Direction = .south, at coordinates: [Coordinate]) -> [Node] {
        
        var nodes = [Node]()
        for coordinate in coordinates {
            let node = type.init()
            place(node, facing: facing, at: coordinate)
            nodes.append(node)
        }
        
        return nodes
    }
    
    /// Places a bidirectional portal into the world.
    public func place(_ portal: Portal, between start: Coordinate, and end: Coordinate) {
        place(portal, at: start)
        
        let linkedPortal = Portal(color: portal.color)
        place(linkedPortal, at: end)
        
        // Link the portals together. 
        portal.linkedPortal = linkedPortal
    }
    
    // MARK: Node Removal
    
    public func remove(nodes: [WorldNode]) {
        if isAnimated {
            add(command: .remove(nodes))
        }
        else {
            // NOTE: This is called from WorldNode `removeFromWorld()` so the node needs to be accessed directly.
            for worldNode in nodes {
                worldNode.node.removeFromParentNode()
            }
        }
    }
    
    /// Removes all nodes at the provided coordinates leaving a big hole in your world.
    public func removeNodes(at coordinates: [Coordinate]) {
        for coordinate in coordinates {
            for node in grid.nodes(at: coordinate) {
                node.removeFromWorld()
            }
        }
    }
    
    public func removeNodes(at coordinate: Coordinate) {
        removeNodes(at: [coordinate])
    }
    
    func removeTop(at coordinate: Coordinate, fadeDuration: Double = 0.0) {
        
        let fadeOut = SCNAction.fadeOut(withDuration: fadeDuration)
        let sequence = SCNAction.sequence([fadeOut, .removeFromParentNode()])
        
        for node in hitNodes(containingName: "Top", at: coordinate) {
            node.run(sequence)
        }
        
        // Remove tops with other names
        for node in hitNodes(containingName: "zon_floor_", at: coordinate) {
            node.run(sequence)
        }
    }
    
    // MARK: Hit Testing
    
    func hitNodes(containingName nodeName: String, at coordinate: Coordinate) -> [SCNNode] {
        guard let rootNode = grid.node.anscestorNode(named: "rootNode") else { return [] }
        let positionInWorld = rootNode.convertPosition(coordinate.position, from: grid.node)
        
        // Probe slightly above and below the provided coordinate.
        var abovePosition = positionInWorld; abovePosition.y += 3
        var belowPosition = positionInWorld; belowPosition.y -= 3
        
        return rootNode.hitTestWithSegment(fromPoint: abovePosition, toPoint: belowPosition).flatMap { hit -> SCNNode? in
            let node = hit.node
            let name = node.name ?? ""
            
            if name.contains(nodeName) {
                return node
            }
            
            
            return node.childNode(withName: nodeName, recursively: true)
        }
    }

    // MARK: Helper
    
    /// Checks if the coordinate is within the grid `dimensions`.
    func gridContains(coordinate: Coordinate) -> Bool {
        let isWithinGrid = coordinate.column < columnCount && coordinate.row < rowCount
        return isWithinGrid
    }
    
    /// Provided as a convenience to make changes to the world while easily
    /// configuring if the changes should/should not be animated.
    func applyChanges(animated: Bool = false, within changes: @noescape () -> Void) {
        let animating = isAnimated
        isAnimated = animated
        
        changes()
        
        isAnimated = animating
    }
}

extension GridWorld {
    
    // MARK: Coordinates
    
    /// Returns all coordinates contained in the specified columns.
    public func coordinates(inColumns columns: [Int]) -> [Coordinate] {
        return coordinates(inColumns: columns, intersectingRows: 0..<rowCount)
    }
    
    /// Returns all coordinates contained in the specified rows.
    public func coordinates(inRows rows: [Int]) -> [Coordinate] {
        return coordinates(inColumns: 0..<columnCount, intersectingRows: rows)
    }
    
    /**
     Returns the coordinates within the intersection between the specified columns and rows.
     
     Example usage:
     coordinatesBetween([0], rows: 0...2) // Returns (0,0), (0,1), (0,2)
     coordinatesBetween([1, 2], rows: [0, 3]) // Returns (1,0), (2,0), (1, 3), (2,3)
     */
    public func coordinates<Rows: Sequence, Columns: Sequence where Rows.Iterator.Element == Int, Columns.Iterator.Element == Int >(inColumns columns: Columns, intersectingRows rows: Rows) -> [Coordinate] {
        
//        let columns = columns.filter { $0 >= 0 && $0 < columnCount }
//        let rows = rows.filter { $0 >= 0 && $0 < rowCount }
        
        return rows.flatMap { row -> [Coordinate] in
            return columns.map { column in
                Coordinate(column: column, row: row)
            }
        }
    }
    
    func height(at coordinate: Coordinate) -> SCNFloat {
        let nodes = grid.nodes(at: coordinate).flatMap { worldNode -> SCNNode? in
            if worldNode.isStackable {
                return worldNode.node
            }
            return nil
        }
        
        let topNode = nodes.max { n1, n2 in
            n1.position.y < n2.position.y
        }
        
        return topNode?.position.y ?? -WorldConfiguration.levelHeight
    }
}

extension GridWorld {
    
    // MARK: Convenience Methods
    
    /**
    Method that returns the gems present on an array of given coordinates.
    */
    public func existingGems(at coordinates: [Coordinate]) -> [Gem] {
        return existingNodes(ofType: Gem.self, at: coordinates)
    }
    
    // MARK: Mass Placement
    
    /**
    Method that places multiple blocks into the puzzle world using an array of coordinates.
    */
    @discardableResult
    public func placeBlocks(at coordinates: [Coordinate]) -> [Block] {
        return place(nodeOfType: Block.self, at: coordinates)
    }
    
    /**
    Method that places multiple water tiles into the puzzle world using an array of coordinates.
    */
    @discardableResult
    public func placeWater(at coordinates: [Coordinate]) -> [Water] {
        return place(nodeOfType: Water.self, at: coordinates)
    }
    
    /**
    Method that places multiple gems into the puzzle world using an array of coordinates.
    */
    @discardableResult
    public func placeGems(at coordinates: [Coordinate]) -> [Gem] {
        return place(nodeOfType: Gem.self, at: coordinates)
    }

    // MARK: Non-Coordinate placement
    
    /**
    Method that places an item into the puzzle world.
    */
    public func place(_ item: Item, facing: Direction = .south, atColumn column: Int, row: Int) {
        self.place(item, facing: facing, at: Coordinate(column: column, row: row))
    }
    
    /**
    Method that places a portal into the puzzle world.
    */
    public func place(_ portal: Portal, atStartColumn: Int, startRow: Int, atEndColumn: Int, endRow: Int) {
        self.place(portal, between: Coordinate(column: atStartColumn, row: startRow), and: Coordinate(column: atEndColumn, row: endRow))
    }
    
    /**
    Method that removes all items from a specific coordinate on the puzzle world.
    */
    public func removeItems(atColumn column: Int, row: Int)  {
        self.removeNodes(at: Coordinate(column: column, row: row))
    }
    
    // MARK:
    
    /**
    Method that returns the top block on a stack of block.
    */
    public func topBlock(at coordinate: Coordinate) -> Block? {
        return existingNodes(ofType: Block.self, at: [coordinate]).max { b1, b2 in
            b1.position.y < b2.position.y
        }
    }
}

// MARK: Commandable

extension GridWorld: Commandable, CommandCompletionDelegate {
    
    var id: Int {
        // 0 is reserved for the `GridWorld`. 
        return 0
    }
    
    func applyStateChange(for command: Command) {
        switch command {
        case .place(let nodes):
            for worldNode in nodes {                
                add(worldNode)
            }
            
        case .remove(let nodes):
            for worldNode in nodes {
                remove(worldNode)
            }
            
        default:
            break
        }
    }
    
    func perform(_ command: Command) {
        let duration: Double

        switch command {
        case .place(let nodes):
            duration = Double(0.4 / commandSpeed)

            for worldNode in nodes {
                // Add the node to the actual Grid. 
                add(worldNode)
                
                let node = worldNode.node
                node.run(worldNode.placeAction(withDuration: duration))
                
                // Percolate nodes up to ensure proper ordering.
                percolateNodes(at: worldNode.coordinate)
            }
            
        case .remove(let nodes):
            duration = Double(1.0 / commandSpeed)

            for worldNode in nodes {
                let node = worldNode.node
                
                let remove = worldNode.removeAction(withDuration: duration)
                node.run(.sequence([remove, .removeFromParentNode()]))
                
                // Mark the node as removed from the world so percolation can take place immediately.
                worldNode.world = nil
                percolateNodes(at: worldNode.coordinate)
            }
            
        default:
            duration = 0.0
            break
        }
        
        dispatch_after(seconds: duration + 0.1) {
            self.commandableFinished(self)
        }
    }
    
    func cancel(_ command: Command) {
        switch command {
        case .place(let nodes):
            for worldNode in nodes {
                worldNode.node.removeAllActions()
            }
            
        case .remove(let nodes):
            for worldNode in nodes {
                worldNode.node.removeAllActions()
            }
            
        default:
            break
        }
        
        // Complete the current command.
        commandQueue.applyStateAdvancingCurrentIndex()
    }
    
    /// Convenience to create an `CommandPerformer` by bundling in `self` with the provided command.
    func add(command: Command) {
        let performer = CommandPerformer(commandable: self, command: command)
        
        commandQueue.add(performer: performer, applyingState: true)
    }

    // MARK: CommandCompletionDelegate
    
    func commandableFinished(_ commandable: Commandable) {
        precondition(Thread.isMainThread())
        guard commandQueue.runMode == .continuous else { return }
        
        // Run the next command.
        commandQueue.runNextCommand()
    }
}

public let CriteriaAll = -1

public struct GridWorldSuccessCriteria {
    let collectedGems: Int
    let openedSwitches: Int
    
    public init() {
        self.init(gems: CriteriaAll, switches: CriteriaAll)
    }
    
    public init(gems: Int, switches: Int) {
        collectedGems = gems
        openedSwitches = switches
    }
}
