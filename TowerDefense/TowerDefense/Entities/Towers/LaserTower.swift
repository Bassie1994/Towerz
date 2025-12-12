import SpriteKit

/// Laser Tower
/// Role: Continuous beam damage in a straight line
/// Hits all enemies in the beam path
/// Cannot hit flying units (beam goes under them)
final class LaserTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 7,       // Nerfed from 15 DPS
        range: 1300,     // Full field range (26 cells * 48 + buffer)
        fireRate: 10.0   // Damage ticks per second
    )
    
    // Laser state
    private var isLaserActive = false
    private var laserAngle: CGFloat = 0
    private var laserBeam: SKShapeNode?
    private var laserGlow: SKShapeNode?
    private var laserImpact: SKShapeNode?
    
    // Damage tracking
    private var lastDamageTime: TimeInterval = 0
    
    init(gridPosition: GridPosition) {
        super.init(
            type: .laser,
            gridPosition: gridPosition,
            damage: LaserTower.stats.damage,
            range: LaserTower.stats.range,
            fireRate: LaserTower.stats.fireRate
        )
        
        setupLaserVisuals()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupTurretVisual() {
        // Crystal emitter design
        let emitter = SKShapeNode(rectOf: CGSize(width: towerSize * 0.3, height: towerSize * 0.15))
        emitter.fillColor = .red
        emitter.strokeColor = .orange
        emitter.lineWidth = 1
        emitter.position = CGPoint(x: towerSize * 0.25, y: 0)
        turretNode.addChild(emitter)
        
        // Core crystal
        let crystal = SKShapeNode(path: createDiamondPath(size: 12))
        crystal.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        crystal.strokeColor = .white
        crystal.lineWidth = 1
        crystal.position = CGPoint(x: towerSize * 0.35, y: 0)
        turretNode.addChild(crystal)
        
        // Pulsing core
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        crystal.run(SKAction.repeatForever(pulse))
    }
    
    private func createDiamondPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size, y: 0))
        path.addLine(to: CGPoint(x: 0, y: size / 2))
        path.addLine(to: CGPoint(x: -size, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -size / 2))
        path.closeSubpath()
        return path
    }
    
    private func setupLaserVisuals() {
        // Main beam
        laserBeam = SKShapeNode()
        laserBeam?.strokeColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.9)
        laserBeam?.lineWidth = 4
        laserBeam?.zPosition = GameConstants.ZPosition.projectile.rawValue
        laserBeam?.isHidden = true
        addChild(laserBeam!)
        
        // Outer glow
        laserGlow = SKShapeNode()
        laserGlow?.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 0.4)
        laserGlow?.lineWidth = 12
        laserGlow?.zPosition = GameConstants.ZPosition.projectile.rawValue - 1
        laserGlow?.isHidden = true
        addChild(laserGlow!)
        
        // Impact point
        laserImpact = SKShapeNode(circleOfRadius: 8)
        laserImpact?.fillColor = .orange
        laserImpact?.strokeColor = .yellow
        laserImpact?.lineWidth = 2
        laserImpact?.zPosition = GameConstants.ZPosition.effects.rawValue
        laserImpact?.isHidden = true
        addChild(laserImpact!)
    }
    
    override func update(currentTime: TimeInterval) {
        // Update buff visual
        if isBuffed {
            if buffIndicator.isHidden {
                buffIndicator.isHidden = false
            }
        } else {
            buffIndicator.isHidden = true
        }
        
        // Find target (ground enemies only)
        updateTarget()
        
        if let target = currentTarget, target.isAlive {
            // Activate laser
            activateLaser(toward: target, currentTime: currentTime)
        } else {
            // Deactivate laser
            deactivateLaser()
        }
    }
    
    override func updateTarget() {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else {
            currentTarget = nil
            return
        }
        
        // Filter out flying enemies - laser goes under them
        let groundEnemies = enemies.filter { $0.isAlive && $0.enemyType != .flying }
        
        // Target closest ground enemy
        currentTarget = groundEnemies.min {
            position.distance(to: $0.position) < position.distance(to: $1.position)
        }
    }
    
    private func activateLaser(toward target: Enemy, currentTime: TimeInterval) {
        isLaserActive = true
        
        // Aim at target
        aimAt(target)
        laserAngle = turretNode.zRotation
        
        // Calculate beam endpoint (extends to range limit or beyond target)
        let beamEnd = CGPoint(
            x: cos(laserAngle) * range,
            y: sin(laserAngle) * range
        )
        
        // Update beam visual
        let beamPath = CGMutablePath()
        beamPath.move(to: CGPoint(x: towerSize * 0.4, y: 0))
        beamPath.addLine(to: beamEnd)
        
        laserBeam?.path = beamPath
        laserBeam?.isHidden = false
        laserGlow?.path = beamPath
        laserGlow?.isHidden = false
        
        // Position impact at target
        laserImpact?.position = CGPoint(
            x: target.position.x - position.x,
            y: target.position.y - position.y
        )
        laserImpact?.isHidden = false
        
        // Apply damage to all enemies in beam path
        let effectiveFireRate = fireRate * fireRateMultiplier
        let damageInterval = 1.0 / Double(effectiveFireRate)
        
        if currentTime - lastDamageTime >= damageInterval {
            applyBeamDamage(angle: laserAngle)
            lastDamageTime = currentTime
            
            // Play sound occasionally
            if Int(currentTime * 10) % 3 == 0 {
                AudioManager.shared.playSound(.laserFire)
            }
        }
        
        // Beam flicker effect
        let flicker = CGFloat.random(in: 0.8...1.0)
        laserBeam?.alpha = flicker
        laserGlow?.alpha = flicker * 0.5
    }
    
    private func applyBeamDamage(angle: CGFloat) {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else { return }
        
        let effectiveDamage = damage * damageMultiplier
        let beamWidth: CGFloat = 20 // How wide the beam hitbox is
        
        for enemy in enemies where enemy.isAlive && enemy.enemyType != .flying {
            // Check if enemy is in beam path
            let relativePos = CGPoint(
                x: enemy.position.x - position.x,
                y: enemy.position.y - position.y
            )
            
            let distance = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
            guard distance <= range else { continue }
            
            // Calculate perpendicular distance from beam
            let enemyAngle = atan2(relativePos.y, relativePos.x)
            let angleDiff = abs(enemyAngle - angle)
            let perpDistance = distance * sin(angleDiff)
            
            if perpDistance <= beamWidth {
                // Enemy is in beam - apply damage
                // Damage is consistent along beam (no falloff)
                enemy.takeDamage(effectiveDamage)
                
                // Spark effect on hit enemy
                spawnSpark(at: enemy.position)
            }
        }
    }
    
    private func spawnSpark(at worldPos: CGPoint) {
        let spark = SKShapeNode(circleOfRadius: 3)
        spark.fillColor = .yellow
        spark.strokeColor = .clear
        spark.position = CGPoint(x: worldPos.x - position.x, y: worldPos.y - position.y)
        spark.zPosition = GameConstants.ZPosition.effects.rawValue
        addChild(spark)
        
        let animation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.1, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ])
        spark.run(animation)
    }
    
    private func deactivateLaser() {
        isLaserActive = false
        laserBeam?.isHidden = true
        laserGlow?.isHidden = true
        laserImpact?.isHidden = true
    }
    
    // Laser tower doesn't use normal fire method
    override func fire(at target: Enemy, currentTime: TimeInterval) {
        // Damage is applied in activateLaser
    }
    
    override func getStats() -> [String: String] {
        var stats = super.getStats()
        stats["Type"] = "Laser"
        stats["DPS"] = String(format: "%.0f", damage * damageMultiplier * fireRate * fireRateMultiplier)
        stats["Special"] = "Piercing beam"
        stats["Note"] = "Cannot hit Flying"
        return stats
    }
}
