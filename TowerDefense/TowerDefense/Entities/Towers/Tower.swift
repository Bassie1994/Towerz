import SpriteKit

/// Protocol for tower event handling
protocol TowerDelegate: AnyObject {
    func towerDidFire(_ tower: Tower, at target: Enemy)
    func getEnemiesInRange(of tower: Tower) -> [Enemy]
    func getAllTowers() -> [Tower]
}

/// Player-selectable target priorities for towers
enum TargetPriority: String, CaseIterable {
    case first
    case last
    case strongest
    case weakest
    case fastest

    var displayName: String {
        switch self {
        case .first: return "First"
        case .last: return "Last"
        case .strongest: return "Strongest"
        case .weakest: return "Weakest"
        case .fastest: return "Fastest"
        }
    }
}

/// Base class for all tower types
class Tower: SKNode {
    
    // MARK: - Properties
    
    weak var delegate: TowerDelegate?
    
    let towerType: TowerType
    let id: UUID = UUID()
    let gridPosition: GridPosition
    
    // Stats (modified by upgrades)
    var damage: CGFloat
    var range: CGFloat
    var fireRate: CGFloat  // Shots per second
    var baseDamage: CGFloat
    var baseRange: CGFloat
    var baseFireRate: CGFloat
    
    // Upgrade state
    var upgradeLevel: Int = 0
    let maxUpgradeLevel: Int = 3  // 3 upgrades possible (levels 1-4)
    
    // Buff state (from buff towers)
    var damageMultiplier: CGFloat = 1.0
    var fireRateMultiplier: CGFloat = 1.0
    var rangeMultiplier: CGFloat = 1.0
    var isBuffed: Bool = false
    
    // Combat state
    var lastFireTime: TimeInterval = 0
    var currentTarget: Enemy?
    var isSelected: Bool = false
    var targetPriority: TargetPriority = .first
    
    // Visual components
    let baseNode: SKShapeNode
    let turretNode: SKShapeNode
    let rangeIndicator: SKShapeNode
    let upgradeIndicators: [SKShapeNode]
    let buffIndicator: SKShapeNode
    
    // Sell value
    var totalInvested: Int
    var sellValue: Int { return Int(Double(totalInvested) * 0.7) }
    
    // Size
    let towerSize: CGFloat = GameConstants.cellSize - 4
    
    // MARK: - Initialization
    
    init(type: TowerType, gridPosition: GridPosition, damage: CGFloat, range: CGFloat, fireRate: CGFloat) {
        self.towerType = type
        self.gridPosition = gridPosition
        self.damage = damage
        self.range = range
        self.fireRate = fireRate
        self.baseDamage = damage
        self.baseRange = range
        self.baseFireRate = fireRate
        self.totalInvested = type.baseCost
        
        // Create base
        baseNode = SKShapeNode(rectOf: CGSize(width: towerSize, height: towerSize), cornerRadius: 4)
        baseNode.fillColor = type.color
        baseNode.strokeColor = .white
        baseNode.lineWidth = 2
        
        // Create turret
        turretNode = SKShapeNode(circleOfRadius: towerSize * 0.3)
        turretNode.fillColor = type.color.withAlphaComponent(0.8)
        turretNode.strokeColor = .white
        turretNode.lineWidth = 1
        
        // Create range indicator (hidden by default)
        rangeIndicator = SKShapeNode(circleOfRadius: range)
        rangeIndicator.fillColor = SKColor.white.withAlphaComponent(0.1)
        rangeIndicator.strokeColor = SKColor.white.withAlphaComponent(0.3)
        rangeIndicator.lineWidth = 2
        rangeIndicator.isHidden = true
        rangeIndicator.zPosition = GameConstants.ZPosition.rangeIndicator.rawValue
        
        // Create upgrade indicators (3 for 3 upgrade levels) - inside the tower
        var indicators: [SKShapeNode] = []
        for i in 0..<3 {
            let indicator = SKShapeNode(circleOfRadius: 4)
            indicator.fillColor = SKColor.black.withAlphaComponent(0.6)  // Dark unfilled
            indicator.strokeColor = .white
            indicator.lineWidth = 1.5
            // Position 3 indicators inside tower at bottom, evenly spaced
            indicator.position = CGPoint(x: -12 + CGFloat(i) * 12, y: -towerSize / 2 + 10)
            indicator.zPosition = 5  // Above tower base
            indicators.append(indicator)
        }
        upgradeIndicators = indicators
        
        // Create buff indicator
        buffIndicator = SKShapeNode(circleOfRadius: towerSize * 0.5)
        buffIndicator.fillColor = .clear
        buffIndicator.strokeColor = .buffEffect
        buffIndicator.lineWidth = 2
        buffIndicator.isHidden = true
        
        super.init()
        
        addChild(rangeIndicator)
        addChild(buffIndicator)
        addChild(baseNode)
        addChild(turretNode)
        for indicator in upgradeIndicators {
            addChild(indicator)
        }
        
        position = gridPosition.toWorldPosition()
        zPosition = GameConstants.ZPosition.tower.rawValue
        
        setupTurretVisual()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Override in subclasses for custom turret appearance
    func setupTurretVisual() {
        // Default: simple barrel
        let barrel = SKShapeNode(rectOf: CGSize(width: towerSize * 0.4, height: towerSize * 0.15))
        barrel.fillColor = .darkGray
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: towerSize * 0.25, y: 0)
        turretNode.addChild(barrel)
    }
    
