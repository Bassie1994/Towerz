import SpriteKit

/// Mine Tower
/// Role: Places mines that explode when enemies walk over them
/// Mines deal splash damage to nearby enemies
/// Best against: Groups of ground enemies
final class MineTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 20,      // Damage per mine explosion (20% reduction)
        range: GameConstants.cellSize * 1.5,      // Adjacent cells only
        fireRate: 0.5    // 1 mine every 2 seconds
    )

    var splashRadius: CGFloat = 50
    static let mineLifetime: TimeInterval = 30
    private var mines: [Mine] = []
    private let maxMinesPerTower = 50  // Max 50 mines per tower, no global limit
    private var pendingMineRemovals: [Mine] = []
    private let mineCounterLabel: SKLabelNode

    init(gridPosition: GridPosition) {
        mineCounterLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        mineCounterLabel.fontSize = 12
        mineCounterLabel.fontColor = .white
        mineCounterLabel.position = CGPoint(x: 0, y: GameConstants.cellSize * 0.4)
        mineCounterLabel.text = "0"

        super.init(
            type: .mine,
            gridPosition: gridPosition,
            damage: MineTower.stats.damage,
            range: MineTower.stats.range,
            fireRate: MineTower.stats.fireRate
        )

        addChild(mineCounterLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupTurretVisual() {
        // Mine deployer design
        let deployer = SKShapeNode(rectOf: CGSize(width: towerSize * 0.4, height: towerSize * 0.3))
        deployer.fillColor = SKColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0)
        deployer.strokeColor = .darkGray
        deployer.lineWidth = 1
        turretNode.addChild(deployer)
        
        // Mine indicator lights
        for i in 0..<3 {
            let light = SKShapeNode(circleOfRadius: 3)
            light.fillColor = .red
            light.strokeColor = .clear
            light.position = CGPoint(x: CGFloat(i - 1) * 8, y: towerSize * 0.2)
            turretNode.addChild(light)
            
            // Blinking animation
            let delay = Double(i) * 0.3
            let blink = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.3, duration: 0.4),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.4)
                ]))
            ])
            light.run(blink)
        }
        
        // Conveyor belt visual
        let belt = SKShapeNode(rectOf: CGSize(width: towerSize * 0.5, height: towerSize * 0.1))
        belt.fillColor = .darkGray
        belt.strokeColor = .black
        belt.lineWidth = 1
        belt.position = CGPoint(x: 0, y: -towerSize * 0.15)
        turretNode.addChild(belt)
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
        
        // Check mines for enemy proximity
        checkMinesForDetonation()

        // Clean up any mines that detonated or degraded this frame
        processPendingMineRemovals()
        
        // Place new mines periodically
        let effectiveFireRate = fireRate * fireRateMultiplier
        let fireInterval = 1.0 / Double(effectiveFireRate)
        
        if currentTime - lastFireTime >= fireInterval {
            placeMine()
            lastFireTime = currentTime
        }
        
        // Don't call super - we handle our own logic
    }
    
    private func placeMine() {
        // Check per-tower limit (50 max per tower)
        guard mines.count < maxMinesPerTower else { return }
        
        // Find a valid position within range (not on a tower)
        guard let validPosition = findValidMinePosition() else { return }
        
        // Create and place mine
        let mine = Mine(
            position: validPosition,
            damage: damage * damageMultiplier,
            splashRadius: splashRadius + CGFloat(upgradeLevel) * 10
        )
        mine.owner = self
        parent?.addChild(mine)
        mines.append(mine)
        updateMineCounter()
        
        // Show launch animation from tower to mine
        spawnLaunchAnimation(to: validPosition)
    }
    
    private func findValidMinePosition() -> CGPoint? {
        var availableCells: [GridPosition] = []

        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let candidate = GridPosition(x: gridPosition.x + dx, y: gridPosition.y + dy)

                guard candidate.x >= 0 && candidate.x < GameConstants.gridWidth &&
                        candidate.y >= 0 && candidate.y < GameConstants.gridHeight else { continue }

                let cellCenter = candidate.toWorldPosition()

                var hasTower = false
                if let allTowers = delegate?.getAllTowers() {
                    for tower in allTowers where tower.position.distance(to: cellCenter) < GameConstants.cellSize * 0.4 {
                        hasTower = true
                        break
                    }
                }

                if !hasTower {
                    availableCells.append(candidate)
                }
            }
        }

        guard let candidate = availableCells.randomElement() else { return nil }

        // Add small random offset for visual stacking variety
        let stackOffset = CGPoint(
            x: CGFloat.random(in: -8...8),
            y: CGFloat.random(in: -8...8)
        )
        let cellCenter = candidate.toWorldPosition()
        return CGPoint(x: cellCenter.x + stackOffset.x, y: cellCenter.y + stackOffset.y)
    }
    
    private func checkMinesForDetonation() {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else { return }
        
        var minesToRemove: [Mine] = []
        
        for mine in mines {
            for enemy in enemies where enemy.isAlive && enemy.enemyType != .flying {
                let distance = mine.position.distance(to: enemy.position)
                if distance < 25 {  // Trigger radius
                    mine.detonate(enemies: enemies)
                    minesToRemove.append(mine)
                    break
                }
            }
        }
        
        // Clean up detonated mines
        for mine in minesToRemove {
            queueMineRemoval(mine)
        }
    }

    func detonateAllMines() {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else { return }
        for mine in mines { mine.detonate(enemies: enemies) }
    }

    func clearAllMines() {
        for mine in mines {
            mine.fadeOut()
        }
        mines.removeAll()
        pendingMineRemovals.removeAll()
        updateMineCounter()
    }

    func getActiveMineCount() -> Int {
        return mines.count
    }
    
    /// Animate mine launching from tower to target position
    private func spawnLaunchAnimation(to targetPos: CGPoint) {
        guard let parentNode = parent else { return }
        
        // Create projectile that travels from tower to mine position
        let projectile = SKShapeNode(circleOfRadius: 6)
        projectile.fillColor = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        projectile.strokeColor = .red
        projectile.lineWidth = 2
        projectile.position = position
        projectile.zPosition = GameConstants.ZPosition.projectile.rawValue
        parentNode.addChild(projectile)
        
        // Calculate arc trajectory
        let distance = position.distance(to: targetPos)
        let duration = TimeInterval(distance / 400)  // Speed
        let arcHeight = distance * 0.4  // Height of arc
        
        // Create arc path
        let midPoint = CGPoint(
            x: (position.x + targetPos.x) / 2,
            y: (position.y + targetPos.y) / 2 + arcHeight
        )
        
        let path = CGMutablePath()
        path.move(to: position)
        path.addQuadCurve(to: targetPos, control: midPoint)
        
        // Trail effect while flying
        let trailAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak projectile, weak parentNode] in
                guard let proj = projectile, let parent = parentNode else { return }
                let trail = SKShapeNode(circleOfRadius: 3)
                trail.fillColor = .orange
                trail.strokeColor = .clear
                trail.alpha = 0.6
                trail.position = proj.position
                trail.zPosition = GameConstants.ZPosition.effects.rawValue
                parent.addChild(trail)
                
                trail.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.fadeOut(withDuration: 0.15),
                        SKAction.scale(to: 0.3, duration: 0.15)
                    ]),
                    SKAction.removeFromParent()
                ]))
            },
            SKAction.wait(forDuration: 0.03)
        ]))
        projectile.run(trailAction, withKey: "trail")
        
        // Follow path and land
        let followPath = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        let spin = SKAction.rotate(byAngle: .pi * 4, duration: duration)
        
        projectile.run(SKAction.sequence([
            SKAction.group([followPath, spin]),
            SKAction.run { [weak projectile] in
                projectile?.removeAction(forKey: "trail")
            },
            SKAction.removeFromParent()
        ]))
        
        // Spawn landing effect at target
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak parentNode] in
            guard let parent = parentNode else { return }
            
            let landEffect = SKShapeNode(circleOfRadius: 8)
            landEffect.fillColor = .orange
            landEffect.strokeColor = .yellow
            landEffect.lineWidth = 2
            landEffect.position = targetPos
            landEffect.zPosition = GameConstants.ZPosition.effects.rawValue
            parent.addChild(landEffect)
            
            landEffect.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 2.5, duration: 0.2),
                    SKAction.fadeOut(withDuration: 0.2)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    override func upgrade() -> Bool {
        let result = super.upgrade()
        
        if result {
            splashRadius = 50 + CGFloat(upgradeLevel) * 10
        }
        
        return result
    }
    
    /// Called when tower is removed - clean up mines
    func removeAllMines() {
        for mine in mines {
            mine.removeFromParent()
        }
        mines.removeAll()
        pendingMineRemovals.removeAll()
        updateMineCounter()
    }

    func queueMineRemoval(_ mine: Mine) {
        pendingMineRemovals.append(mine)
    }

    private func processPendingMineRemovals() {
        guard !pendingMineRemovals.isEmpty else { return }

        for mine in pendingMineRemovals {
            mines.removeAll { $0 === mine }
        }

        pendingMineRemovals.removeAll()
        updateMineCounter()
    }

    private func updateMineCounter() {
        mineCounterLabel.text = "\(mines.count)"
        let fillRatio = CGFloat(mines.count) / CGFloat(maxMinesPerTower)
        mineCounterLabel.fontColor = fillRatio > 0.8 ? .red : .white
    }
    
    // Not used for mine tower
    override func fire(at target: Enemy, currentTime: TimeInterval) {
        // Mines handle damage, not direct firing
    }
    
    override func getStats() -> [String: String] {
        var stats = super.getStats()
        stats["Type"] = "Mine Layer"
        stats["Splash Radius"] = String(format: "%.0f", splashRadius + CGFloat(upgradeLevel) * 10)
        stats["Mines Active"] = "\(mines.count)/\(maxMinesPerTower)"
        stats["Lifetime"] = String(format: "%.0fs", MineTower.mineLifetime)
        stats["Best vs"] = "Groups"
        stats["Note"] = "Cannot hit Flying"
        return stats
    }
}

