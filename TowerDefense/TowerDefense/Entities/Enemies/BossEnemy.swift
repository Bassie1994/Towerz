import SpriteKit

/// Boss enemy - massive, extremely tanky, very slow
/// Spawns first in waves 5, 10, 15, etc.
/// HP equals the total HP of the previous wave
final class BossEnemy: Enemy {
    
    // Boss base stats - will be overridden by wave HP
    static let baseStats: (health: CGFloat, speed: CGFloat, armor: CGFloat, reward: Int) = (
        health: 10000,   // Will be replaced with wave HP
        speed: 25,       // Very slow
        armor: 50,       // Armored
        reward: 100      // Big reward
    )
    
    private var pulseNode: SKShapeNode?
    private var crownNode: SKShapeNode?
    
    init(level: Int = 1, customHP: CGFloat? = nil) {
        // Use custom HP if provided (from wave calculation), otherwise scale base
        let health = customHP ?? (BossEnemy.baseStats.health * CGFloat(level))
        let speed = BossEnemy.baseStats.speed  // Boss speed stays constant (very slow)
        let armor = BossEnemy.baseStats.armor + CGFloat(level - 1) * 20
        let reward = BossEnemy.baseStats.reward + (level - 1) * 50
        
        super.init(
            type: .boss,
            health: health,
            speed: speed,
            armor: armor,
            reward: reward
        )
        
        setupBossAppearance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBossAppearance() {
        // Make boss MUCH larger (3x normal size)
        bodyNode.setScale(3.0)
        
        // Override body color to be more menacing
        bodyNode.fillColor = SKColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 1.0)
        bodyNode.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        bodyNode.lineWidth = 4
        
        // Add pulsing red aura
        let aura = SKShapeNode(circleOfRadius: enemySize * 2)
        aura.fillColor = SKColor(red: 1.0, green: 0, blue: 0, alpha: 0.2)
        aura.strokeColor = SKColor(red: 1.0, green: 0, blue: 0, alpha: 0.5)
        aura.lineWidth = 3
        aura.zPosition = -2
        bodyNode.addChild(aura)
        pulseNode = aura
        
        // Pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        aura.run(SKAction.repeatForever(pulse))
        
        // Add crown/horns to show it's a boss
        let crown = SKShapeNode()
        let crownPath = CGMutablePath()
        crownPath.move(to: CGPoint(x: -8, y: 8))
        crownPath.addLine(to: CGPoint(x: -6, y: 15))
        crownPath.addLine(to: CGPoint(x: -3, y: 10))
        crownPath.addLine(to: CGPoint(x: 0, y: 18))
        crownPath.addLine(to: CGPoint(x: 3, y: 10))
        crownPath.addLine(to: CGPoint(x: 6, y: 15))
        crownPath.addLine(to: CGPoint(x: 8, y: 8))
        crownPath.closeSubpath()
        crown.path = crownPath
        crown.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0, alpha: 1.0)  // Gold
        crown.strokeColor = SKColor(red: 0.8, green: 0.6, blue: 0, alpha: 1.0)
        crown.lineWidth = 1
        crown.position = CGPoint(x: 0, y: enemySize / 2)
        crown.zPosition = 2
        bodyNode.addChild(crown)
        crownNode = crown
        
        // Add glowing eyes
        for xOffset: CGFloat in [-4, 4] {
            let eye = SKShapeNode(circleOfRadius: 3)
            eye.fillColor = .yellow
            eye.strokeColor = .orange
            eye.lineWidth = 1
            eye.position = CGPoint(x: xOffset, y: 2)
            eye.zPosition = 1
            bodyNode.addChild(eye)
            
            // Glowing animation
            let glow = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.3),
                SKAction.fadeAlpha(to: 1.0, duration: 0.3)
            ])
            eye.run(SKAction.repeatForever(glow))
        }
        
        // Add "BOSS" label above
        let bossLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bossLabel.text = "BOSS"
        bossLabel.fontSize = 12
        bossLabel.fontColor = .red
        bossLabel.position = CGPoint(x: 0, y: enemySize + 25)
        bossLabel.zPosition = 3
        bodyNode.addChild(bossLabel)
        
        // Scale up health bar
        healthBarBackground.setScale(2.0)
        healthBarBackground.position = CGPoint(x: 0, y: enemySize * 1.5 + 35)
    }
    
    override func calculateMovementDirection() -> CGVector {
        // Boss uses flow field like other ground units
        if let flowField = delegate?.getFlowField(),
           let direction = flowField.getInterpolatedDirection(at: position) {
            return direction
        }
        return CGVector(dx: 1, dy: 0)
    }
    
    
    override func die() {
        // Epic death explosion for boss
        guard let parent = parent else {
            super.die()
            return
        }
        
        // Multiple explosions
        for i in 0..<8 {
            let delay = Double(i) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak parent, position] in
                guard let p = parent else { return }
                
                let offset = CGPoint(
                    x: CGFloat.random(in: -30...30),
                    y: CGFloat.random(in: -30...30)
                )
                
                let explosion = SKShapeNode(circleOfRadius: 20)
                explosion.fillColor = [.orange, .red, .yellow].randomElement()!
                explosion.strokeColor = .white
                explosion.lineWidth = 2
                explosion.position = CGPoint(x: position.x + offset.x, y: position.y + offset.y)
                explosion.zPosition = GameConstants.ZPosition.effects.rawValue
                p.addChild(explosion)
                
                explosion.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 3.0, duration: 0.3),
                        SKAction.fadeOut(withDuration: 0.3)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
        }
        
        // Final big explosion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak parent, position] in
            guard let p = parent else { return }
            
            let bigExplosion = SKShapeNode(circleOfRadius: 50)
            bigExplosion.fillColor = .white
            bigExplosion.strokeColor = .yellow
            bigExplosion.lineWidth = 5
            bigExplosion.position = position
            bigExplosion.zPosition = GameConstants.ZPosition.effects.rawValue + 1
            p.addChild(bigExplosion)
            
            bigExplosion.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 4.0, duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        super.die()
    }
}
