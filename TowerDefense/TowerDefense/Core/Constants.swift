import SpriteKit

// MARK: - Game Constants
enum GameConstants {
    // Field dimensions (in grid cells)
    static let gridWidth = 24
    static let gridHeight = 11
    static let cellSize: CGFloat = 48
    
    // Playfield bounds (adjusted for UI padding) - moved up for better visibility
    static let playFieldOrigin = CGPoint(x: 100, y: 110)
    static let playFieldSize = CGSize(
        width: CGFloat(gridWidth) * cellSize,
        height: CGFloat(gridHeight) * cellSize
    )
    
    // Spawn zone: top-left corner (2 columns x 4 rows)
    static let spawnZoneWidth: Int = 2
    static let spawnZoneHeight: Int = 4
    
    // Exit zone: bottom-right corner (2 columns x 4 rows)  
    static let exitZoneWidth: Int = 2
    static let exitZoneHeight: Int = 4
    
    // Starting resources
    static let startingLives = 20
    static let startingMoney = 500
    
    // Z-positions for layering
    enum ZPosition: CGFloat {
        case background = 0
        case grid = 1
        case tower = 10
        case enemy = 20
        case projectile = 30
        case effects = 40
        case rangeIndicator = 50
        case ui = 100
        case hud = 200
        case menu = 300
    }
}

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32 = 0
    static let enemy: UInt32 = 0x1 << 0
    static let tower: UInt32 = 0x1 << 1
    static let projectile: UInt32 = 0x1 << 2
    static let ground: UInt32 = 0x1 << 3
}

// MARK: - Enemy Types
enum EnemyType: String, CaseIterable, Codable {
    case infantry
    case cavalry
    case flying
    case shielded
    case support
    case boss
    
    var displayName: String {
        switch self {
        case .infantry: return "Infantry"
        case .cavalry: return "Cavalry"
        case .flying: return "Flying"
        case .shielded: return "Shielded"
        case .support: return "Support"
        case .boss: return "BOSS"
        }
    }
    
    var color: SKColor {
        switch self {
        case .infantry: return .green
        case .cavalry: return .orange
        case .flying: return .cyan
        case .shielded: return SKColor(red: 0.25, green: 0.7, blue: 0.95, alpha: 1.0)
        case .support: return SKColor(red: 0.7, green: 0.4, blue: 0.95, alpha: 1.0)
        case .boss: return SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        }
    }
    
    var isFlying: Bool {
        return self == .flying
    }
}

// MARK: - Tower Types
enum TowerType: String, CaseIterable {
    case wall       // Cheap blocker, can convert to other towers
    case machineGun
    case cannon
    case slow
    case buff
    case mine       // Was shotgun - now places mines that explode
    case splash
    case laser
    case antiAir
    
    var displayName: String {
        switch self {
        case .wall: return "Wall"
        case .machineGun: return "MG"
        case .cannon: return "Cannon"
        case .slow: return "Slow"
        case .buff: return "Buff"
        case .mine: return "Mine"
        case .splash: return "Splash"
        case .laser: return "Sniper"
        case .antiAir: return "AA"
        }
    }
    
    var color: SKColor {
        switch self {
        case .wall: return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        case .machineGun: return SKColor(red: 0.3, green: 0.3, blue: 0.8, alpha: 1.0)
        case .cannon: return SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .slow: return SKColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
        case .buff: return SKColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        case .mine: return SKColor(red: 0.5, green: 0.35, blue: 0.25, alpha: 1.0)  // Brown for mine
        case .splash: return SKColor(red: 0.8, green: 0.4, blue: 0.6, alpha: 1.0)
        case .laser: return SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        case .antiAir: return SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        }
    }
    
    var baseCost: Int {
        switch self {
        case .wall: return 5        // Very cheap blocking
        case .machineGun: return 25
        case .cannon: return 40
        case .slow: return 30
        case .buff: return 50
        case .mine: return 35       // Mine layer
        case .splash: return 45
        case .laser: return 60
        case .antiAir: return 38
        }
    }
}

// MARK: - Game State
enum GameState {
    case preparing
    case playing
    case paused
    case gameOver
    case victory
}

// MARK: - Placement State
enum PlacementState {
    case none
    case selecting(TowerType)
    case placing(TowerType, GridPosition)
    case invalid(TowerType, GridPosition, String)
}

// MARK: - Grid Position
struct GridPosition: Hashable, Equatable {
    let x: Int
    let y: Int
    
    static let zero = GridPosition(x: 0, y: 0)
    
    func distance(to other: GridPosition) -> Int {
        return abs(x - other.x) + abs(y - other.y)
    }
    
    func neighbors(in grid: PathfindingGrid) -> [GridPosition] {
        var result: [GridPosition] = []
        let deltas = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        
        for (dx, dy) in deltas {
            let newX = x + dx
            let newY = y + dy
            if newX >= 0 && newX < grid.width && newY >= 0 && newY < grid.height {
                result.append(GridPosition(x: newX, y: newY))
            }
        }
        return result
    }
    
    func diagonalNeighbors(in grid: PathfindingGrid) -> [GridPosition] {
        var result: [GridPosition] = []
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let newX = x + dx
                let newY = y + dy
                if newX >= 0 && newX < grid.width && newY >= 0 && newY < grid.height {
                    result.append(GridPosition(x: newX, y: newY))
                }
            }
        }
        return result
    }
}

// MARK: - Direction
enum Direction: CaseIterable {
    case up, down, left, right
    case upLeft, upRight, downLeft, downRight
    
    var vector: CGVector {
        switch self {
        case .up: return CGVector(dx: 0, dy: 1)
        case .down: return CGVector(dx: 0, dy: -1)
        case .left: return CGVector(dx: -1, dy: 0)
        case .right: return CGVector(dx: 1, dy: 0)
        case .upLeft: return CGVector(dx: -0.707, dy: 0.707)
        case .upRight: return CGVector(dx: 0.707, dy: 0.707)
        case .downLeft: return CGVector(dx: -0.707, dy: -0.707)
        case .downRight: return CGVector(dx: 0.707, dy: -0.707)
        }
    }
}
