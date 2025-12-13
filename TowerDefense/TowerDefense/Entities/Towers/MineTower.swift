import SpriteKit

/// Mine Tower
/// Role: Places mines that explode when enemies walk over them
/// Mines deal splash damage to nearby enemies
/// Best against: Groups of ground enemies
final class MineTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 25,      // Damage per mine explosion
        range: 120,      // Range to place mines
        fireRate: 0.5    // 1 mine every 2 seconds
    )
    
    static let maxTotalMines = 50  // Max mines across all mine towers
    static var currentMineCount = 0
    
    var splashRadius: CGFloat = 50
    private var mines: [Mine] = []
    private let maxMinesPerTower = 15
    
    init(gridPosition: GridPosition) {
        super.init(
            type: .mine,
            gridPosition: gridPosition,
            damage: MineTower.stats.damage,
            range: MineTower.stats.range,
            fireRate: MineTower.stats.fireRate
        )
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
        // Check global mine limit
        guard MineTower.currentMineCount < MineTower.maxTotalMines else { return }
        
        // Check per-tower limit
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
        MineTower.currentMineCount += 1
        
        // Deploy animation
        spawnDeployEffect(at: validPosition)
    }
    
    private func findValidMinePosition() -> CGPoint? {
        // Try random positions within range
        for _ in 0..<20 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...range)
            
            let candidatePos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            // Convert to grid position
            let gridX = Int((candidatePos.x - GameConstants.playFieldOrigin.x) / GameConstants.cellSize)
            let gridY = Int((candidatePos.y - GameConstants.playFieldOrigin.y) / GameConstants.cellSize)
            
            // Check bounds
            guard gridX >= 0 && gridX < GameConstants.gridWidth &&
                  gridY >= 0 && gridY < GameConstants.gridHeight else { continue }
            
            // Check if there's already a tower here
            let cellCenter = CGPoint(
                x: GameConstants.playFieldOrigin.x + CGFloat(gridX) * GameConstants.cellSize + GameConstants.cellSize / 2,
                y: GameConstants.playFieldOrigin.y + CGFloat(gridY) * GameConstants.cellSize + GameConstants.cellSize / 2
            )
            
            var hasTower = false
            if let allTowers = delegate?.getAllTowers() {
                for tower in allTowers {
                    if tower.position.distance(to: cellCenter) < GameConstants.cellSize * 0.6 {
                        hasTower = true
                        break
                    }
                }
            }
            
            // Also check if there's already a mine nearby
            var hasMine = false
            for mine in mines {
                if mine.position.distance(to: candidatePos) < GameConstants.cellSize * 0.8 {
                    hasMine = true
                    break
                }
            }
            
            if !hasTower && !hasMine {
                return cellCenter
            }
        }
        
        return nil
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
            mines.removeAll { $0 === mine }
            MineTower.currentMineCount -= 1
        }
    }
    
    private func spawnDeployEffect(at pos: CGPoint) {
        let effect = SKShapeNode(circleOfRadius: 5)
        effect.fillColor = .orange
        effect.strokeColor = .yellow
        effect.lineWidth = 2
        effect.position = pos
        effect.zPosition = GameConstants.ZPosition.effects.rawValue
        parent?.addChild(effect)
        
        let animation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        effect.run(animation)
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
            MineTower.currentMineCount -= 1
        }
        mines.removeAll()
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
    
    init(position: CGPoint, damage: CGFloat, splashRadius: CGFloat) {
        self.damage = damage
        self.splashRadius = splashRadius
        
        // Create mine visual
        mineNode = SKShapeNode(circleOfRadius: 8)
        mineNode.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        mineNode.strokeColor = .red
        mineNode.lineWidth = 2
        
        super.init()
        
        self.position = position
        zPosition = GameConstants.ZPosition.grid.rawValue + 2
        addChild(mineNode)
        
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
        
        // Remove mine
        removeFromParent()
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
}
