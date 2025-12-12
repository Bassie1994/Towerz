import SpriteKit

/// Buff Tower
/// Role: Buffs nearby towers (increases damage and fire rate)
/// Does not attack enemies directly
/// Buff does not stack with multiple buff towers (uses highest buff)
final class BuffTower: Tower {
    
    static let stats: (damage: CGFloat, range: CGFloat, fireRate: CGFloat) = (
        damage: 0,      // No damage
        range: 150,     // Buff radius
        fireRate: 1.0   // Update rate (not used for attacks)
    )
    
    var damageBuffPercent: CGFloat = 0.15  // +15% damage
    var fireRateBuffPercent: CGFloat = 0.10  // +10% fire rate
    
    // Visual
    let buffFieldNode: SKShapeNode
    let buffBeams: [SKShapeNode]
    
    // Tracked buffed towers
    private var buffedTowers: Set<UUID> = []
    
    init(gridPosition: GridPosition) {
        buffFieldNode = SKShapeNode(circleOfRadius: BuffTower.stats.range)
        buffFieldNode.fillColor = SKColor.buffEffect.withAlphaComponent(0.05)
        buffFieldNode.strokeColor = SKColor.buffEffect.withAlphaComponent(0.2)
        buffFieldNode.lineWidth = 2
        buffFieldNode.zPosition = -1
        
        // Create beam visuals (will connect to buffed towers)
        var beams: [SKShapeNode] = []
        for _ in 0..<6 {
            let beam = SKShapeNode()
            beam.strokeColor = .buffEffect
            beam.lineWidth = 2
            beam.alpha = 0
            beam.zPosition = GameConstants.ZPosition.effects.rawValue - 1
            beams.append(beam)
        }
        buffBeams = beams
        
        super.init(
            type: .buff,
            gridPosition: gridPosition,
            damage: BuffTower.stats.damage,
            range: BuffTower.stats.range,
            fireRate: BuffTower.stats.fireRate
        )
        
        addChild(buffFieldNode)
        for beam in buffBeams {
            addChild(beam)
        }
        
        setupBuffFieldAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBuffFieldAnimation() {
        // Gentle rotation
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 10.0)
        buffFieldNode.run(SKAction.repeatForever(rotate))
        
        // Pulse
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 1.5),
            SKAction.fadeAlpha(to: 0.05, duration: 1.5)
        ])
        buffFieldNode.run(SKAction.repeatForever(pulse))
    }
    
    override func setupTurretVisual() {
        // Antenna/broadcast design
        let antenna = SKShapeNode(rectOf: CGSize(width: towerSize * 0.08, height: towerSize * 0.5))
        antenna.fillColor = .buffEffect
        antenna.strokeColor = .clear
        antenna.position = CGPoint(x: 0, y: towerSize * 0.25)
        turretNode.addChild(antenna)
        
        // Signal rings
        for i in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: towerSize * 0.15 + CGFloat(i) * 8)
            ring.fillColor = .clear
            ring.strokeColor = .buffEffect
            ring.lineWidth = 1
            ring.alpha = 0.3
            ring.position = CGPoint(x: 0, y: towerSize * 0.25)
            turretNode.addChild(ring)
            
            // Animate rings
            let delay = Double(i) * 0.3
            let expand = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: 1.5, duration: 1.0),
                    SKAction.fadeOut(withDuration: 1.0)
                ]),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0),
                    SKAction.fadeAlpha(to: 0.3, duration: 0)
                ])
            ])
            ring.run(SKAction.repeatForever(expand))
        }
    }
    
    override func update(currentTime: TimeInterval) {
        // Don't attack - just buff nearby towers
        updateBuffedTowers()
        updateBuffBeams()
    }
    
    private func updateBuffedTowers() {
        guard let allTowers = delegate?.getAllTowers() else { return }
        
        let effectiveDamageBuff = 1.0 + damageBuffPercent * (1.0 + CGFloat(upgradeLevel) * 0.5)
        let effectiveFireRateBuff = 1.0 + fireRateBuffPercent * (1.0 + CGFloat(upgradeLevel) * 0.5)
        
        var newBuffedTowers = Set<UUID>()
        
        for tower in allTowers {
            // Don't buff self or other buff towers
            guard tower.id != self.id && tower.towerType != .buff else { continue }
            
            let distance = position.distance(to: tower.position)
            
            if distance <= range {
                // In range - apply buff
                tower.applyBuff(
                    damageMultiplier: effectiveDamageBuff,
                    fireRateMultiplier: effectiveFireRateBuff
                )
                newBuffedTowers.insert(tower.id)
            } else if buffedTowers.contains(tower.id) {
                // Was buffed but now out of range
                tower.removeBuff()
            }
        }
        
        buffedTowers = newBuffedTowers
    }
    
    private func updateBuffBeams() {
        guard let allTowers = delegate?.getAllTowers() else { return }
        
        // Reset all beams
        for beam in buffBeams {
            beam.alpha = 0
        }
        
        // Draw beams to buffed towers
        var beamIndex = 0
        for tower in allTowers {
            guard beamIndex < buffBeams.count else { break }
            guard tower.id != self.id && buffedTowers.contains(tower.id) else { continue }
            
            let beam = buffBeams[beamIndex]
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(
                x: tower.position.x - position.x,
                y: tower.position.y - position.y
            ))
            beam.path = path
            beam.alpha = 0.3
            
            beamIndex += 1
        }
    }
    
    override func upgrade() -> Bool {
        let result = super.upgrade()
        
        if result {
            // Increase buff strength
            damageBuffPercent = 0.15 + CGFloat(upgradeLevel) * 0.05
            fireRateBuffPercent = 0.10 + CGFloat(upgradeLevel) * 0.05
            
            // Update visual
            let newPath = CGPath(ellipseIn: CGRect(x: -range, y: -range, width: range * 2, height: range * 2), transform: nil)
            buffFieldNode.path = newPath
        }
        
        return result
    }
    
    /// Called when this tower is sold/removed
    func removeAllBuffs() {
        guard let allTowers = delegate?.getAllTowers() else { return }
        
        for tower in allTowers {
            if buffedTowers.contains(tower.id) {
                tower.removeBuff()
            }
        }
        buffedTowers.removeAll()
    }
    
    override func getStats() -> [String: String] {
        let effectiveDamageBuff = damageBuffPercent * (1.0 + CGFloat(upgradeLevel) * 0.5)
        let effectiveFireRateBuff = fireRateBuffPercent * (1.0 + CGFloat(upgradeLevel) * 0.5)
        
        return [
            "Type": towerType.displayName,
            "Damage Buff": "+\(Int(effectiveDamageBuff * 100))%",
            "ROF Buff": "+\(Int(effectiveFireRateBuff * 100))%",
            "Range": String(format: "%.0f", range),
            "Buffing": "\(buffedTowers.count) towers",
            "Level": "\(upgradeLevel + 1)/\(maxUpgradeLevel + 1)",
            "Sell Value": "\(sellValue)"
        ]
    }
}
