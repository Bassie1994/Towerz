import SpriteKit

/// Shotgun Tower
/// Role: Short range, cone spread, high damage to clustered enemies
/// Multiple pellets with damage falloff
/// Best against: Clustered Infantry
final class ShotgunTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 6,       // Nerfed from 12 per pellet
        range: 70,       // Minimum range
        fireRate: 1.5    // Shots per second
    )
    
    let pelletCount: Int = 6
    let spreadAngle: CGFloat = .pi / 4  // 45 degree spread
    
    init(gridPosition: GridPosition) {
        super.init(
            type: .shotgun,
            gridPosition: gridPosition,
            damage: ShotgunTower.stats.damage,
            range: ShotgunTower.stats.range,
            fireRate: ShotgunTower.stats.fireRate
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupTurretVisual() {
        // Wide barrel design
        let barrel = SKShapeNode(rectOf: CGSize(width: towerSize * 0.4, height: towerSize * 0.25))
        barrel.fillColor = SKColor(red: 0.4, green: 0.3, blue: 0.3, alpha: 1.0)
        barrel.strokeColor = .darkGray
        barrel.lineWidth = 1
        barrel.position = CGPoint(x: towerSize * 0.25, y: 0)
        turretNode.addChild(barrel)
        
        // Shell ejector
        let ejector = SKShapeNode(rectOf: CGSize(width: 6, height: 8))
        ejector.fillColor = .brown
        ejector.strokeColor = .clear
        ejector.position = CGPoint(x: -5, y: 6)
        turretNode.addChild(ejector)
        
        // Grip
        let grip = SKShapeNode(rectOf: CGSize(width: 8, height: 12))
        grip.fillColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        grip.strokeColor = .clear
        grip.position = CGPoint(x: -8, y: -6)
        turretNode.addChild(grip)
    }
    
    override func fire(at target: Enemy, currentTime: TimeInterval) {
        delegate?.towerDidFire(self, at: target)
        // AudioManager.shared.playSound(.shotgunFire)
        
        let baseAngle = position.angle(to: target.position)
        let effectiveDamage = damage * damageMultiplier
        let effectivePelletCount = pelletCount + upgradeLevel
        
        // Fire multiple pellets in a cone
        for i in 0..<effectivePelletCount {
            let angleOffset = spreadAngle * (CGFloat(i) / CGFloat(effectivePelletCount - 1) - 0.5)
            let pelletAngle = baseAngle + angleOffset
            
            // Calculate pellet end position
            let pelletRange = range * CGFloat.random(in: 0.8...1.0)
            let endPoint = CGPoint(
                x: position.x + cos(pelletAngle) * pelletRange,
                y: position.y + sin(pelletAngle) * pelletRange
            )
            
            // Create pellet visual
            let pellet = SKShapeNode(circleOfRadius: 3)
            pellet.fillColor = .yellow
            pellet.strokeColor = .clear
            pellet.position = position
            pellet.zPosition = GameConstants.ZPosition.projectile.rawValue
            parent?.addChild(pellet)
            
            // Animate pellet
            let travelTime = 0.15
            let travel = SKAction.move(to: endPoint, duration: travelTime)
            let fade = SKAction.fadeOut(withDuration: travelTime)
            let remove = SKAction.removeFromParent()
            pellet.run(SKAction.sequence([SKAction.group([travel, fade]), remove]))
            
            // Check for hits along pellet path
            checkPelletHits(from: position, to: endPoint, damage: effectiveDamage, pelletAngle: pelletAngle)
        }
        
        // Muzzle flash (wide)
        let flash = SKShapeNode(rectOf: CGSize(width: 20, height: 15))
        flash.fillColor = .orange
        flash.strokeColor = .yellow
        flash.lineWidth = 1
        flash.position = CGPoint(
            x: cos(turretNode.zRotation) * towerSize * 0.4,
            y: sin(turretNode.zRotation) * towerSize * 0.4
        )
        flash.zRotation = turretNode.zRotation
        flash.zPosition = GameConstants.ZPosition.effects.rawValue
        addChild(flash)
        
        let flashAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.05),
                SKAction.fadeOut(withDuration: 0.08)
            ]),
            SKAction.removeFromParent()
        ])
        flash.run(flashAnimation)
        
        // Heavy recoil
        let recoil = SKAction.sequence([
            SKAction.moveBy(x: -cos(turretNode.zRotation) * 6,
                           y: -sin(turretNode.zRotation) * 6,
                           duration: 0.03),
            SKAction.moveBy(x: cos(turretNode.zRotation) * 6,
                           y: sin(turretNode.zRotation) * 6,
                           duration: 0.15)
        ])
        turretNode.run(recoil)
        
        // Shell eject
        let shell = SKShapeNode(rectOf: CGSize(width: 4, height: 6))
        shell.fillColor = .yellow
        shell.strokeColor = .orange
        shell.position = CGPoint(
            x: cos(turretNode.zRotation + .pi / 2) * 10,
            y: sin(turretNode.zRotation + .pi / 2) * 10
        )
        shell.zPosition = GameConstants.ZPosition.effects.rawValue
        addChild(shell)
        
        let ejectAngle = turretNode.zRotation + .pi / 2 + CGFloat.random(in: -0.3...0.3)
        let shellAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.move(by: CGVector(
                    dx: cos(ejectAngle) * 30,
                    dy: sin(ejectAngle) * 30 + 20
                ), duration: 0.3),
                SKAction.rotate(byAngle: .pi * 2, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ])
        shell.run(shellAnimation)
    }
    
    private func checkPelletHits(from start: CGPoint, to end: CGPoint, damage: CGFloat, pelletAngle: CGFloat) {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else { return }
        
        for enemy in enemies where enemy.isAlive {
            // Check if enemy is in the pellet's path (simplified cone check)
            let angleToEnemy = start.angle(to: enemy.position)
            let angleDiff = abs(angleToEnemy - pelletAngle)
            let distance = start.distance(to: enemy.position)
            
            // Hit detection: within spread angle and range
            let hitAngle: CGFloat = spreadAngle / CGFloat(pelletCount) * 1.5
            if angleDiff < hitAngle && distance <= range {
                // Damage falloff based on distance
                let falloff = 1.0 - (distance / range) * 0.5  // 50% falloff at max range
                enemy.takeDamage(damage * falloff)
            }
        }
    }
    
    override func getStats() -> [String: String] {
        var stats = super.getStats()
        stats["Pellets"] = "\(pelletCount + upgradeLevel)"
        stats["Spread"] = "\(Int(spreadAngle * 180 / .pi))°"
        stats["Best vs"] = "Clustered"
        return stats
    }
}
