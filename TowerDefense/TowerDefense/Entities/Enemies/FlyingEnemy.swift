import SpriteKit

/// Flying unit that ignores ground obstacles (towers)
/// Moves in a straight line toward the exit - NOT path bound
/// WEAKER than ground units to compensate for ignoring pathing
/// Can ONLY be hit by: MachineGun, Slow, Shotgun, AntiAir
/// IMMUNE to: Cannon, Splash, Laser (projectiles go under them)
/// Best countered by AntiAir tower (bonus damage) and MachineGun (prioritizes flying)
final class FlyingEnemy: Enemy {
    
    // Flying stats per level - WEAKER than ground units
    static let baseStats: (health: CGFloat, speed: CGFloat, armor: CGFloat, reward: Int) = (
        health: 80,     // 2x HP - still fragile
        speed: 60,      // Reduced from 90 - slower
        armor: 0,       // No armor
        reward: 2       // Reduced from 12 (factor ~5)
    )
    
    // Hover animation offset
    private var hoverOffset: CGFloat = 0
    private var hoverDirection: CGFloat = 1
    private var wobblePhase: CGFloat = 0
    
    // Shadow node for visual elevation indication
    private var shadowNode: SKShapeNode?
    
    init(level: Int = 1) {
        // Scale stats with level - weaker scaling than ground units
        let healthMultiplier = 1.0 + (CGFloat(level - 1) * 0.20)  // Only 20% per level
        let health = FlyingEnemy.baseStats.health * healthMultiplier
        let speed = FlyingEnemy.baseStats.speed + CGFloat(level - 1) * 5
        let armor = FlyingEnemy.baseStats.armor  // No armor scaling
        let reward = FlyingEnemy.baseStats.reward + (level - 1) * 2
        
        super.init(
            type: .flying,
            health: health,
            speed: speed,
            armor: armor,
            reward: reward
        )
        
        setupAppearance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        // Simplified flying visual - no complex animations for performance
        bodyNode.position.y = 8
        healthBarBackground.position.y += 8
        healthBarFill.position.y += 8
        slowIndicator.position.y = 8
        
        // Simple static shadow
        shadowNode = SKShapeNode(ellipseOf: CGSize(width: enemySize * 0.5, height: enemySize * 0.2))
        shadowNode?.fillColor = SKColor.black.withAlphaComponent(0.2)
        shadowNode?.strokeColor = .clear
        shadowNode?.position = CGPoint(x: 5, y: -15)
        shadowNode?.zPosition = -2
        addChild(shadowNode!)
    }
    
    override func calculateMovementDirection() -> CGVector {
        // Flying units IGNORE pathfinding completely
        // They fly in a direct line toward the exit (bottom-right) with slight wobble
        
        // Target is bottom-right exit zone
        let targetX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - GameConstants.cellSize
        let targetY = GameConstants.playFieldOrigin.y + GameConstants.cellSize * 2  // Center of exit zone
        
        let dx = targetX - position.x
        let dy = targetY - position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Update wobble phase
        wobblePhase += 0.08
        let wobble = sin(wobblePhase) * 0.1
        
        // Normalize direction + add wobble perpendicular to movement
        if distance > 0 {
            let normDx = dx / distance
            let normDy = dy / distance
            // Add wobble perpendicular to direction
            return CGVector(dx: normDx - wobble * normDy, dy: normDy + wobble * normDx).normalized()
        }
        
        return CGVector(dx: 1, dy: -0.5).normalized()  // Fallback: down-right
    }
    
    override func update(deltaTime: TimeInterval, currentTime: TimeInterval, enemies: [Enemy]) {
        guard isAlive else { return }
        
        // Update slow status
        if isSlowed && currentTime >= slowEndTime {
            isSlowed = false
            slowMultiplier = 1.0
            slowIndicator.isHidden = true
            slowIndicator.removeAction(forKey: "slowPulse")
        }
        
        // Calculate movement - DIRECT PATH, no flow field
        let direction = calculateMovementDirection()
        
        // Very light separation for flying units (they can overlap more)
        var separation = CGVector.zero
        let separationRadius: CGFloat = enemySize * 0.6
        
        for other in enemies {
            guard other.id != self.id && other.isAlive && other.enemyType == .flying else { continue }
            
            let distance = position.distance(to: other.position)
            if distance < separationRadius && distance > 0 {
                let strength = (separationRadius - distance) / separationRadius * 0.2
                let dx = (position.x - other.position.x) / distance
                let dy = (position.y - other.position.y) / distance
                separation.dx += dx * strength
                separation.dy += dy * strength
            }
        }
        
        // Combine direction with light separation
        let finalDirection = CGVector(
            dx: direction.dx + separation.dx * 0.1,
            dy: direction.dy + separation.dy * 0.1
        ).normalized()
        
        // Very smooth direction changes
        currentDirection = CGVector(
            dx: currentDirection.dx * 0.85 + finalDirection.dx * 0.15,
            dy: currentDirection.dy * 0.85 + finalDirection.dy * 0.15
        ).normalized()
        
        // Move with slow effect
        let actualSpeed = moveSpeed * slowMultiplier
        let movement = CGVector(
            dx: currentDirection.dx * actualSpeed * CGFloat(deltaTime),
            dy: currentDirection.dy * actualSpeed * CGFloat(deltaTime)
        )
        
        position = CGPoint(
            x: position.x + movement.dx,
            y: position.y + movement.dy
        )
        
        // Clamp vertical position with buffer
        let minY = GameConstants.playFieldOrigin.y + enemySize
        let maxY = GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - enemySize
        position.y = max(minY, min(maxY, position.y))
        
        // Check exit (bottom-right corner)
        let exitX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - CGFloat(GameConstants.exitZoneWidth) * GameConstants.cellSize
        let exitY = GameConstants.playFieldOrigin.y + CGFloat(4) * GameConstants.cellSize
        if position.x >= exitX && position.y < exitY {
            isAlive = false
            // AudioManager.shared.playSound(.enemyReachExit)
            let exitAnimation = SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ])
            run(exitAnimation)
            delegate?.enemyDidReachExit(self)
        }
    }
    
    override func takeDamage(_ damage: CGFloat, armorPenetration: CGFloat = 0) {
        // Flying units take normal damage (no armor anyway)
        // But they're weaker so they die faster
        super.takeDamage(damage, armorPenetration: armorPenetration)
    }
}
