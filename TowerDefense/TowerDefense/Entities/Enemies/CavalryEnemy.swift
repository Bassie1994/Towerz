import SpriteKit

/// Fast ground unit with higher HP and armor
/// Must navigate around towers like infantry
/// Best countered by Cannon tower (armor penetration)
final class CavalryEnemy: Enemy {
    
    // Cavalry stats per level - TANKY but SLOW
    static let baseStats: (health: CGFloat, speed: CGFloat, armor: CGFloat, reward: Int) = (
        health: 600,    // 2x HP - very tanky
        speed: 50,      // Reduced from 120 - slow moving
        armor: 30,
        reward: 4       // Reduced from 20 (factor 5)
    )
    
    init(level: Int = 1) {
        // Scale stats with level
        let healthMultiplier = 1.0 + (CGFloat(level - 1) * 0.35)
        let health = CavalryEnemy.baseStats.health * healthMultiplier
        let speed = CavalryEnemy.baseStats.speed + CGFloat(level - 1) * 5
        let armor = CavalryEnemy.baseStats.armor + CGFloat(level - 1) * 10
        let reward = CavalryEnemy.baseStats.reward + (level - 1) * 4
        
        super.init(
            type: .cavalry,
            health: health,
            speed: speed,
            armor: armor,
            reward: reward
        )
        
        setupAppearance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        // Make cavalry slightly larger
        bodyNode.setScale(1.2)
        
        // Add horse/mount indicator
        let mount = SKShapeNode(ellipseOf: CGSize(width: enemySize * 1.4, height: enemySize * 0.6))
        mount.fillColor = enemyType.color.withAlphaComponent(0.6)
        mount.strokeColor = enemyType.color
        mount.lineWidth = 1
        mount.position = CGPoint(x: 0, y: -enemySize / 4)
        mount.zPosition = -1
        bodyNode.addChild(mount)
        
        // Simple visual indicator for cavalry (no complex animations)
        let armorIndicator = SKShapeNode(circleOfRadius: 5)
        armorIndicator.fillColor = .gray
        armorIndicator.strokeColor = .white
        armorIndicator.lineWidth = 1
        armorIndicator.position = CGPoint(x: 0, y: 5)
        bodyNode.addChild(armorIndicator)
    }
    
    override func calculateMovementDirection() -> CGVector {
        // Cavalry also uses flow field but moves faster
        if let flowField = delegate?.getFlowField(),
           let direction = flowField.getInterpolatedDirection(at: position) {
            return direction
        }
        return CGVector(dx: 1, dy: 0)
    }
}
