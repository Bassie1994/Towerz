import SpriteKit

/// Anti-Air Tower
/// Role: Specialized against flying units
/// Deals bonus damage to flying enemies
/// Can ONLY target flying units
final class AntiAirTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 12,      // Nerfed from 25
        range: 200,      // Good range for air coverage
        fireRate: 3.0    // Fast firing
    )
    
    let flyingDamageMultiplier: CGFloat = 2.5  // 250% damage to flying
    
    // Visual
    private var radarDish: SKShapeNode?
    private var targetingBeams: [SKShapeNode] = []
    
    init(gridPosition: GridPosition) {
        super.init(
            type: .antiAir,
            gridPosition: gridPosition,
            damage: AntiAirTower.stats.damage,
            range: AntiAirTower.stats.range,
            fireRate: AntiAirTower.stats.fireRate
        )
        
        setupRadar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupTurretVisual() {
        // Vertical launcher tubes
        let tube1 = SKShapeNode(rectOf: CGSize(width: towerSize * 0.15, height: towerSize * 0.4))
        tube1.fillColor = SKColor(red: 0.3, green: 0.4, blue: 0.3, alpha: 1.0)
        tube1.strokeColor = .darkGray
        tube1.lineWidth = 1
        tube1.position = CGPoint(x: -6, y: towerSize * 0.15)
        turretNode.addChild(tube1)
        
        let tube2 = SKShapeNode(rectOf: CGSize(width: towerSize * 0.15, height: towerSize * 0.4))
        tube2.fillColor = SKColor(red: 0.3, green: 0.4, blue: 0.3, alpha: 1.0)
        tube2.strokeColor = .darkGray
        tube2.lineWidth = 1
        tube2.position = CGPoint(x: 6, y: towerSize * 0.15)
        turretNode.addChild(tube2)
        
        // Missile tips
        let tip1 = SKShapeNode(path: createMissileTipPath())
        tip1.fillColor = .red
        tip1.strokeColor = .clear
        tip1.position = CGPoint(x: -6, y: towerSize * 0.35)
        turretNode.addChild(tip1)
        
        let tip2 = SKShapeNode(path: createMissileTipPath())
        tip2.fillColor = .red
        tip2.strokeColor = .clear
        tip2.position = CGPoint(x: 6, y: towerSize * 0.35)
        turretNode.addChild(tip2)
    }
    
    private func createMissileTipPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 8))
        path.addLine(to: CGPoint(x: -4, y: 0))
        path.addLine(to: CGPoint(x: 4, y: 0))
        path.closeSubpath()
        return path
    }
    
    private func setupRadar() {
        // Rotating radar dish
        radarDish = SKShapeNode(ellipseOf: CGSize(width: range * 2, height: range * 2))
        radarDish?.fillColor = .clear
        radarDish?.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.15)
        radarDish?.lineWidth = 1
        radarDish?.zPosition = GameConstants.ZPosition.grid.rawValue + 1
        addChild(radarDish!)
        
        // Radar sweep line
        let sweepLine = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: range, y: 0))
        sweepLine.path = path
        sweepLine.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.3)
        sweepLine.lineWidth = 2
        radarDish?.addChild(sweepLine)
        
        // Rotate radar
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
        radarDish?.run(SKAction.repeatForever(rotate))
        
        // Create targeting beams (shown when targeting)
        for _ in 0..<3 {
            let beam = SKShapeNode()
            beam.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.5)
            beam.lineWidth = 1
            beam.isHidden = true
            beam.zPosition = GameConstants.ZPosition.effects.rawValue
            targetingBeams.append(beam)
            addChild(beam)
        }
    }
    
    override func updateTarget() {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else {
            currentTarget = nil
            hideTargetingBeams()
            return
        }
        
        // ONLY target flying enemies
        let flyingEnemies = enemies.filter { $0.isAlive && $0.enemyType == .flying }
        
        if flyingEnemies.isEmpty {
            currentTarget = nil
            hideTargetingBeams()
            return
        }
        
        // Target closest flying enemy
        currentTarget = flyingEnemies.min {
            position.distance(to: $0.position) < position.distance(to: $1.position)
        }
        
        // Show targeting beams
        if currentTarget != nil {
            showTargetingBeams()
        }
    }
    
    private func showTargetingBeams() {
        guard let target = currentTarget else { return }
        
        for (i, beam) in targetingBeams.enumerated() {
            beam.isHidden = false
            
            // Create converging beam effect
            let offset = CGFloat(i - 1) * 15
            let startPoint = CGPoint(x: offset, y: towerSize * 0.4)
            let endPoint = CGPoint(
                x: target.position.x - position.x,
                y: target.position.y - position.y
            )
            
            let path = CGMutablePath()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            beam.path = path
            
            // Flicker
            beam.alpha = CGFloat.random(in: 0.3...0.6)
        }
    }
    
    private func hideTargetingBeams() {
        for beam in targetingBeams {
            beam.isHidden = true
        }
    }
    
    override func fire(at target: Enemy, currentTime: TimeInterval) {
        guard target.enemyType == .flying else { return }
        
        delegate?.towerDidFire(self, at: target)
        AudioManager.shared.playSound(.antiAirFire)
        
        // Calculate damage with flying bonus
        let effectiveDamage = damage * damageMultiplier * flyingDamageMultiplier
        
        // Create homing missile
        let missile = AntiAirMissile(
            from: position,
            to: target,
            damage: effectiveDamage
        )
        parent?.addChild(missile)
        
        // Launch effect
        for i in 0..<2 {
            let smoke = SKShapeNode(circleOfRadius: 5)
            smoke.fillColor = .gray
            smoke.strokeColor = .clear
            smoke.alpha = 0.7
            smoke.position = CGPoint(x: CGFloat(i * 12 - 6), y: towerSize * 0.3)
            smoke.zPosition = GameConstants.ZPosition.effects.rawValue
            addChild(smoke)
            
            let animation = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: 0, y: -20, duration: 0.3),
                    SKAction.scale(to: 2.0, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ])
            smoke.run(animation)
        }
    }
    
    override func aimAt(_ target: Enemy) {
        // Anti-air tower doesn't rotate - missiles track
        // Just keep turret pointing up
        turretNode.zRotation = .pi / 2
    }
    
    override func getStats() -> [String: String] {
        var stats = super.getStats()
        stats["Type"] = "Anti-Air"
        stats["vs Flying"] = "+\(Int((flyingDamageMultiplier - 1) * 100))% damage"
        stats["Special"] = "Only targets Flying"
        return stats
    }
}

