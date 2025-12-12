import Foundation

/// A* Pathfinding implementation
/// Used for individual path queries and validation
final class AStarPathfinder {
    
    private struct PathNode: Comparable {
        let position: GridPosition
        let gCost: Int  // Cost from start
        let hCost: Int  // Heuristic cost to end
        let parent: GridPosition?
        
        var fCost: Int { gCost + hCost }
        
        static func < (lhs: PathNode, rhs: PathNode) -> Bool {
            if lhs.fCost == rhs.fCost {
                return lhs.hCost < rhs.hCost
            }
            return lhs.fCost < rhs.fCost
        }
        
        static func == (lhs: PathNode, rhs: PathNode) -> Bool {
            return lhs.position == rhs.position
        }
    }
    
    private let grid: PathfindingGrid
    
    init(grid: PathfindingGrid) {
        self.grid = grid
    }
    
    /// Find path from start to any exit position
    func findPathToExit(from start: GridPosition) -> [GridPosition]? {
        // Find the closest exit
        let exits = grid.exitPositions
        guard !exits.isEmpty else { return nil }
        
        // Use the center exit as target (others are also valid endpoints)
        let targetY = grid.height / 2
        let targetX = grid.width - 1
        let target = GridPosition(x: targetX, y: targetY)
        
        return findPath(from: start, to: target, allowNearbyGoal: true)
    }
    
    /// Find path between two specific positions
    func findPath(from start: GridPosition, to end: GridPosition, allowNearbyGoal: Bool = false) -> [GridPosition]? {
        guard grid.isValidPosition(start) && grid.isValidPosition(end) else {
            return nil
        }
        
        // Priority queue (using array with insertion sort for simplicity)
        var openList: [PathNode] = []
        var closedSet = Set<GridPosition>()
        var nodeMap: [GridPosition: PathNode] = [:]
        
        let startNode = PathNode(
            position: start,
            gCost: 0,
            hCost: heuristic(from: start, to: end),
            parent: nil
        )
        
        openList.append(startNode)
        nodeMap[start] = startNode
        
        while !openList.isEmpty {
            // Get node with lowest fCost
            openList.sort()
            let currentNode = openList.removeFirst()
            let current = currentNode.position
            
            // Check if we reached the goal
            if current == end || (allowNearbyGoal && current.isInExitZone()) {
                return reconstructPath(from: currentNode, nodeMap: nodeMap)
            }
            
            closedSet.insert(current)
            
            // Explore neighbors
            for neighbor in current.neighbors(in: grid) {
                if closedSet.contains(neighbor) {
                    continue
                }
                
                // Skip blocked cells (unless it's the exit zone)
                if !grid.isWalkable(neighbor) && !neighbor.isInExitZone() {
                    continue
                }
                
                let tentativeGCost = currentNode.gCost + 1
                
                if let existingNode = nodeMap[neighbor] {
                    if tentativeGCost < existingNode.gCost {
                        // Found better path, update
                        let newNode = PathNode(
                            position: neighbor,
                            gCost: tentativeGCost,
                            hCost: existingNode.hCost,
                            parent: current
                        )
                        nodeMap[neighbor] = newNode
                        
                        // Update in open list
                        if let index = openList.firstIndex(where: { $0.position == neighbor }) {
                            openList[index] = newNode
                        }
                    }
                } else {
                    // New node
                    let newNode = PathNode(
                        position: neighbor,
                        gCost: tentativeGCost,
                        hCost: heuristic(from: neighbor, to: end),
                        parent: current
                    )
                    nodeMap[neighbor] = newNode
                    openList.append(newNode)
                }
            }
        }
        
        return nil // No path found
    }
    
    /// Manhattan distance heuristic
    private func heuristic(from: GridPosition, to: GridPosition) -> Int {
        return abs(from.x - to.x) + abs(from.y - to.y)
    }
    
    /// Reconstruct path from end node
    private func reconstructPath(from endNode: PathNode, nodeMap: [GridPosition: PathNode]) -> [GridPosition] {
        var path: [GridPosition] = []
        var current: GridPosition? = endNode.position
        
        while let pos = current {
            path.insert(pos, at: 0)
            current = nodeMap[pos]?.parent
        }
        
        return path
    }
    
    /// Check if path exists (faster than finding full path)
    func pathExists(from start: GridPosition, to end: GridPosition) -> Bool {
        // Use BFS for existence check (faster than A* for this purpose)
        guard grid.isValidPosition(start) && grid.isValidPosition(end) else {
            return false
        }
        
        var visited = Set<GridPosition>()
        var queue: [GridPosition] = [start]
        visited.insert(start)
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            if current == end || (current.isInExitZone() && end.isInExitZone()) {
                return true
            }
            
            for neighbor in current.neighbors(in: grid) {
                if !visited.contains(neighbor) && (grid.isWalkable(neighbor) || neighbor.isInExitZone()) {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
        
        return false
    }
}
