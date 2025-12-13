import SpriteKit

// MARK: - Game Constants
enum GameConstants {
    // Field dimensions (in grid cells)
    static let gridWidth = 26
    static let gridHeight = 14
    static let cellSize: CGFloat = 48
    
    // Playfield bounds
    static let playFieldOrigin = CGPoint(x: 100, y: 50)
    static let playFieldSize = CGSize(
        width: CGFloat(gridWidth) * cellSize,
        height: CGFloat(gridHeight) * cellSize
    )
    
    // Spawn and exit zones
    static let spawnZoneWidth: Int = 2  // leftmost columns
    static let exitZoneWidth: Int = 2   // rightmost columns
    
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
    
    var displayName: String {
        switch self {
        case .infantry: return "Infantry"
        case .cavalry: return "Cavalry"
        case .flying: return "Flying"
        }
    }
    
    var color: SKColor {
        switch self {
        case .infantry: return .green
        case .cavalry: return .orange
        case .flying: return .cyan
        }
    }
    
    var isFlying: Bool {
        return self == .flying
    }
}

// MARK: - Tower Types
enum TowerType: String, CaseIterable {
    case wall       // NEW: Cheap blocker, can convert to other towers
    case machineGun
    case cannon
    case slow
    case buff
    case shotgun
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
        case .shotgun: return "Shotgun"
        case .splash: return "Splash"
        case .laser: return "Laser"
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
        case .shotgun: return SKColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0)
        case .splash: return SKColor(red: 0.8, green: 0.4, blue: 0.6, alpha: 1.0)
        case .laser: return SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        case .antiAir: return SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        }
    }
    
    var baseCost: Int {
        switch self {
        case .wall: return 10       // Very cheap - just for blocking
        case .machineGun: return 50
        case .cannon: return 80
        case .slow: return 60
        case .buff: return 100
        case .shotgun: return 70
        case .splash: return 90
        case .laser: return 120
        case .antiAir: return 75
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
