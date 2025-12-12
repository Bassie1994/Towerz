import SpriteKit

/// Result of placement validation
struct PlacementValidationResult {
    let isValid: Bool
    let reason: String?
    let gridPosition: GridPosition
    
    static func valid(at position: GridPosition) -> PlacementValidationResult {
        return PlacementValidationResult(isValid: true, reason: nil, gridPosition: position)
    }
    
    static func invalid(at position: GridPosition, reason: String) -> PlacementValidationResult {
        return PlacementValidationResult(isValid: false, reason: reason, gridPosition: position)
    }
}

/// Validates tower placement
final class PlacementValidator {
    
    private let grid: PathfindingGrid
    private let pathfinder: AStarPathfinder
    
    init(grid: PathfindingGrid) {
        self.grid = grid
        self.pathfinder = AStarPathfinder(grid: grid)
    }
    
    /// Validate if a tower can be placed at the given world position
    func validate(worldPosition: CGPoint, towerType: TowerType) -> PlacementValidationResult {
        let gridPos = worldPosition.toGridPosition()
        return validate(gridPosition: gridPos, towerType: towerType)
    }
    
    /// Validate if a tower can be placed at the given grid position
    func validate(gridPosition: GridPosition, towerType: TowerType) -> PlacementValidationResult {
        // Check 1: Position is within grid bounds
        guard grid.isValidPosition(gridPosition) else {
            return .invalid(at: gridPosition, reason: "Outside play area")
        }
        
        // Check 2: Not in spawn zone
        if gridPosition.isInSpawnZone() {
            return .invalid(at: gridPosition, reason: "Cannot place in spawn zone")
        }
        
        // Check 3: Not in exit zone
        if gridPosition.isInExitZone() {
            return .invalid(at: gridPosition, reason: "Cannot place in exit zone")
        }
        
        // Check 4: Cell is not already occupied
        if grid.hasTower(at: gridPosition) {
            return .invalid(at: gridPosition, reason: "Cell already occupied")
        }
        
        // Check 5: Cell is currently walkable
        if !grid.isWalkable(gridPosition) {
            return .invalid(at: gridPosition, reason: "Cell is blocked")
        }
        
        // Check 6: Placement would not block all paths
        // This is the critical check - we need to ensure enemies can still reach the exit
        if !grid.testBlockCell(gridPosition) {
            return .invalid(at: gridPosition, reason: "Would block all paths!")
        }
        
        // All checks passed
        return .valid(at: gridPosition)
    }
    
    /// Check if placement at position would create a valid maze
    /// More thorough check that validates multiple spawn points
    func validatePathIntegrity(afterPlacingAt gridPosition: GridPosition) -> Bool {
        // Temporarily block the cell
        grid.blockCell(gridPosition)
        
        // Check if path exists from multiple spawn points
        var pathExists = false
        
        for spawnPos in grid.spawnPositions {
            if grid.canReachExit(from: spawnPos) {
                pathExists = true
                break
            }
        }
        
        // Restore the cell
        grid.unblockCell(gridPosition)
        
        return pathExists
    }
    
    /// Get all valid placement positions (for UI highlighting)
    func getAllValidPositions() -> [GridPosition] {
        var validPositions: [GridPosition] = []
        
        for x in GameConstants.spawnZoneWidth..<(GameConstants.gridWidth - GameConstants.exitZoneWidth) {
            for y in 0..<GameConstants.gridHeight {
                let pos = GridPosition(x: x, y: y)
                if validate(gridPosition: pos, towerType: .machineGun).isValid {
                    validPositions.append(pos)
                }
            }
        }
        
        return validPositions
    }
    
    /// Snap world position to nearest valid grid position
    func snapToGrid(worldPosition: CGPoint) -> GridPosition {
        var gridX = Int((worldPosition.x - GameConstants.playFieldOrigin.x) / GameConstants.cellSize)
        var gridY = Int((worldPosition.y - GameConstants.playFieldOrigin.y) / GameConstants.cellSize)
        
        // Clamp to valid range
        gridX = max(0, min(GameConstants.gridWidth - 1, gridX))
        gridY = max(0, min(GameConstants.gridHeight - 1, gridY))
        
        return GridPosition(x: gridX, y: gridY)
    }
    
    /// Check if a world position is within the playable area
    func isInPlayableArea(worldPosition: CGPoint) -> Bool {
        let minX = GameConstants.playFieldOrigin.x
        let maxX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width
        let minY = GameConstants.playFieldOrigin.y
        let maxY = GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height
        
        return worldPosition.x >= minX && worldPosition.x <= maxX &&
               worldPosition.y >= minY && worldPosition.y <= maxY
    }
}