    // MARK: - Update
    
    func update(currentTime: TimeInterval) {
        // Update buff visual
        if isBuffed {
            if buffIndicator.isHidden {
                buffIndicator.isHidden = false
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.1, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
                buffIndicator.run(SKAction.repeatForever(pulse), withKey: "buffPulse")
            }
        } else {
            buffIndicator.isHidden = true
            buffIndicator.removeAction(forKey: "buffPulse")
        }
        
        // Find target
        updateTarget()
        
        // Aim at target
        if let target = currentTarget {
            aimAt(target)
        }
        
        // Fire if ready
        let effectiveFireRate = fireRate * fireRateMultiplier
        let fireInterval = 1.0 / Double(effectiveFireRate)
        
        if currentTime - lastFireTime >= fireInterval {
            if let target = currentTarget, target.isAlive {
                fire(at: target, currentTime: currentTime)
                lastFireTime = currentTime
            }
        }
    }
    
    /// Override in subclasses for custom targeting logic
    func updateTarget() {
        guard let enemies = delegate?.getEnemiesInRange(of: self) else {
            currentTarget = nil
            return
        }

        // Default: respect configurable priority
        currentTarget = selectTarget(from: enemies)
    }

    func selectTarget(from enemies: [Enemy]) -> Enemy? {
        let alive = enemies.filter { $0.isAlive }

        switch targetPriority {
        case .first:
            return alive.max { lhs, rhs in lhs.position.x < rhs.position.x }
        case .last:
            return alive.min { lhs, rhs in lhs.position.x < rhs.position.x }
        case .strongest:
            return alive.max { lhs, rhs in lhs.currentHealth < rhs.currentHealth }
        case .weakest:
            return alive.min { lhs, rhs in lhs.currentHealth < rhs.currentHealth }
        case .fastest:
            return alive.max { lhs, rhs in lhs.moveSpeed * lhs.slowMultiplier < rhs.moveSpeed * rhs.slowMultiplier }
        }
    }
    
    func aimAt(_ target: Enemy) {
        let angle = position.angle(to: target.position)
        turretNode.zRotation = angle
    }
    
