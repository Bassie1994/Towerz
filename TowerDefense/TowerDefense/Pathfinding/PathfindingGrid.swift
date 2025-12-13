import SpriteKit

/// Manages the walkability grid for pathfinding
/// Ground units must navigate around blocked cells (towers)
/// Flying units ignore blocking
final class PathfindingGrid {
    let width: Int
    let height: Int
    
    // Walkability data: true = walkable, false = blocked
    private var walkable: [[Bool]]
    
    // Track tower positions for quick lookup
    private var towerPositions: Set<GridPosition> = []
    
    // Cached flow field (invalidated when grid changes)
    private var cachedFlowField: FlowField?
    private var flowFieldDirty = true
    
    // Exit positions (right side of the map)
    private(set) var exitPositions: [GridPosition] = []
    
    // Spawn positions (left side of the map)
    private(set) var spawnPositions: [GridPosition] = []
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        
        // Initialize all cells as walkable
        self.walkable = Array(repeating: Array(repeating: true, count: height), count: width)
        
        // Setup spawn and exit positions
        setupZones()
    }
    
    private func setupZones() {
        // Spawn zone: leftmost columns
        for y in 0..<height {
            for x in 0..<GameConstants.spawnZoneWidth {
                spawnPositions.append(GridPosition(x: x, y: y))
            }
        }
        
        // Exit zone: bottom-right corner (last 2 columns, bottom 4 rows)
        for y in 0..<4 {  // Bottom 4 rows only
            for x in (width - GameConstants.exitZoneWidth)..<width {
                exitPositions.append(GridPosition(x: x, y: y))
            }
        }
    }
    
    // MARK: - Query Methods
    
    func isWalkable(_ position: GridPosition) -> Bool {
        guard isValidPosition(position) else { return false }
        return walkable[position.x][position.y]
    }
    
    func isValidPosition(_ position: GridPosition) -> Bool {
        return position.x >= 0 && position.x < width &&
               position.y >= 0 && position.y < height
    }
    
    func hasTower(at position: GridPosition) -> Bool {
        return towerPositions.contains(position)
    }
    
    // MARK: - Modification Methods
    
    func blockCell(_ position: GridPosition) {
        guard isValidPosition(position) else { return }
        walkable[position.x][position.y] = false
        towerPositions.insert(position)
        invalidateFlowField()
    }
    
    func unblockCell(_ position: GridPosition) {
        guard isValidPosition(position) else { return }
        walkable[position.x][position.y] = true
        towerPositions.remove(position)
        invalidateFlowField()
    }
    
    /// Temporarily block a cell to test if path still exists
    func testBlockCell(_ position: GridPosition) -> Bool {
        guard isValidPosition(position) else { return false }
        
        // Temporarily block
        let wasWalkable = walkable[position.x][position.y]
        walkable[position.x][position.y] = false
        
        // Test if any spawn can reach any exit
        let pathExists = canReachExitFromAnySpawn()
        
        // Restore
        walkable[position.x][position.y] = wasWalkable
        
        return pathExists
    }
    
    // MARK: - Path Existence Check
    
    func canReachExitFromAnySpawn() -> Bool {
        // Use BFS from exits backwards to check if any spawn is reachable
        var visited = Set<GridPosition>()
        var queue: [GridPosition] = []
        
        // Start from all exit positions
        for exit in exitPositions {
            queue.append(exit)
            visited.insert(exit)
        }
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            // Check if we reached any spawn position
            if current.isInSpawnZone() {
                return true
            }
            
            // Explore neighbors
            for neighbor in current.neighbors(in: self) {
                if !visited.contains(neighbor) && isWalkable(neighbor) {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
        
        return false
    }
    
    /// Check if a specific spawn can reach the exit
    func canReachExit(from spawnPosition: GridPosition) -> Bool {
        guard let flowField = getFlowField() else { return false }
        return flowField.hasPath(from: spawnPosition)
    }
    
    // MARK: - Flow Field Management
    
    func getFlowField() -> FlowField? {
        if flowFieldDirty {
            cachedFlowField = FlowField(grid: self)
            flowFieldDirty = false
        }
        return cachedFlowField
    }
    
    func invalidateFlowField() {
        flowFieldDirty = true
    }
    
    // MARK: - Utility
    
    func getRandomSpawnPosition() -> GridPosition? {
        return spawnPositions.randomElement()
    }
    
    func getAllTowerPositions() -> Set<GridPosition> {
        return towerPositions
    }
    
    /// Debug visualization
    func debugDescription() -> String {
        var result = ""
        for y in (0..<height).reversed() {
            for x in 0..<width {
                let pos = GridPosition(x: x, y: y)
                if pos.isInSpawnZone() {
                    result += "S"
                } else if pos.isInExitZone() {
                    result += "E"
                } else if !isWalkable(pos) {
                    result += "#"
                } else {
                    result += "."
                }
            }
            result += "\n"
        }
        return result
    }
}
