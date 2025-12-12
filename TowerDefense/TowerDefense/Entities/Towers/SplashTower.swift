import SpriteKit

/// Splash Damage Tower
/// Role: Area of Effect damage on impact
/// Good against groups, less effective single-target DPS
/// Type: Projectile with explosion on impact
final class SplashTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 30,
        range: 160,
        fireRate: 0.7  // Slow firing
    )
    
    var splashRadius: CGFloat = 60
    var splashDamageFalloff: CGFloat = 0.5  // Enemies at edge take 50% damage
    
    init(gridPosition: GridPosition) {
        super.init(
            type: .splash,
            gridPosition: gridPosition,
            damage: SplashTower.stats.damage,
            range: SplashTower.stats.range,
            fireRate: SplashTower.stats.fireRate
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupTurretVisual() {
        // Mortar-style design
        let tube = SKShapeNode(rectOf: CGSize(width: towerSize * 0.25, height: towerSize * 0.4))
        tube.fillColor = SKColor(red: 0.5, green: 0.4, blue: 0.5, alpha: 1.0)
        tube.strokeColor = .darkGray
        tube.lineWidth = 1
        tube.position = CGPoint(x: towerSize * 0.15, y: 0)
        tube.zRotation = .pi / 6  // Angled up
        turretNode.addChild(tube)
        
        // Base plate
        let basePlate = SKShapeNode(rectOf: CGSize(width: towerSize * 0.5, height: towerSize * 0.15))
        basePlate.fillColor = .darkGray
        basePlate.strokeColor = .clear
        basePlate.position = CGPoint(x: 0, y: -5)
        turretNode.addChild(basePlate)
        
        // Ammo indicator
        let ammo = SKShapeNode(circleOfRadius: 5)
        ammo.fillColor = .red
        ammo.strokeColor = .orange
        ammo.position = CGPoint(x: -10, y: 5)
        turretNode.addChild(ammo)
    }
    
    override func updateTarget() {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else {
            currentTarget = nil
            return
        }
        
        // Splash cannot hit flying enemies - explosion is ground-level
        let groundEnemies = enemies.filter { $0.isAlive && $0.enemyType != .flying }
        guard !groundEnemies.isEmpty else {
            currentTarget = nil
            return
        }
        
        // Find the position that would hit the most enemies
        var bestTarget: Enemy?
        var bestScore = 0
        
        for enemy in groundEnemies {
            var score = 1
            // Count how many other ground enemies would be hit by splash
            for other in groundEnemies {
                if other.id != enemy.id {
                    let distance = enemy.position.distance(to: other.position)
                    if distance <= splashRadius {
                        score += 1
                    }
                }
            }
            
            if score > bestScore {
                bestScore = score
                bestTarget = enemy
            }
        }
        
        currentTarget = bestTarget ?? groundEnemies.first
    }
    
    override func fire(at target: Enemy, currentTime: TimeInterval) {
        delegate?.towerDidFire(self, at: target)
        AudioManager.shared.playSound(.splashFire)
        
        // Create arcing projectile
        let projectile = SplashProjectile(
            from: position,
            to: target.position,
            damage: damage * damageMultiplier,
            splashRadius: splashRadius + CGFloat(upgradeLevel) * 10,
            splashFalloff: splashDamageFalloff
        ) { [weak self] impactPosition in
            self?.handleSplashImpact(at: impactPosition)
        }
        parent?.addChild(projectile)
        
        // Mortar launch effect
        let smokeRing = SKShapeNode(circleOfRadius: 8)
        smokeRing.fillColor = .gray
        smokeRing.strokeColor = .clear
        smokeRing.alpha = 0.6
        smokeRing.position = CGPoint(
            x: cos(turretNode.zRotation + .pi / 6) * towerSize * 0.3,
            y: sin(turretNode.zRotation + .pi / 6) * towerSize * 0.3
        )
        smokeRing.zPosition = GameConstants.ZPosition.effects.rawValue
        addChild(smokeRing)
        
        let smokeAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ])
        smokeRing.run(smokeAnimation)
        
        // Recoil
        let recoil = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -4, duration: 0.05),
            SKAction.moveBy(x: 0, y: 4, duration: 0.2)
        ])
        turretNode.run(recoil)
    }
    
    private func handleSplashImpact(at impactPosition: CGPoint) {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else { return }
        
        let effectiveSplashRadius = splashRadius + CGFloat(upgradeLevel) * 10
        let effectiveDamage = damage * damageMultiplier
        
        // Damage all ground enemies in splash radius (flying are above explosion)
        for enemy in enemies where enemy.isAlive && enemy.enemyType != .flying {
            let distance = impactPosition.distance(to: enemy.position)
            if distance <= effectiveSplashRadius {
                // Calculate damage with falloff
                let falloffFactor = 1.0 - (distance / effectiveSplashRadius) * splashDamageFalloff
                let actualDamage = effectiveDamage * falloffFactor
                enemy.takeDamage(actualDamage)
            }
        }
        
        // Explosion visual
        createExplosion(at: impactPosition, radius: effectiveSplashRadius)
    }
    
    private func createExplosion(at position: CGPoint, radius: CGFloat) {
        // Main explosion
        let explosion = SKShapeNode(circleOfRadius: radius * 0.3)
        explosion.fillColor = .orange
        explosion.strokeColor = .yellow
        explosion.lineWidth = 3
        explosion.position = position
        explosion.zPosition = GameConstants.ZPosition.effects.rawValue
        parent?.addChild(explosion)
        
        let explosionAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: radius / (radius * 0.3), duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        explosion.run(explosionAnimation)
        
        // Inner flash
        let flash = SKShapeNode(circleOfRadius: radius * 0.2)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.position = position
        flash.zPosition = GameConstants.ZPosition.effects.rawValue + 1
        parent?.addChild(flash)
        
        let flashAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ])
        flash.run(flashAnimation)
        
        // Debris particles
        for _ in 0..<8 {
            let debris = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            debris.fillColor = [.orange, .red, .yellow].randomElement()!
            debris.strokeColor = .clear
            debris.position = position
            debris.zPosition = GameConstants.ZPosition.effects.rawValue
            parent?.addChild(debris)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: radius * 0.5...radius)
            let destination = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let debrisAnimation = SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: destination, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 0.1, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ])
            debris.run(debrisAnimation)
        }
    }
    
    override func upgrade() -> Bool {
        let result = super.upgrade()
        
        if result {
            splashRadius = 60 + CGFloat(upgradeLevel) * 10
        }
        
        return result
    }
    
    override func getStats() -> [String: String] {
        var stats = super.getStats()
        stats["Splash Radius"] = String(format: "%.0f", splashRadius + CGFloat(upgradeLevel) * 10)
        stats["Best vs"] = "Groups"
        stats["Note"] = "Cannot hit Flying"
        return stats
    }
}

