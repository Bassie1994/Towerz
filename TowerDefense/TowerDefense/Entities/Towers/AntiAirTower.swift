import SpriteKit

/// Anti-Air Tower
/// Role: Specialized against flying units
/// Deals bonus damage to flying enemies
/// Can ONLY target flying units
final class AntiAirTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 12,      // 2x damage - harder hits
        range: 200,      // Good range for air coverage
        fireRate: 1.5    // /2 fire rate - slower but stronger
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
        // AudioManager.shared.playSound(.antiAirFire)
        
        // Calculate damage with flying bonus
        let effectiveDamage = damage * damageMultiplier * flyingDamageMultiplier
        
        // Create homing missile - add to scene's gameLayer for proper update
        let missile = AntiAirMissile(
            from: position,
            to: target,
            damage: effectiveDamage
        )
        // Add to parent's parent (gameLayer) so it gets updated properly
        if let towerLayer = parent, let gameLayer = towerLayer.parent {
            gameLayer.addChild(missile)
        } else {
            parent?.addChild(missile)
        }
        
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
    let missileSpeed: CGFloat = 500
    
    private let missileNode: SKShapeNode
    private let thrusterNode: SKShapeNode
    private var hasHit = false
    private var lastTrailTime: TimeInterval = 0
    
    init(from startPosition: CGPoint, to target: Enemy, damage: CGFloat) {
        self.damage = damage
        self.target = target
        
        // Create missile shape - more detailed
        missileNode = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 10))
        path.addLine(to: CGPoint(x: -4, y: -2))
        path.addLine(to: CGPoint(x: -2, y: -2))
        path.addLine(to: CGPoint(x: -2, y: -6))
        path.addLine(to: CGPoint(x: 2, y: -6))
        path.addLine(to: CGPoint(x: 2, y: -2))
        path.addLine(to: CGPoint(x: 4, y: -2))
        path.closeSubpath()
        missileNode.path = path
        missileNode.fillColor = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
        missileNode.strokeColor = .darkGray
        missileNode.lineWidth = 1
        
        // Thruster glow
        thrusterNode = SKShapeNode(circleOfRadius: 4)
        thrusterNode.fillColor = .orange
        thrusterNode.strokeColor = .yellow
        thrusterNode.lineWidth = 1
        thrusterNode.position = CGPoint(x: 0, y: -8)
        
        super.init()
        
        position = startPosition
        zPosition = GameConstants.ZPosition.projectile.rawValue
        addChild(missileNode)
        missileNode.addChild(thrusterNode)
        
        // Thruster flicker animation
        let flicker = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.05),
            SKAction.scale(to: 0.8, duration: 0.05)
        ])
        thrusterNode.run(SKAction.repeatForever(flicker))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Call this every frame from the scene's update loop
    func update(currentTime: TimeInterval) {
        guard !hasHit else { return }
        
        guard let target = target, target.isAlive else {
            // Lost target - self destruct
            explode()
            return
        }
        
        // Calculate direction to target's CURRENT position (tracking!)
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
        
        // Home toward target with smooth rotation
        let normalizedDir = CGVector(dx: direction.dx / distance, dy: direction.dy / distance)
        let moveSpeed = missileSpeed / 60.0
        
        position = CGPoint(
            x: position.x + normalizedDir.dx * moveSpeed,
            y: position.y + normalizedDir.dy * moveSpeed
        )
        
        // Smooth rotation to face direction
        let targetRotation = atan2(normalizedDir.dy, normalizedDir.dx) - .pi / 2
        let rotationDiff = targetRotation - zRotation
        zRotation += rotationDiff * 0.3  // Smooth turning
        
        // Trail every few frames
        if currentTime - lastTrailTime > 0.02 {
            createTrail()
            lastTrailTime = currentTime
        }
    }
    
    private func createTrail() {
        let trail = SKShapeNode(circleOfRadius: 3)
        trail.fillColor = .orange
        trail.strokeColor = .clear
        trail.alpha = 0.8
        trail.position = position
        trail.zPosition = zPosition - 1
        parent?.addChild(trail)
        
        let fade = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.3, duration: 0.2)
            ]),
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
        // Explosion effect
        let explosion = SKShapeNode(circleOfRadius: 20)
        explosion.fillColor = .orange
        explosion.strokeColor = .yellow
        explosion.lineWidth = 3
        explosion.position = position
        explosion.zPosition = GameConstants.ZPosition.effects.rawValue
        parent?.addChild(explosion)
        
        let animation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.5, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        explosion.run(animation)
        
        // Debris
        for _ in 0..<6 {
            let debris = SKShapeNode(circleOfRadius: 2)
            debris.fillColor = [.orange, .yellow, .red].randomElement()!
            debris.strokeColor = .clear
            debris.position = position
            debris.zPosition = GameConstants.ZPosition.effects.rawValue
            parent?.addChild(debris)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 20...40)
            let debrisAnim = SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: CGPoint(x: position.x + cos(angle) * dist, y: position.y + sin(angle) * dist), duration: 0.25),
                    SKAction.fadeOut(withDuration: 0.25)
                ]),
                SKAction.removeFromParent()
            ])
            debris.run(debrisAnim)
        }
        
        removeFromParent()
    }
}
