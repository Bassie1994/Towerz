import SpriteKit

/// Fast ground unit with higher HP and armor
/// Must navigate around towers like infantry
/// Best countered by Cannon tower (armor penetration)
final class CavalryEnemy: Enemy {
    
    // Cavalry stats per level - TANKY but SLOW
    static let baseStats: (health: CGFloat, speed: CGFloat, armor: CGFloat, reward: Int) = (
        health: 300,    // Increased from 180 - very tanky
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
        
        // Add speed lines effect
        let speedLine1 = SKShapeNode(rectOf: CGSize(width: 15, height: 2))
        speedLine1.fillColor = .white
        speedLine1.strokeColor = .clear
        speedLine1.alpha = 0.5
        speedLine1.position = CGPoint(x: -enemySize, y: 3)
        bodyNode.addChild(speedLine1)
        
        let speedLine2 = SKShapeNode(rectOf: CGSize(width: 10, height: 2))
        speedLine2.fillColor = .white
        speedLine2.strokeColor = .clear
        speedLine2.alpha = 0.3
        speedLine2.position = CGPoint(x: -enemySize - 5, y: -3)
        bodyNode.addChild(speedLine2)
        
        // Animate speed lines
        let fadeAnimation = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.2),
            SKAction.fadeAlpha(to: 0.5, duration: 0.2)
        ])
        speedLine1.run(SKAction.repeatForever(fadeAnimation))
        speedLine2.run(SKAction.repeatForever(fadeAnimation.reversed()))
        
        // Gallop animation
        let gallopAnimation = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 2, duration: 0.1),
            SKAction.moveBy(x: 0, y: -2, duration: 0.1)
        ])
        bodyNode.run(SKAction.repeatForever(gallopAnimation), withKey: "gallop")
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
