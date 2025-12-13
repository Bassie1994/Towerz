import SpriteKit

/// Cannon Tower
/// Role: High damage, slow rate of fire, armor penetration
/// Best against: Cavalry (armored units)
/// Type: Projectile (travels to target)
final class CannonTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 30,     // Nerfed from 60
        range: 70,      // Reduced from 180 - short range
        fireRate: 0.8   // 0.8 shots per second
    )
    
    let armorPenetration: CGFloat = 50  // Ignores this much armor
    
    init(gridPosition: GridPosition) {
        super.init(
            type: .cannon,
            gridPosition: gridPosition,
            damage: CannonTower.stats.damage,
            range: CannonTower.stats.range,
            fireRate: CannonTower.stats.fireRate
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupTurretVisual() {
        // Large single barrel
        let barrel = SKShapeNode(rectOf: CGSize(width: towerSize * 0.6, height: towerSize * 0.2))
        barrel.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        barrel.strokeColor = .darkGray
        barrel.lineWidth = 1
        barrel.position = CGPoint(x: towerSize * 0.35, y: 0)
        turretNode.addChild(barrel)
        
        // Barrel end (muzzle)
        let muzzle = SKShapeNode(circleOfRadius: towerSize * 0.12)
        muzzle.fillColor = .black
        muzzle.strokeColor = .darkGray
        muzzle.position = CGPoint(x: towerSize * 0.65, y: 0)
        turretNode.addChild(muzzle)
        
        // Reinforcement ring
        let ring = SKShapeNode(circleOfRadius: turretNode.frame.width * 0.6)
        ring.fillColor = .clear
        ring.strokeColor = towerType.color.withAlphaComponent(0.5)
        ring.lineWidth = 3
        turretNode.addChild(ring)
    }
    
    override func updateTarget() {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else {
            currentTarget = nil
            return
        }
        
        // Cannon cannot hit flying enemies - projectile goes under them
        let groundEnemies = enemies.filter { $0.isAlive && $0.enemyType != .flying }
        
        // Prioritize armored enemies (cavalry)
        let armoredEnemies = groundEnemies.filter { $0.armor > 0 }
        
        if !armoredEnemies.isEmpty {
            // Target cavalry with most armor
            currentTarget = armoredEnemies.max { $0.armor < $1.armor }
        } else {
            // Target enemy with most health
            currentTarget = groundEnemies.max { $0.currentHealth < $1.currentHealth }
        }
    }
    
    override func fire(at target: Enemy, currentTime: TimeInterval) {
        delegate?.towerDidFire(self, at: target)
        // AudioManager.shared.playSound(.cannonFire)
        
        // Create projectile
        let projectile = Projectile(
            from: position,
            to: target,
            damage: damage * damageMultiplier,
            speed: 400,
            armorPenetration: armorPenetration + CGFloat(upgradeLevel) * 15
        )
        projectile.visualType = .cannonBall
        parent?.addChild(projectile)
        
        // Heavy recoil animation
        let recoilDistance: CGFloat = 5
        let recoil = SKAction.sequence([
            SKAction.moveBy(x: -cos(turretNode.zRotation) * recoilDistance,
                           y: -sin(turretNode.zRotation) * recoilDistance,
                           duration: 0.05),
            SKAction.moveBy(x: cos(turretNode.zRotation) * recoilDistance,
                           y: sin(turretNode.zRotation) * recoilDistance,
                           duration: 0.15)
        ])
        turretNode.run(recoil)
        
        // Large muzzle flash
        let flash = SKShapeNode(circleOfRadius: 12)
        flash.fillColor = .orange
        flash.strokeColor = .yellow
        flash.lineWidth = 2
        flash.position = CGPoint(
            x: cos(turretNode.zRotation) * towerSize * 0.65,
            y: sin(turretNode.zRotation) * towerSize * 0.65
        )
        flash.zPosition = GameConstants.ZPosition.effects.rawValue
        addChild(flash)
        
        let flashAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ])
        flash.run(flashAnimation)
        
        // Smoke effect
        for _ in 0..<3 {
            let smoke = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...8))
            smoke.fillColor = .gray
            smoke.strokeColor = .clear
            smoke.alpha = 0.6
            smoke.position = CGPoint(
                x: cos(turretNode.zRotation) * towerSize * 0.6 + CGFloat.random(in: -5...5),
                y: sin(turretNode.zRotation) * towerSize * 0.6 + CGFloat.random(in: -5...5)
            )
            smoke.zPosition = GameConstants.ZPosition.effects.rawValue
            addChild(smoke)
            
            let smokeAnimation = SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 2.0, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.moveBy(x: CGFloat.random(in: -20...20),
                                   y: CGFloat.random(in: 10...30),
                                   duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ])
            smoke.run(smokeAnimation)
        }
    }
    
    override func getStats() -> [String: String] {
        var stats = super.getStats()
        stats["Special"] = "Armor Pen: \(Int(armorPenetration + CGFloat(upgradeLevel) * 15))"
        stats["Best vs"] = "Cavalry"
        stats["Note"] = "Cannot hit Flying"
        return stats
    }
}
