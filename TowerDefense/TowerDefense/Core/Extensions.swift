import SpriteKit

// MARK: - CGPoint Extensions
extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
    
    func normalized() -> CGPoint {
        let length = sqrt(x * x + y * y)
        guard length > 0 else { return .zero }
        return CGPoint(x: x / length, y: y / length)
    }
    
    func scaled(by factor: CGFloat) -> CGPoint {
        return CGPoint(x: x * factor, y: y * factor)
    }
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    func angle(to point: CGPoint) -> CGFloat {
        return atan2(point.y - y, point.x - x)
    }
    
    func toGridPosition() -> GridPosition {
        let gridX = Int((x - GameConstants.playFieldOrigin.x) / GameConstants.cellSize)
        let gridY = Int((y - GameConstants.playFieldOrigin.y) / GameConstants.cellSize)
        return GridPosition(x: gridX, y: gridY)
    }
}

// MARK: - GridPosition to World
extension GridPosition {
    func toWorldPosition() -> CGPoint {
        let worldX = GameConstants.playFieldOrigin.x + (CGFloat(x) + 0.5) * GameConstants.cellSize
        let worldY = GameConstants.playFieldOrigin.y + (CGFloat(y) + 0.5) * GameConstants.cellSize
        return CGPoint(x: worldX, y: worldY)
    }
    
    func isInSpawnZone() -> Bool {
        return x < GameConstants.spawnZoneWidth
    }
    
    func isInExitZone() -> Bool {
        // Exit zone is bottom-right corner (last 2 columns, bottom 4 rows)
        let inExitColumns = x >= GameConstants.gridWidth - GameConstants.exitZoneWidth
        let inExitRows = y < 4  // Bottom 4 rows
        return inExitColumns && inExitRows
    }
    
    func isInPlayableArea() -> Bool {
        return x >= 0 && x < GameConstants.gridWidth &&
               y >= 0 && y < GameConstants.gridHeight &&
               !isInSpawnZone() && !isInExitZone()
    }
}

// MARK: - CGVector Extensions
extension CGVector {
    var length: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
    
    func normalized() -> CGVector {
        let len = length
        guard len > 0 else { return CGVector(dx: 1, dy: 0) }  // Default right direction
        return CGVector(dx: dx / len, dy: dy / len)
    }
    
    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
    
    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }
}

// MARK: - SKNode Extensions
extension SKNode {
    func removeAllActionsRecursively() {
        removeAllActions()
        children.forEach { $0.removeAllActionsRecursively() }
    }
}

// MARK: - Array Extensions
extension Array {
    func randomElement(using generator: inout RandomNumberGenerator) -> Element? {
        guard !isEmpty else { return nil }
        let index = Int.random(in: 0..<count, using: &generator)
        return self[index]
    }
}

// MARK: - SKColor Extensions
extension SKColor {
    static let healthBarGreen = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
    static let healthBarYellow = SKColor(red: 0.9, green: 0.9, blue: 0.2, alpha: 1.0)
    static let healthBarRed = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    
    static let validPlacement = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.5)
    static let invalidPlacement = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.5)
    
    static let slowEffect = SKColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)
    static let buffEffect = SKColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1.0)
}

// MARK: - Int Extensions
extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
