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
        // Simplified infantry visual - no animation for better performance
        let marker = SKShapeNode(rectOf: CGSize(width: 8, height: 4))
        marker.fillColor = enemyType.color.withAlphaComponent(0.6)
        marker.strokeColor = .clear
        marker.position = CGPoint(x: 0, y: -enemySize / 2 - 2)
        bodyNode.addChild(marker)
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
