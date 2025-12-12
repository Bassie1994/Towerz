import SpriteKit

/// Wall Tower
/// Role: Cheap obstacle that blocks enemy paths
/// Does NO damage - purely for maze building
/// Can be converted to any other tower type (pays the difference)
final class WallTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 0,       // No damage
        range: 0,        // No range
        fireRate: 0      // No firing
    )
    
    // Visual
    private var wallPattern: SKShapeNode?
    
    init(gridPosition: GridPosition) {
        super.init(
            type: .wall,
            gridPosition: gridPosition,
            damage: WallTower.stats.damage,
            range: WallTower.stats.range,
            fireRate: WallTower.stats.fireRate
        )
        
        setupWallVisual()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupTurretVisual() {
        // No turret - just a wall
        turretNode.isHidden = true
    }
    
    private func setupWallVisual() {
        // Remove default turret
        turretNode.removeAllChildren()
        turretNode.isHidden = true
        
        // Make base look like a wall/barrier
        baseNode.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        baseNode.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        
        // Add brick pattern
        let brickSize: CGFloat = towerSize / 4
        for row in 0..<4 {
            for col in 0..<4 {
                let offset = (row % 2 == 0) ? 0 : brickSize / 2
                let brick = SKShapeNode(rectOf: CGSize(width: brickSize - 2, height: brickSize - 2))
                brick.fillColor = SKColor(red: 0.5 + CGFloat.random(in: -0.1...0.1),
                                          green: 0.4 + CGFloat.random(in: -0.1...0.1),
                                          blue: 0.35 + CGFloat.random(in: -0.1...0.1),
                                          alpha: 1.0)
                brick.strokeColor = SKColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 0.5)
                brick.lineWidth = 1
                brick.position = CGPoint(
                    x: -towerSize/2 + brickSize/2 + CGFloat(col) * brickSize + offset,
                    y: -towerSize/2 + brickSize/2 + CGFloat(row) * brickSize
                )
                brick.zPosition = 1
                baseNode.addChild(brick)
            }
        }
        
        // Add "WALL" indicator
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.fontSize = 10
        label.fontColor = .white
        label.text = "WALL"
        label.position = CGPoint(x: 0, y: -towerSize/2 - 12)
        label.zPosition = 2
        addChild(label)
    }
    
    override func update(currentTime: TimeInterval) {
        // Wall does nothing - no targeting, no firing
        // Just update buff visual if somehow buffed
        if isBuffed {
            buffIndicator.isHidden = false
        } else {
            buffIndicator.isHidden = true
        }
    }
    
    override func updateTarget() {
        // No targeting
        currentTarget = nil
    }
    
    override func fire(at target: Enemy, currentTime: TimeInterval) {
        // Wall cannot fire
    }
    
    // Wall cannot be upgraded normally - only converted
    override func canUpgrade() -> Bool {
        return false
    }
    
    override func getUpgradeCost() -> Int? {
        return nil
    }
    
    /// Get the cost to convert this wall to another tower type
    func getConversionCost(to type: TowerType) -> Int {
        guard type != .wall else { return 0 }
        // Pay the difference between wall cost and target tower cost
        return type.baseCost - TowerType.wall.baseCost
    }
    
    override func getStats() -> [String: String] {
        return [
            "Type": "Wall",
            "Damage": "None",
            "Range": "None",
            "Special": "Blocks path only",
            "Hint": "Tap to convert",
            "Sell Value": "\(sellValue)"
        ]
    }
}