// MARK: - Mine

class Mine: SKNode {
    
    let damage: CGFloat
    let splashRadius: CGFloat
    weak var owner: MineTower?
    
    private let mineNode: SKShapeNode
    private var hasDetonated = false
    private let lifetimeRing: SKShapeNode

    init(position: CGPoint, damage: CGFloat, splashRadius: CGFloat) {
        self.damage = damage
        self.splashRadius = splashRadius

        // Create mine visual
        mineNode = SKShapeNode(circleOfRadius: 8)
        mineNode.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        mineNode.strokeColor = .red
        mineNode.lineWidth = 2

        lifetimeRing = SKShapeNode(circleOfRadius: 12)
        lifetimeRing.strokeColor = SKColor.yellow.withAlphaComponent(0.3)
        lifetimeRing.fillColor = .clear
        lifetimeRing.lineWidth = 2

        super.init()

        self.position = position
        zPosition = GameConstants.ZPosition.grid.rawValue + 2
        addChild(mineNode)
        addChild(lifetimeRing)
        
        // Add detail - trigger plate
        let trigger = SKShapeNode(circleOfRadius: 4)
        trigger.fillColor = SKColor(red: 0.5, green: 0.1, blue: 0.1, alpha: 1.0)
        trigger.strokeColor = .clear
        mineNode.addChild(trigger)
        
        // Warning light
        let light = SKShapeNode(circleOfRadius: 2)
        light.fillColor = .red
        light.strokeColor = .clear
        light.position = CGPoint(x: 0, y: 4)
        mineNode.addChild(light)
        
        // Blinking animation
        let blink = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        light.run(SKAction.repeatForever(blink))
        
        // Entry animation
        let enter = SKAction.sequence([
            SKAction.scale(to: 0.1, duration: 0),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        run(enter)

        animateLifetimeRing()

        startDegradeCountdown()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func detonate(enemies: [Enemy]) {
        guard !hasDetonated else { return }
        hasDetonated = true
        
        // Deal splash damage to all ground enemies in radius
        for enemy in enemies where enemy.isAlive && enemy.enemyType != .flying {
            let distance = position.distance(to: enemy.position)
            if distance <= splashRadius {
                // Damage falloff based on distance
                let falloff = 1.0 - (distance / splashRadius) * 0.5
                enemy.takeDamage(damage * falloff)
            }
        }
        
        // Explosion visual
        createExplosion()
        
        owner?.queueMineRemoval(self)
        removeFromParent()
    }

    func fadeOut() {
        guard !hasDetonated else { return }
        hasDetonated = true
        let fade = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 0.2, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ])
        owner?.queueMineRemoval(self)
        run(fade)
    }

    private func createExplosion() {
        guard let parent = parent else { return }
        
        // Main explosion
        let explosion = SKShapeNode(circleOfRadius: splashRadius * 0.3)
        explosion.fillColor = .orange
        explosion.strokeColor = .yellow
        explosion.lineWidth = 3
        explosion.position = position
        explosion.zPosition = GameConstants.ZPosition.effects.rawValue
        parent.addChild(explosion)
        
        let explosionAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: splashRadius / (splashRadius * 0.3), duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ])
        explosion.run(explosionAnimation)
        
