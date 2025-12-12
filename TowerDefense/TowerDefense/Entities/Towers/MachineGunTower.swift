import SpriteKit

/// Machine Gun Tower
/// Role: High rate-of-fire, low damage per shot
/// Best against: Flying enemies (prioritizes them), Infantry
/// Type: Hitscan (instant hit)
final class MachineGunTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 4,      // Nerfed from 8
        range: 150,
        fireRate: 8.0   // 8 shots per second
    )
    
    init(gridPosition: GridPosition) {
        super.init(
            type: .machineGun,
            gridPosition: gridPosition,
            damage: MachineGunTower.stats.damage,
            range: MachineGunTower.stats.range,
            fireRate: MachineGunTower.stats.fireRate
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupTurretVisual() {
        // Double barrel design
        let barrel1 = SKShapeNode(rectOf: CGSize(width: towerSize * 0.5, height: towerSize * 0.08))
        barrel1.fillColor = .darkGray
        barrel1.strokeColor = .clear
        barrel1.position = CGPoint(x: towerSize * 0.3, y: 3)
        turretNode.addChild(barrel1)
        
        let barrel2 = SKShapeNode(rectOf: CGSize(width: towerSize * 0.5, height: towerSize * 0.08))
        barrel2.fillColor = .darkGray
        barrel2.strokeColor = .clear
        barrel2.position = CGPoint(x: towerSize * 0.3, y: -3)
        turretNode.addChild(barrel2)
        
        // Ammo belt indicator
        let ammoBox = SKShapeNode(rectOf: CGSize(width: 8, height: 10))
        ammoBox.fillColor = .brown
        ammoBox.strokeColor = .clear
        ammoBox.position = CGPoint(x: -8, y: 0)
        turretNode.addChild(ammoBox)
    }
    
    override func updateTarget() {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else {
            currentTarget = nil
            return
        }
        
        let aliveEnemies = enemies.filter { $0.isAlive }
        
        // Prioritize flying enemies
        let flyingEnemies = aliveEnemies.filter { $0.enemyType == .flying }
        
        if !flyingEnemies.isEmpty {
            // Target closest flying enemy
            currentTarget = flyingEnemies.min {
                position.distance(to: $0.position) < position.distance(to: $1.position)
            }
        } else {
            // Target closest any enemy
            currentTarget = aliveEnemies.min {
                position.distance(to: $0.position) < position.distance(to: $1.position)
            }
        }
    }
    
    override func fire(at target: Enemy, currentTime: TimeInterval) {
        let effectiveDamage = damage * damageMultiplier
        target.takeDamage(effectiveDamage)
        delegate?.towerDidFire(self, at: target)
        // AudioManager.shared.playSound(.machineGunFire)
        
        // Tracer effect (hitscan visual)
        let tracer = SKShapeNode()
        let path = CGMutablePath()
        
        let barrelEnd = CGPoint(
            x: position.x + cos(turretNode.zRotation) * towerSize * 0.5,
            y: position.y + sin(turretNode.zRotation) * towerSize * 0.5
        )
        
        path.move(to: barrelEnd)
        path.addLine(to: target.position)
        tracer.path = path
        tracer.strokeColor = .yellow
        tracer.lineWidth = 2
        tracer.alpha = 0.8
        tracer.zPosition = GameConstants.ZPosition.projectile.rawValue
        
        parent?.addChild(tracer)
        
        let tracerAnimation = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.05),
            SKAction.removeFromParent()
        ])
        tracer.run(tracerAnimation)
        
        // Small muzzle flash
        let flash = SKShapeNode(circleOfRadius: 5)
        flash.fillColor = .orange
        flash.strokeColor = .clear
        flash.position = CGPoint(
            x: cos(turretNode.zRotation) * towerSize * 0.5,
            y: sin(turretNode.zRotation) * towerSize * 0.5
        )
        flash.zPosition = GameConstants.ZPosition.effects.rawValue
        addChild(flash)
        
        let flashAnimation = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.03),
            SKAction.removeFromParent()
        ])
        flash.run(flashAnimation)
        
        // Recoil animation
        let recoil = SKAction.sequence([
            SKAction.moveBy(x: -2, y: 0, duration: 0.02),
            SKAction.moveBy(x: 2, y: 0, duration: 0.02)
        ])
        turretNode.run(recoil)
    }
    
    override func getStats() -> [String: String] {
        var stats = super.getStats()
        stats["Special"] = "Prioritizes Flying"
        stats["DPS"] = String(format: "%.0f", damage * damageMultiplier * fireRate * fireRateMultiplier)
        return stats
    }
}