    /// Override in subclasses for custom firing behavior
    func fire(at target: Enemy, currentTime: TimeInterval) {
        let effectiveDamage = damage * damageMultiplier
        target.takeDamage(effectiveDamage)
        delegate?.towerDidFire(self, at: target)
        
        // Muzzle flash
        let flash = SKShapeNode(circleOfRadius: 8)
        flash.fillColor = .yellow
        flash.strokeColor = .clear
        flash.position = CGPoint(
            x: turretNode.position.x + cos(turretNode.zRotation) * towerSize * 0.4,
            y: turretNode.position.y + sin(turretNode.zRotation) * towerSize * 0.4
        )
        flash.zPosition = GameConstants.ZPosition.effects.rawValue
        addChild(flash)
        
        let flashAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.1, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ])
        flash.run(flashAnimation)
    }
    
    // MARK: - Upgrades
    
    func getUpgradeCost() -> Int? {
        guard upgradeLevel < maxUpgradeLevel else { return nil }
        // Upgrade costs scale: 40%, 50%, 60% of base cost
        // Level 1→2: 40%, Level 2→3: 50%, Level 3→4: 60%
        let costPercent = 0.40 + Double(upgradeLevel) * 0.10
        return Int(Double(towerType.baseCost) * costPercent)
    }
    
    func canUpgrade() -> Bool {
        return upgradeLevel < maxUpgradeLevel
    }
    
    func upgrade() -> Bool {
        guard upgradeLevel < maxUpgradeLevel else { return false }
        
        // Track investment for sell value BEFORE incrementing level
        let upgradeCost = getUpgradeCost() ?? 0
        totalInvested += upgradeCost
        
        upgradeLevel += 1
        
        // BUFFED upgrade scaling - makes upgrades more valuable than buying new towers
        // Each upgrade gives 35% damage, 15% range, 25% fire rate
        // Level 4 tower has: 205% damage, 145% range, 175% fire rate
        // At 150% total cost (40% + 50% + 60% = 150% for all upgrades)
        // Much more efficient than buying multiple towers!
        // So upgrading one tower is more efficient!
        let upgradeDamageMultiplier = 1.0 + (CGFloat(upgradeLevel) * 0.35)  // +35% per level
        let upgradeRangeMultiplier = 1.0 + (CGFloat(upgradeLevel) * 0.15)   // +15% per level
        let upgradeFireRateMultiplier = 1.0 + (CGFloat(upgradeLevel) * 0.25) // +25% per level
        
        damage = baseDamage * upgradeDamageMultiplier
        range = baseRange * upgradeRangeMultiplier
        fireRate = baseFireRate * upgradeFireRateMultiplier
        
        // Update range indicator
        let newPath = CGPath(ellipseIn: CGRect(x: -range, y: -range, width: range * 2, height: range * 2), transform: nil)
        rangeIndicator.path = newPath
        
        // Update visual indicator with bright contrasting color
        if upgradeLevel <= upgradeIndicators.count {
            upgradeIndicators[upgradeLevel - 1].fillColor = .white  // Bright white for contrast
            upgradeIndicators[upgradeLevel - 1].strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0, alpha: 1.0)  // Gold outline
            upgradeIndicators[upgradeLevel - 1].lineWidth = 2
        }
        
        // Upgrade animation
        let upgradeAnimation = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        run(upgradeAnimation)
        
        // Particle effect
        spawnUpgradeParticles()
        
        return true
    }
    
    private func spawnUpgradeParticles() {
        for _ in 0..<12 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = .yellow
            particle.strokeColor = .clear
            particle.position = .zero
            particle.zPosition = GameConstants.ZPosition.effects.rawValue
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...50)
            let destination = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            
            let animation = SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: destination, duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4)
                ]),
                SKAction.removeFromParent()
            ])
            
            addChild(particle)
            particle.run(animation)
        }
    }
    
    // MARK: - Selection
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
        rangeIndicator.isHidden = !selected
        
        if selected {
            baseNode.strokeColor = .yellow
            baseNode.lineWidth = 3
        } else {
            baseNode.strokeColor = .white
            baseNode.lineWidth = 2
        }
    }
    
    // MARK: - Buff Management
    
    func applyBuff(damageMultiplier: CGFloat, fireRateMultiplier: CGFloat, rangeMultiplier: CGFloat) {
        self.damageMultiplier = damageMultiplier
        self.fireRateMultiplier = fireRateMultiplier
        self.rangeMultiplier = rangeMultiplier
        self.isBuffed = true
        
        // Update range indicator to show buffed range
        updateRangeIndicatorForBuff()
        
        // Visual: Add golden glow to tower base
        updateBuffVisual()
    }
    
    func removeBuff() {
        self.damageMultiplier = 1.0
        self.fireRateMultiplier = 1.0
        self.rangeMultiplier = 1.0
        self.isBuffed = false
        
        // Reset range indicator to base range
        updateRangeIndicatorForBuff()
        
        // Reset visual
        updateBuffVisual()
    }
    
    /// Update range indicator to reflect current buff state
    func updateRangeIndicatorForBuff() {
        let effectiveRange = range * rangeMultiplier
        let newPath = CGPath(ellipseIn: CGRect(x: -effectiveRange, y: -effectiveRange, width: effectiveRange * 2, height: effectiveRange * 2), transform: nil)
        rangeIndicator.path = newPath
        
        // Change color when buffed
        if isBuffed {
            rangeIndicator.strokeColor = SKColor.buffEffect.withAlphaComponent(0.6)
            rangeIndicator.fillColor = SKColor.buffEffect.withAlphaComponent(0.2)
        } else {
            rangeIndicator.strokeColor = SKColor.white.withAlphaComponent(0.3)
            rangeIndicator.fillColor = SKColor.white.withAlphaComponent(0.1)
        }
    }
    
    /// Update tower visual to show buff state
    private func updateBuffVisual() {
        if isBuffed {
            // Golden/buff color glow on base
            baseNode.strokeColor = SKColor.buffEffect
            baseNode.lineWidth = 3

            let intensity = max(damageMultiplier, fireRateMultiplier)
            buffIndicator.lineWidth = 2 + min(intensity - 1.0, 1.0) * 3
            buffIndicator.alpha = 0.4 + min(intensity - 1.0, 1.0) * 0.4
            buffIndicator.strokeColor = SKColor.buffEffect.withAlphaComponent(0.8)
            
            // Add subtle glow effect
            if baseNode.childNode(withName: "buffGlow") == nil {
                let glow = SKShapeNode(rectOf: CGSize(width: towerSize + 6, height: towerSize + 6), cornerRadius: 6)
                glow.fillColor = .clear
                glow.strokeColor = SKColor.buffEffect.withAlphaComponent(0.6)
                glow.lineWidth = 2
                glow.name = "buffGlow"
                glow.zPosition = -1
                baseNode.addChild(glow)
                
                // Pulse animation
                let pulse = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.3, duration: 0.5),
                    SKAction.fadeAlpha(to: 0.8, duration: 0.5)
                ])
                glow.run(SKAction.repeatForever(pulse), withKey: "buffPulse")
            }
        } else {
            // Reset to normal
            baseNode.strokeColor = isSelected ? .yellow : .white
            baseNode.lineWidth = isSelected ? 3 : 2

            buffIndicator.lineWidth = 2
            buffIndicator.alpha = 1.0
            
            // Remove glow
            baseNode.childNode(withName: "buffGlow")?.removeFromParent()
        }
    }
    
    // MARK: - Info
    
    /// Get effective range (including buff)
    func getEffectiveRange() -> CGFloat {
        return range * rangeMultiplier
    }
    
    func getStats() -> [String: String] {
        var stats = [
            "Type": towerType.displayName,
            "Damage": String(format: "%.0f", damage * damageMultiplier),
            "Range": String(format: "%.0f", getEffectiveRange()),
            "Fire Rate": String(format: "%.1f/s", fireRate * fireRateMultiplier),
            "Target": targetPriority.displayName,
            "Level": "\(upgradeLevel + 1)/\(maxUpgradeLevel + 1)",
            "Sell Value": "\(sellValue)"
        ]
        
        // Add buff indicator if buffed
        if isBuffed {
            stats["Buffed"] = "✓ +\(Int((rangeMultiplier - 1) * 100))% range"
        }
        
        return stats
    }
}
