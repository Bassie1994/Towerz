import SpriteKit

/// Enemy that buffs nearby allies with speed + damage reduction
final class SupportEnemy: Enemy {
    
    private static let baseStats: (health: CGFloat, speed: CGFloat, armor: CGFloat, reward: Int) = (
        health: 180,
        speed: 90,
        armor: 0,
        reward: 3
    )
    
    private let auraRadius: CGFloat = GameConstants.cellSize * 2.2
    private let buffSpeedMultiplier: CGFloat = 1.15
    private let buffDamageReduction: CGFloat = 0.15
    private let buffDuration: TimeInterval = 0.8
    
    private let auraNode: SKShapeNode
    
    init(level: Int = 1) {
        let healthMultiplier = 1.0 + (CGFloat(level - 1) * 0.22)
        let health = SupportEnemy.baseStats.health * healthMultiplier
        let speed = SupportEnemy.baseStats.speed
        let armor = SupportEnemy.baseStats.armor + CGFloat(level - 1) * 4
        let reward = SupportEnemy.baseStats.reward + (level - 1)
        
        auraNode = SKShapeNode(circleOfRadius: auraRadius)
        auraNode.fillColor = SKColor(red: 0.7, green: 0.4, blue: 0.95, alpha: 0.12)
        auraNode.strokeColor = SKColor(red: 0.7, green: 0.4, blue: 0.95, alpha: 0.5)
        auraNode.lineWidth = 2
        
        super.init(
            type: .support,
            health: health,
            speed: speed,
            armor: armor,
            reward: reward
        )
        
        auraNode.zPosition = -1
        addChild(auraNode)
        startAuraPulse()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime: TimeInterval, currentTime: TimeInterval, enemies: [Enemy]) {
        applySupportAura(currentTime: currentTime, enemies: enemies)
        super.update(deltaTime: deltaTime, currentTime: currentTime, enemies: enemies)
    }
    
    private func applySupportAura(currentTime: TimeInterval, enemies: [Enemy]) {
        for enemy in enemies where enemy.isAlive && enemy.id != id {
            let distance = position.distance(to: enemy.position)
            if distance <= auraRadius {
                enemy.applySupportBuff(
                    speedMultiplier: buffSpeedMultiplier,
                    damageReduction: buffDamageReduction,
                    duration: buffDuration,
                    currentTime: currentTime
                )
            }
        }
    }
    
    private func startAuraPulse() {
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.08, duration: 0.6),
            SKAction.fadeAlpha(to: 0.18, duration: 0.6)
        ])
        auraNode.run(SKAction.repeatForever(pulse), withKey: "auraPulse")
    }
}