        // Dirt/debris particles
        for _ in 0..<10 {
            let debris = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            debris.fillColor = [.brown, .darkGray, .orange].randomElement()!
            debris.strokeColor = .clear
            debris.position = position
            debris.zPosition = GameConstants.ZPosition.effects.rawValue
            parent.addChild(debris)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: splashRadius * 0.3...splashRadius * 0.8)
            let destination = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance + 20  // Upward arc
            )
            
            let debrisAnimation = SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: destination, duration: 0.25),
                    SKAction.fadeOut(withDuration: 0.25),
                    SKAction.scale(to: 0.2, duration: 0.25)
                ]),
                SKAction.removeFromParent()
            ])
            debris.run(debrisAnimation)
        }
        
        // Shockwave ring
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.8)
        ring.lineWidth = 3
        ring.position = position
        ring.zPosition = GameConstants.ZPosition.effects.rawValue
        parent.addChild(ring)
        
        let ringAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: splashRadius / 10, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        ring.run(ringAnimation)
    }

    private func startDegradeCountdown() {
        let degradeAction = SKAction.sequence([
            SKAction.wait(forDuration: MineTower.mineLifetime),
            SKAction.run { [weak self] in
                self?.degrade()
            }
        ])

        run(degradeAction, withKey: "degrade")
    }

    private func animateLifetimeRing() {
        let shrink = SKAction.sequence([
            SKAction.scale(to: 0.1, duration: MineTower.mineLifetime),
            SKAction.removeFromParent()
        ])
        lifetimeRing.run(shrink)
    }

    private func degrade() {
        guard !hasDetonated else { return }
        hasDetonated = true

        // Visual fade to indicate deterioration
        let fadeOut = SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 0.2, duration: 0.5),
                SKAction.scale(to: 0.5, duration: 0.5)
            ]),
            SKAction.removeFromParent()
        ])

        owner?.queueMineRemoval(self)
        run(fadeOut)
    }
}
