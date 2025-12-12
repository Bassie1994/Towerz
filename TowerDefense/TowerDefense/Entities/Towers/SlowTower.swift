import SpriteKit

/// Slow Tower
/// Role: Slows enemies in range (no direct damage)
/// Effect: Applies slow debuff to all enemies in range
/// Upgrade: Increases slow strength and effect radius
final class SlowTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 0,      // No damage
        range: 120,
        fireRate: 2.0   // Apply slow every 0.5 seconds
    )
    
    var slowStrength: CGFloat = 0.5   // 50% speed reduction
    var slowDuration: TimeInterval = 2.0
    
    // Visual
    let slowFieldNode: SKShapeNode
    
    init(gridPosition: GridPosition) {
        slowFieldNode = SKShapeNode(circleOfRadius: SlowTower.stats.range)
        slowFieldNode.fillColor = SKColor.slowEffect.withAlphaComponent(0.1)
        slowFieldNode.strokeColor = SKColor.slowEffect.withAlphaComponent(0.3)
        slowFieldNode.lineWidth = 2
        slowFieldNode.zPosition = -1
        
        super.init(
            type: .slow,
            gridPosition: gridPosition,
            damage: SlowTower.stats.damage,
            range: SlowTower.stats.range,
            fireRate: SlowTower.stats.fireRate
        )
        
        addChild(slowFieldNode)
        setupSlowFieldAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSlowFieldAnimation() {
        // Pulsing effect
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 1.0),
            SKAction.scale(to: 0.95, duration: 1.0)
        ])
        slowFieldNode.run(SKAction.repeatForever(pulse))
        
        // Rotating pattern inside
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 8.0)
        slowFieldNode.run(SKAction.repeatForever(rotateAction))
    }
    
    override func setupTurretVisual() {
        // Crystal/emitter design
        let crystal = SKShapeNode(rectOf: CGSize(width: towerSize * 0.3, height: towerSize * 0.5))
        crystal.fillColor = .slowEffect
        crystal.strokeColor = .white
        crystal.lineWidth = 1
        crystal.zRotation = .pi / 4
        turretNode.addChild(crystal)
        
        // Inner glow
        let glow = SKShapeNode(circleOfRadius: towerSize * 0.15)
        glow.fillColor = SKColor.white.withAlphaComponent(0.5)
        glow.strokeColor = .clear
        turretNode.addChild(glow)
        
        // Glow animation
        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.5),
            SKAction.fadeAlpha(to: 0.3, duration: 0.5)
        ])
        glow.run(SKAction.repeatForever(glowPulse))
    }
    
    override func update(currentTime: TimeInterval) {
        // Don't call super - slow tower has different behavior
        
        // Update visual based on buff
        if isBuffed {
            if buffIndicator.isHidden {
                buffIndicator.isHidden = false
            }
        } else {
            buffIndicator.isHidden = true
        }
        
        // Apply slow to all enemies in range
        let effectiveFireRate = fireRate * fireRateMultiplier
        let fireInterval = 1.0 / Double(effectiveFireRate)
        
        if currentTime - lastFireTime >= fireInterval {
            applySlowToEnemiesInRange(currentTime: currentTime)
            lastFireTime = currentTime
        }
    }
    
    private func applySlowToEnemiesInRange(currentTime: TimeInterval) {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else { return }
        
        let effectiveSlowStrength = slowStrength * (isBuffed ? 1.2 : 1.0)
        let effectiveDuration = slowDuration * (isBuffed ? 1.2 : 1.0)
        
        var appliedToAny = false
        
        for enemy in enemies where enemy.isAlive {
            enemy.applySlow(
                multiplier: 1.0 - effectiveSlowStrength,
                duration: effectiveDuration,
                currentTime: currentTime
            )
            appliedToAny = true
        }
        
        // Visual feedback when slowing
        if appliedToAny {
            spawnSlowWave()
        }
    }
    
    private func spawnSlowWave() {
        let wave = SKShapeNode(circleOfRadius: 10)
        wave.fillColor = .clear
        wave.strokeColor = .slowEffect
        wave.lineWidth = 2
        wave.alpha = 0.8
        wave.zPosition = GameConstants.ZPosition.effects.rawValue
        addChild(wave)
        
        let waveAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: range / 10, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ])
        wave.run(waveAnimation)
    }
    
    override func upgrade() -> Bool {
        let result = super.upgrade()
        
        if result {
            // Increase slow strength and duration
            slowStrength = min(0.7, 0.5 + CGFloat(upgradeLevel) * 0.1)
            slowDuration = 2.0 + Double(upgradeLevel) * 0.5
            
            // Update visual
            let newPath = CGPath(ellipseIn: CGRect(x: -range, y: -range, width: range * 2, height: range * 2), transform: nil)
            slowFieldNode.path = newPath
        }
        
        return result
    }
    
    override func getStats() -> [String: String] {
        return [
            "Type": towerType.displayName,
            "Slow": "\(Int(slowStrength * 100))%",
            "Duration": String(format: "%.1fs", slowDuration),
            "Range": String(format: "%.0f", range),
            "Level": "\(upgradeLevel + 1)/\(maxUpgradeLevel + 1)",
            "Sell Value": "\(sellValue)"
        ]
    }
}
