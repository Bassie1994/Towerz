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
                    directionField[x][y] = CGVector(dx: 1, dy: -1).normalized() // Move to bottom-right
                    continue
                }
                
                // Skip unreachable cells
                if distanceField[x][y] >= maxDistance {
                    continue
                }
                
                // Use gradient-based direction for smoother pathing
                // Sample all 8 neighbors and compute weighted direction
                var totalDx: CGFloat = 0
                var totalDy: CGFloat = 0
                let currentDist = distanceField[x][y]
                
                // All 8 directions with their offsets
                let allDirections: [(dx: Int, dy: Int, weight: CGFloat)] = [
                    (1, 0, 1.0),    // Right
                    (-1, 0, 1.0),   // Left
                    (0, 1, 1.0),    // Up
                    (0, -1, 1.0),   // Down
                    (1, 1, 0.707),  // Diagonal (weighted less)
                    (1, -1, 0.707),
                    (-1, 1, 0.707),
                    (-1, -1, 0.707)
                ]
                
                for (dx, dy, weight) in allDirections {
                    let nx = x + dx
                    let ny = y + dy
                    
                    guard nx >= 0 && nx < grid.width && ny >= 0 && ny < grid.height else {
                        continue
                    }
                    
                    // For diagonals, check that adjacent cells are walkable
                    if abs(dx) == 1 && abs(dy) == 1 {
                        let adj1 = GridPosition(x: x + dx, y: y)
                        let adj2 = GridPosition(x: x, y: y + dy)
                        if !grid.isWalkable(adj1) || !grid.isWalkable(adj2) {
                            continue
                        }
                    }
                    
                    let neighborDist = distanceField[nx][ny]
                    
                    // Only consider cells that bring us closer to goal
                    if neighborDist < currentDist {
                        // Weight by how much closer this cell is
                        let improvement = CGFloat(currentDist - neighborDist)
                        totalDx += CGFloat(dx) * improvement * weight
                        totalDy += CGFloat(dy) * improvement * weight
                    }
                }
                
                // Normalize the direction
                let length = sqrt(totalDx * totalDx + totalDy * totalDy)
                if length > 0 {
                    directionField[x][y] = CGVector(dx: totalDx / length, dy: totalDy / length)
                } else {
                    // Fallback: find any neighbor with lower distance
                    for (dx, dy, _) in allDirections {
                        let nx = x + dx
                        let ny = y + dy
                        guard nx >= 0 && nx < grid.width && ny >= 0 && ny < grid.height else { continue }
                        if distanceField[nx][ny] < currentDist {
                            let len = sqrt(CGFloat(dx * dx + dy * dy))
                            directionField[x][y] = CGVector(dx: CGFloat(dx) / len, dy: CGFloat(dy) / len)
                            break
                        }
                    }
                }
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
        // Safety: check for valid world position
        guard !worldPosition.x.isNaN && !worldPosition.y.isNaN else {
            return CGVector(dx: 1, dy: 0)
        }
        
        let gridPos = worldPosition.toGridPosition()
        
        // Safety: if base position is out of bounds, return simple direction
        guard gridPos.x >= 0 && gridPos.x < grid.width &&
              gridPos.y >= 0 && gridPos.y < grid.height else {
            return CGVector(dx: 1, dy: -0.5).normalized()
        }
        
        // If current cell has no direction (blocked), return nil
        guard let currentDir = getDirection(at: gridPos) else {
            // Try to find escape direction from blocked cell
            return findEscapeDirection(from: gridPos)
        }
        
        // Get cell-local position (0-1)
        let cellX = (worldPosition.x - GameConstants.playFieldOrigin.x) / GameConstants.cellSize
        let cellY = (worldPosition.y - GameConstants.playFieldOrigin.y) / GameConstants.cellSize
        let localX = max(0, min(1, cellX - floor(cellX)))
        let localY = max(0, min(1, cellY - floor(cellY)))
        
        // Only interpolate with walkable neighbors
        var totalDx: CGFloat = 0
        var totalDy: CGFloat = 0
        var totalWeight: CGFloat = 0
        
        let offsets = [(0, 0), (1, 0), (0, 1), (1, 1)]
        let weights = [
            (1 - localX) * (1 - localY),
            localX * (1 - localY),
            (1 - localX) * localY,
            localX * localY
        ]
        
        for (i, offset) in offsets.enumerated() {
            let pos = GridPosition(x: gridPos.x + offset.0, y: gridPos.y + offset.1)
            // Only include if walkable or in spawn/exit zone
            if let dir = getDirection(at: pos) {
                let weight = weights[i]
                totalDx += dir.dx * weight
                totalDy += dir.dy * weight
                totalWeight += weight
            }
        }
        
        // If no valid neighbors, use current cell direction
        guard totalWeight > 0.1 else { 
            return currentDir
        }
        
        let result = CGVector(dx: totalDx / totalWeight, dy: totalDy / totalWeight)
        let length = sqrt(result.dx * result.dx + result.dy * result.dy)
        
        guard length > 0.01 else {
            return currentDir
        }
        
        return CGVector(dx: result.dx / length, dy: result.dy / length)
    }
    
    /// Find direction to escape from a blocked cell
    private func findEscapeDirection(from pos: GridPosition) -> CGVector? {
        let directions = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        
        var bestDir: CGVector?
        var bestDist = Int.max
        
        for (dx, dy) in directions {
            let neighbor = GridPosition(x: pos.x + dx, y: pos.y + dy)
            guard neighbor.x >= 0 && neighbor.x < grid.width &&
                  neighbor.y >= 0 && neighbor.y < grid.height else { continue }
            
            let dist = distanceField[neighbor.x][neighbor.y]
            if dist < bestDist && dist < maxDistance {
                bestDist = dist
                let len = sqrt(CGFloat(dx * dx + dy * dy))
                bestDir = CGVector(dx: CGFloat(dx) / len, dy: CGFloat(dy) / len)
            }
        }
        
        return bestDir
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