// MARK: - Splash Projectile

class SplashProjectile: SKNode {
    
    let impactCallback: (CGPoint) -> Void
    let targetPosition: CGPoint
    let damage: CGFloat
    let splashRadius: CGFloat
    
    private let projectileNode: SKShapeNode
    
    init(from startPosition: CGPoint, to targetPosition: CGPoint, damage: CGFloat, splashRadius: CGFloat, splashFalloff: CGFloat, onImpact: @escaping (CGPoint) -> Void) {
        self.targetPosition = targetPosition
        self.damage = damage
        self.splashRadius = splashRadius
        self.impactCallback = onImpact
        
        projectileNode = SKShapeNode(circleOfRadius: 6)
        projectileNode.fillColor = .red
        projectileNode.strokeColor = .orange
        projectileNode.lineWidth = 2
        
        super.init()
        
        position = startPosition
        zPosition = GameConstants.ZPosition.projectile.rawValue
        addChild(projectileNode)
        
        // Calculate arc trajectory
        let distance = startPosition.distance(to: targetPosition)
        let duration = TimeInterval(distance / 300)  // Speed of projectile
        let arcHeight = distance * 0.3  // Height of arc
        
        // Create arc path
        let path = CGMutablePath()
        path.move(to: .zero)
        
        let midPoint = CGPoint(
            x: (targetPosition.x - startPosition.x) / 2,
            y: (targetPosition.y - startPosition.y) / 2 + arcHeight
        )
        let endPoint = CGPoint(
            x: targetPosition.x - startPosition.x,
            y: targetPosition.y - startPosition.y
        )
        
        path.addQuadCurve(to: endPoint, control: midPoint)
        
        // Follow path
        let followPath = SKAction.follow(path, asOffset: true, orientToPath: false, duration: duration)
        
        // Trail effect
        let trailAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                self?.createTrailParticle()
            },
            SKAction.wait(forDuration: 0.03)
        ]))
        
        // Spin
        let spin = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 0.3))
        projectileNode.run(spin)
        
        run(trailAction, withKey: "trail")
        
        run(SKAction.sequence([
            followPath,
            SKAction.run { [weak self] in
                self?.impact()
            }
        ]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createTrailParticle() {
        let trail = SKShapeNode(circleOfRadius: 3)
        trail.fillColor = .orange
        trail.strokeColor = .clear
        trail.alpha = 0.6
        trail.position = position
        trail.zPosition = GameConstants.ZPosition.projectile.rawValue - 1
        parent?.addChild(trail)
        
        let fade = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.1, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        trail.run(fade)
    }
    
    private func impact() {
        removeAction(forKey: "trail")
        impactCallback(targetPosition)
        removeFromParent()
    }
}
