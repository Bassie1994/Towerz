import SpriteKit

/// Sniper Tower (was Laser)
/// Role: Extreme single-target damage, very slow fire rate
/// Single devastating shot that looks like a laser beam
/// DPS = ~3x MachineGun (48 DPS: 600 damage * 0.08 rate)
/// Cannot hit flying units
final class LaserTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 600,     // Massive single-shot damage
        range: 1300,     // Full field range - true sniper
        fireRate: 0.08   // ~1 shot every 12.5 seconds - extremely slow
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
        
        // Find target (ground enemies only - prioritize highest HP)
        updateTarget()
        
        // Aim at target
        if let target = currentTarget {
            aimAt(target)
        }
        
        // Fire when ready (single devastating shot)
        let effectiveFireRate = fireRate * fireRateMultiplier
        let fireInterval = 1.0 / Double(effectiveFireRate)
        
        if currentTime - lastFireTime >= fireInterval {
            if let target = currentTarget, target.isAlive {
                fireSniperShot(at: target)
                lastFireTime = currentTime
            }
        }
        
        // Hide laser after brief display
        if isLaserActive && currentTime - lastDamageTime > 0.15 {
            deactivateLaser()
        }
    }
    
    override func updateTarget() {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else {
            currentTarget = nil
            return
        }
        
        // Filter out flying enemies - sniper targets ground only
        let groundEnemies = enemies.filter { $0.isAlive && $0.enemyType != .flying }
        
        // Prioritize highest HP enemy (sniper should take out big threats)
        currentTarget = groundEnemies.max { $0.currentHealth < $1.currentHealth }
    }
    
    private func fireSniperShot(at target: Enemy) {
        isLaserActive = true
        lastDamageTime = lastFireTime
        
        laserAngle = turretNode.zRotation
        
        // Calculate beam endpoint to target
        let beamEnd = CGPoint(
            x: target.position.x - position.x,
            y: target.position.y - position.y
        )
        
        // Update beam visual - brief intense flash
        let beamPath = CGMutablePath()
        beamPath.move(to: CGPoint(x: towerSize * 0.4, y: 0))
        beamPath.addLine(to: beamEnd)
        
        laserBeam?.path = beamPath
        laserBeam?.isHidden = false
        laserBeam?.alpha = 1.0
        laserBeam?.lineWidth = 6  // Thicker for sniper shot
        
        laserGlow?.path = beamPath
        laserGlow?.isHidden = false
        laserGlow?.alpha = 0.8
        laserGlow?.lineWidth = 16
        
        // Impact marker at target
        laserImpact?.position = beamEnd
        laserImpact?.isHidden = false
        
        // Apply damage to single target (sniper = single target only)
        let effectiveDamage = damage * damageMultiplier
        target.takeDamage(effectiveDamage)
        
        // Big impact effect
        spawnSniperImpact(at: target.position)
        
        // Screen shake effect (subtle)
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 2, y: 0, duration: 0.02),
            SKAction.moveBy(x: -4, y: 0, duration: 0.02),
            SKAction.moveBy(x: 2, y: 0, duration: 0.02)
        ])
        parent?.run(shake)
        
        delegate?.towerDidFire(self, at: target)
    }
    
    private func spawnSniperImpact(at worldPos: CGPoint) {
        guard let parentNode = parent else { return }
        
        // Big impact flash
        let flash = SKShapeNode(circleOfRadius: 25)
        flash.fillColor = .white
        flash.strokeColor = .red
        flash.lineWidth = 4
        flash.position = worldPos
        flash.zPosition = GameConstants.ZPosition.effects.rawValue + 1
        parentNode.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))
        
        // Ring effect
        let ring = SKShapeNode(circleOfRadius: 15)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.8)
        ring.lineWidth = 3
        ring.position = worldPos
        ring.zPosition = GameConstants.ZPosition.effects.rawValue
        parentNode.addChild(ring)
        
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 4.0, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    private func deactivateLaser() {
        isLaserActive = false
        laserBeam?.isHidden = true
        laserGlow?.isHidden = true
        laserImpact?.isHidden = true
    }
    
    // Sniper handles its own firing in update
    override func fire(at target: Enemy, currentTime: TimeInterval) {
        // Handled in fireSniperShot
    }
    
    override func getStats() -> [String: String] {
        var stats = super.getStats()
        stats["Type"] = "Sniper"
        stats["DPS"] = String(format: "%.0f", damage * damageMultiplier * fireRate * fireRateMultiplier)
        stats["Special"] = "Targets highest HP"
        stats["Note"] = "Cannot hit Flying"
        stats["Hint"] = "~12s between shots"
        return stats
    }
}