// MARK: - Anti-Air Missile

class AntiAirMissile: SKNode {
    
    let damage: CGFloat
    weak var target: Enemy?
    let speed: CGFloat = 500
    
    private let missileNode: SKShapeNode
    private var hasHit = false
    
    init(from startPosition: CGPoint, to target: Enemy, damage: CGFloat) {
        self.damage = damage
        self.target = target
        
        // Create missile shape
        missileNode = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 8))
        path.addLine(to: CGPoint(x: -3, y: -4))
        path.addLine(to: CGPoint(x: 3, y: -4))
        path.closeSubpath()
        missileNode.path = path
        missileNode.fillColor = .red
        missileNode.strokeColor = .orange
        missileNode.lineWidth = 1
        
        super.init()
        
        position = startPosition
        zPosition = GameConstants.ZPosition.projectile.rawValue
        addChild(missileNode)
        
        // Start tracking
        let trackAction = SKAction.customAction(withDuration: 5.0) { [weak self] _, _ in
            self?.updateTracking()
        }
        run(trackAction, withKey: "track")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateTracking() {
        guard !hasHit else { return }
        
        guard let target = target, target.isAlive else {
            // Lost target - self destruct
            explode()
            return
        }
        
        // Calculate direction to target
        let direction = CGVector(
            dx: target.position.x - position.x,
            dy: target.position.y - position.y
        )
        
        let distance = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
        
        // Hit detection
        if distance < 20 {
            hit()
            return
        }
        
        // Home toward target
        let normalizedDir = CGVector(dx: direction.dx / distance, dy: direction.dy / distance)
        let moveSpeed = speed / 60.0
        
        position = CGPoint(
            x: position.x + normalizedDir.dx * moveSpeed,
            y: position.y + normalizedDir.dy * moveSpeed
        )
        
        // Rotate to face direction
        zRotation = atan2(normalizedDir.dy, normalizedDir.dx) - .pi / 2
        
        // Trail
        createTrail()
    }
    
    private func createTrail() {
        let trail = SKShapeNode(circleOfRadius: 2)
        trail.fillColor = .orange
        trail.strokeColor = .clear
        trail.alpha = 0.7
        trail.position = position
        trail.zPosition = zPosition - 1
        parent?.addChild(trail)
        
        let fade = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ])
        trail.run(fade)
    }
    
    private func hit() {
        guard !hasHit else { return }
        hasHit = true
        
        target?.takeDamage(damage)
        explode()
    }
    
    private func explode() {
        removeAction(forKey: "track")
        
        // Explosion effect
        let explosion = SKShapeNode(circleOfRadius: 15)
        explosion.fillColor = .orange
        explosion.strokeColor = .yellow
        explosion.lineWidth = 2
        explosion.position = position
        explosion.zPosition = GameConstants.ZPosition.effects.rawValue
        parent?.addChild(explosion)
        
        let animation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ])
        explosion.run(animation)
        
        removeFromParent()
    }
}
