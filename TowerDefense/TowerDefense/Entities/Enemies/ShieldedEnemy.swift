import SpriteKit

/// Enemy with a temporary damage reduction shield
final class ShieldedEnemy: Enemy {
    
    private static let baseStats: (health: CGFloat, speed: CGFloat, armor: CGFloat, reward: Int) = (
        health: 260,
        speed: 80,
        armor: 10,
        reward: 4
    )
    
    private let shieldNode: SKShapeNode
    private let shieldDuration: TimeInterval = 4.0
    private let shieldDamageReduction: CGFloat = 0.5
    private var shieldActive: Bool = true
    
    init(level: Int = 1) {
        let healthMultiplier = 1.0 + (CGFloat(level - 1) * 0.28)
        let health = ShieldedEnemy.baseStats.health * healthMultiplier
        let speed = ShieldedEnemy.baseStats.speed
        let armor = ShieldedEnemy.baseStats.armor + CGFloat(level - 1) * 6
        let reward = ShieldedEnemy.baseStats.reward + (level - 1) * 2
        
        shieldNode = SKShapeNode(circleOfRadius: 18)
        shieldNode.fillColor = .clear
        shieldNode.strokeColor = SKColor(red: 0.3, green: 0.85, blue: 1.0, alpha: 0.9)
        shieldNode.lineWidth = 3
        
        super.init(
            type: .shielded,
            health: health,
            speed: speed,
            armor: armor,
            reward: reward
        )
        
        shieldNode.setScale((enemySize / 2 + 6) / 18)
        addChild(shieldNode)
        startShieldTimer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func startShieldTimer() {
        let shimmer = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.4),
            SKAction.fadeAlpha(to: 0.9, duration: 0.4)
        ])
        shieldNode.run(SKAction.repeatForever(shimmer), withKey: "shieldShimmer")
        
        let expire = SKAction.sequence([
            SKAction.wait(forDuration: shieldDuration),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 0.7, duration: 0.3)
            ]),
            SKAction.run { [weak self] in
                self?.shieldActive = false
                self?.shieldNode.isHidden = true
                self?.shieldNode.removeAction(forKey: "shieldShimmer")
            }
        ])
        run(expire, withKey: "shieldExpire")
    }
    
    override func takeDamage(_ damage: CGFloat, armorPenetration: CGFloat = 0) {
        let adjustedDamage = shieldActive ? damage * (1 - shieldDamageReduction) : damage
        super.takeDamage(adjustedDamage, armorPenetration: armorPenetration)
    }
}
