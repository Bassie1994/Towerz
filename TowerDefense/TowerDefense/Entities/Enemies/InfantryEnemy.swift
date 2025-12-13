import SpriteKit

/// Standard ground unit
/// Must navigate around towers using flow field pathfinding
/// Balanced stats, no special abilities
final class InfantryEnemy: Enemy {
    
    // Infantry stats per level
    static let baseStats: (health: CGFloat, speed: CGFloat, armor: CGFloat, reward: Int) = (
        health: 200,    // 2x HP
        speed: 100,     // Increased from 80
        armor: 0,
        reward: 2       // Reduced from 10 (factor 5)
    )
    
    init(level: Int = 1) {
        // Scale stats with level
        let healthMultiplier = 1.0 + (CGFloat(level - 1) * 0.3)
        let health = InfantryEnemy.baseStats.health * healthMultiplier
        let speed = InfantryEnemy.baseStats.speed
        let armor = InfantryEnemy.baseStats.armor + CGFloat(level - 1) * 5
        let reward = InfantryEnemy.baseStats.reward + (level - 1) * 2
        
        super.init(
            type: .infantry,
            health: health,
            speed: speed,
            armor: armor,
            reward: reward
        )
        
        // Infantry specific appearance
        setupAppearance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        // Add infantry-specific visual (boots/legs indicator)
        let leg1 = SKShapeNode(rectOf: CGSize(width: 4, height: 8))
        leg1.fillColor = enemyType.color.withAlphaComponent(0.8)
        leg1.strokeColor = .clear
        leg1.position = CGPoint(x: -6, y: -enemySize / 2 - 2)
        bodyNode.addChild(leg1)
        
        let leg2 = SKShapeNode(rectOf: CGSize(width: 4, height: 8))
        leg2.fillColor = enemyType.color.withAlphaComponent(0.8)
        leg2.strokeColor = .clear
        leg2.position = CGPoint(x: 6, y: -enemySize / 2 - 2)
        bodyNode.addChild(leg2)
        
        // Animate legs
        let walkAnimation = SKAction.sequence([
            SKAction.run {
                leg1.position.y = -self.enemySize / 2 - 4
                leg2.position.y = -self.enemySize / 2
            },
            SKAction.wait(forDuration: 0.15),
            SKAction.run {
                leg1.position.y = -self.enemySize / 2
                leg2.position.y = -self.enemySize / 2 - 4
            },
            SKAction.wait(forDuration: 0.15)
        ])
        bodyNode.run(SKAction.repeatForever(walkAnimation), withKey: "walk")
    }
    
    override func calculateMovementDirection() -> CGVector {
        // Infantry uses flow field for pathfinding around obstacles
        if let flowField = delegate?.getFlowField(),
           let direction = flowField.getInterpolatedDirection(at: position) {
            return direction
        }
        return CGVector(dx: 1, dy: 0)
    }
}
