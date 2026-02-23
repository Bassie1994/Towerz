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

    struct ZoneValidationResult {
        let isValid: Bool
        let issues: [String]

        var message: String {
            issues.isEmpty ? "OK" : issues.joined(separator: "; ")
        }
    }

    /// Pure helper for validating zone constants against grid size.
    /// This can be reused in tests to guard against future layout regressions.
    static func validateZoneDefinitions(
        width: Int,
        height: Int,
        spawnZoneWidth: Int,
        spawnZoneHeight: Int,
        exitZoneWidth: Int,
        exitZoneHeight: Int
    ) -> ZoneValidationResult {
        var issues: [String] = []

        if width <= 0 || height <= 0 {
            issues.append("Grid dimensions must be positive")
        }

        if spawnZoneWidth <= 0 || spawnZoneHeight <= 0 {
            issues.append("Spawn zone dimensions must be positive")
        }
        if exitZoneWidth <= 0 || exitZoneHeight <= 0 {
            issues.append("Exit zone dimensions must be positive")
        }

        if spawnZoneWidth > width || spawnZoneHeight > height {
            issues.append("Spawn zone exceeds grid bounds")
        }
        if exitZoneWidth > width || exitZoneHeight > height {
            issues.append("Exit zone exceeds grid bounds")
        }

        if issues.isEmpty {
            let spawnXRange = 0..<spawnZoneWidth
            let spawnYRange = (height - spawnZoneHeight)..<height
            let exitXRange = (width - exitZoneWidth)..<width
            let exitYRange = 0..<exitZoneHeight
            let zonesOverlap = spawnXRange.overlaps(exitXRange) && spawnYRange.overlaps(exitYRange)
            if zonesOverlap {
                issues.append("Spawn and exit zones overlap")
            }
        }

        return ZoneValidationResult(isValid: issues.isEmpty, issues: issues)
    }
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height

        let zoneValidation = PathfindingGrid.validateZoneDefinitions(
            width: width,
            height: height,
            spawnZoneWidth: GameConstants.spawnZoneWidth,
            spawnZoneHeight: GameConstants.spawnZoneHeight,
            exitZoneWidth: GameConstants.exitZoneWidth,
            exitZoneHeight: GameConstants.exitZoneHeight
        )
        assert(zoneValidation.isValid, "Invalid pathfinding zone definitions: \(zoneValidation.message)")
        if !zoneValidation.isValid {
            print("PathfindingGrid warning: \(zoneValidation.message)")
        }
        
        // Initialize all cells as walkable
        self.walkable = Array(repeating: Array(repeating: true, count: height), count: width)
        
        // Setup spawn and exit positions
        setupZones()

        let expectedSpawnCount = GameConstants.spawnZoneWidth * GameConstants.spawnZoneHeight
        let expectedExitCount = GameConstants.exitZoneWidth * GameConstants.exitZoneHeight
        assert(spawnPositions.count == expectedSpawnCount, "Spawn zone cell count mismatch")
        assert(exitPositions.count == expectedExitCount, "Exit zone cell count mismatch")
    }
    
    private func setupZones() {
        // Spawn zone: top-left corner (first N columns, top M rows)
        let spawnMinY = max(0, height - GameConstants.spawnZoneHeight)
        for y in spawnMinY..<height {
            for x in 0..<GameConstants.spawnZoneWidth {
                spawnPositions.append(GridPosition(x: x, y: y))
            }
        }
        
        // Exit zone: bottom-right corner (last N columns, bottom M rows)
        for y in 0..<GameConstants.exitZoneHeight {
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
