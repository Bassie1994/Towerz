import SpriteKit

/// Flow Field for efficient many-to-one pathfinding
/// All ground units use this to navigate toward the exit
/// Recalculated when grid changes (tower placed/removed)
final class FlowField {
    
    private let grid: PathfindingGrid
    
    // Distance from each cell to the nearest exit
    private var distanceField: [[Int]]
    
    // Direction to move from each cell (toward exit)
    private var directionField: [[CGVector?]]
    
    // Maximum distance value (unreachable)
    private let maxDistance = Int.max / 2
    
    init(grid: PathfindingGrid) {
        self.grid = grid
        
        // Initialize fields
        distanceField = Array(
            repeating: Array(repeating: maxDistance, count: grid.height),
            count: grid.width
        )
        directionField = Array(
            repeating: Array(repeating: nil, count: grid.height),
            count: grid.width
        )
        
        // Calculate flow field
        calculateDistanceField()
        calculateDirectionField()
    }
    
    // MARK: - Field Calculation
    
    private func calculateDistanceField() {
        // BFS from all exit positions
        var queue: [GridPosition] = []
        
        // Initialize exits with distance 0
        for exit in grid.exitPositions {
            distanceField[exit.x][exit.y] = 0
            queue.append(exit)
        }
        
        // BFS to calculate distances
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let currentDistance = distanceField[current.x][current.y]
            
            for neighbor in current.neighbors(in: grid) {
                // Skip blocked cells
                guard grid.isWalkable(neighbor) || neighbor.isInExitZone() else {
                    continue
                }
                
                let newDistance = currentDistance + 1
                
                if newDistance < distanceField[neighbor.x][neighbor.y] {
                    distanceField[neighbor.x][neighbor.y] = newDistance
                    queue.append(neighbor)
                }
            }
        }
    }
    
    private func calculateDirectionField() {
        for x in 0..<grid.width {
            for y in 0..<grid.height {
                let pos = GridPosition(x: x, y: y)
                
                // Skip exit positions (no direction needed)
                if pos.isInExitZone() {
                    directionField[x][y] = CGVector(dx: 1, dy: 0) // Move right to exit
                    continue
                }
                
                // Skip unreachable cells
                if distanceField[x][y] >= maxDistance {
                    continue
                }
                
                // Find neighbor with lowest distance
                var bestDirection: CGVector?
                var bestDistance = distanceField[x][y]
                
                // Check cardinal directions
                let directions: [(Int, Int, CGVector)] = [
                    (1, 0, CGVector(dx: 1, dy: 0)),   // Right
                    (-1, 0, CGVector(dx: -1, dy: 0)), // Left
                    (0, 1, CGVector(dx: 0, dy: 1)),   // Up
                    (0, -1, CGVector(dx: 0, dy: -1))  // Down
                ]
                
                for (dx, dy, dir) in directions {
                    let nx = x + dx
                    let ny = y + dy
                    
                    guard nx >= 0 && nx < grid.width && ny >= 0 && ny < grid.height else {
                        continue
                    }
                    
                    let neighborDistance = distanceField[nx][ny]
                    if neighborDistance < bestDistance {
                        bestDistance = neighborDistance
                        bestDirection = dir
                    }
                }
                
                // Also check diagonals for smoother movement
                let diagonals: [(Int, Int, CGVector)] = [
                    (1, 1, CGVector(dx: 0.707, dy: 0.707)),
                    (1, -1, CGVector(dx: 0.707, dy: -0.707)),
                    (-1, 1, CGVector(dx: -0.707, dy: 0.707)),
                    (-1, -1, CGVector(dx: -0.707, dy: -0.707))
                ]
                
                for (dx, dy, dir) in diagonals {
                    let nx = x + dx
                    let ny = y + dy
                    
                    guard nx >= 0 && nx < grid.width && ny >= 0 && ny < grid.height else {
                        continue
                    }
                    
                    // Diagonal movement requires both adjacent cells to be walkable
                    let adj1Walkable = grid.isWalkable(GridPosition(x: x + dx, y: y))
                    let adj2Walkable = grid.isWalkable(GridPosition(x: x, y: y + dy))
                    
                    if !adj1Walkable || !adj2Walkable {
                        continue
                    }
                    
                    let neighborDistance = distanceField[nx][ny]
                    // Diagonal has slightly higher cost (1.4 vs 1.0)
                    if neighborDistance < bestDistance - 1 {
                        bestDistance = neighborDistance
                        bestDirection = dir
                    }
                }
                
                directionField[x][y] = bestDirection
            }
        }
    }
    
    // MARK: - Query Methods
    
    /// Get direction to move from a world position
    func getDirection(at worldPosition: CGPoint) -> CGVector? {
        let gridPos = worldPosition.toGridPosition()
        return getDirection(at: gridPos)
    }
    
    /// Get direction to move from a grid position
    func getDirection(at position: GridPosition) -> CGVector? {
        guard grid.isValidPosition(position) else { return nil }
        return directionField[position.x][position.y]
    }
    
    /// Get interpolated direction for smoother movement
    func getInterpolatedDirection(at worldPosition: CGPoint) -> CGVector? {
        let gridPos = worldPosition.toGridPosition()
        
        // Get cell-local position (0-1)
        let cellX = (worldPosition.x - GameConstants.playFieldOrigin.x) / GameConstants.cellSize
        let cellY = (worldPosition.y - GameConstants.playFieldOrigin.y) / GameConstants.cellSize
        let localX = cellX - floor(cellX)
        let localY = cellY - floor(cellY)
        
        // Sample four corners
        let positions = [
            GridPosition(x: gridPos.x, y: gridPos.y),
            GridPosition(x: gridPos.x + 1, y: gridPos.y),
            GridPosition(x: gridPos.x, y: gridPos.y + 1),
            GridPosition(x: gridPos.x + 1, y: gridPos.y + 1)
        ]
        
        var totalDx: CGFloat = 0
        var totalDy: CGFloat = 0
        var count: CGFloat = 0
        
        let weights = [
            (1 - localX) * (1 - localY),
            localX * (1 - localY),
            (1 - localX) * localY,
            localX * localY
        ]
        
        for (i, pos) in positions.enumerated() {
            if let dir = getDirection(at: pos) {
                let weight = weights[i]
                totalDx += dir.dx * weight
                totalDy += dir.dy * weight
                count += weight
            }
        }
        
        guard count > 0 else { return getDirection(at: gridPos) }
        
        let result = CGVector(dx: totalDx / count, dy: totalDy / count)
        return result.normalized()
    }
    
    /// Get distance to exit from a position
    func getDistance(at position: GridPosition) -> Int {
        guard grid.isValidPosition(position) else { return maxDistance }
        return distanceField[position.x][position.y]
    }
    
    /// Check if a position has a valid path to exit
    func hasPath(from position: GridPosition) -> Bool {
        guard grid.isValidPosition(position) else { return false }
        return distanceField[position.x][position.y] < maxDistance
    }
    
    /// Check if position is at exit
    func isAtExit(_ position: GridPosition) -> Bool {
        return position.isInExitZone()
    }
    
    /// Debug visualization
    func createDebugVisualization(parent: SKNode) {
        for x in 0..<grid.width {
            for y in 0..<grid.height {
                let pos = GridPosition(x: x, y: y)
                let worldPos = pos.toWorldPosition()
                
                if let direction = directionField[x][y] {
                    // Draw arrow
                    let arrow = SKShapeNode()
                    let path = CGMutablePath()
                    path.move(to: CGPoint(x: -10, y: 0))
                    path.addLine(to: CGPoint(x: 10, y: 0))
                    path.addLine(to: CGPoint(x: 5, y: 3))
                    path.move(to: CGPoint(x: 10, y: 0))
                    path.addLine(to: CGPoint(x: 5, y: -3))
                    arrow.path = path
                    arrow.strokeColor = .yellow
                    arrow.lineWidth = 1
                    arrow.position = worldPos
                    arrow.zRotation = atan2(direction.dy, direction.dx)
                    arrow.alpha = 0.3
                    arrow.zPosition = GameConstants.ZPosition.grid.rawValue
                    parent.addChild(arrow)
                }
            }
        }
    }
}
