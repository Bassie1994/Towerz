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
        health: 40,     // Reduced from 60 - very fragile
        speed: 90,      // Slightly slower
        armor: 0,       // No armor
        reward: 12      // Less reward due to being easier in some ways
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
        // Flying units are visually elevated
        bodyNode.position.y = 8
        healthBarBackground.position.y += 8
        healthBarFill.position.y += 8
        slowIndicator.position.y = 8
        
        // Add ground shadow to show they're flying
        shadowNode = SKShapeNode(ellipseOf: CGSize(width: enemySize * 0.7, height: enemySize * 0.25))
        shadowNode?.fillColor = SKColor.black.withAlphaComponent(0.25)
        shadowNode?.strokeColor = .clear
        shadowNode?.position = CGPoint(x: 8, y: -12)  // Offset shadow
        shadowNode?.zPosition = -2
        addChild(shadowNode!)
        
        // Enhanced wing flapping
        if let wing1 = bodyNode.children.first(where: { ($0 as? SKShapeNode)?.position.x == -12 }) as? SKShapeNode,
           let wing2 = bodyNode.children.first(where: { ($0 as? SKShapeNode)?.position.x == 12 }) as? SKShapeNode {
            
            // Fast wing flapping
            let flapUp = SKAction.group([
                SKAction.rotate(toAngle: 0.6, duration: 0.08),
                SKAction.moveBy(x: 0, y: 3, duration: 0.08)
            ])
            let flapDown = SKAction.group([
                SKAction.rotate(toAngle: 0.1, duration: 0.08),
                SKAction.moveBy(x: 0, y: -3, duration: 0.08)
            ])
            let flap = SKAction.sequence([flapUp, flapDown])
            wing1.run(SKAction.repeatForever(flap), withKey: "flap")
            
            let flapUp2 = SKAction.group([
                SKAction.rotate(toAngle: -0.6, duration: 0.08),
                SKAction.moveBy(x: 0, y: 3, duration: 0.08)
            ])
            let flapDown2 = SKAction.group([
                SKAction.rotate(toAngle: -0.1, duration: 0.08),
                SKAction.moveBy(x: 0, y: -3, duration: 0.08)
            ])
            let flap2 = SKAction.sequence([flapUp2, flapDown2])
            wing2.run(SKAction.repeatForever(flap2), withKey: "flap")
        }
        
        // Hovering body animation
        let bodyHover = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 0.4),
            SKAction.moveBy(x: 0, y: -4, duration: 0.4)
        ])
        bodyNode.run(SKAction.repeatForever(bodyHover), withKey: "hover")
        
        // Shadow movement (opposite to body for 3D effect)
        let shadowMove = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 2, y: -2, duration: 0.4),
                SKAction.scale(to: 0.85, duration: 0.4)
            ]),
            SKAction.group([
                SKAction.moveBy(x: -2, y: 2, duration: 0.4),
                SKAction.scale(to: 1.0, duration: 0.4)
            ])
        ])
        shadowNode?.run(SKAction.repeatForever(shadowMove))
    }
    
    override func calculateMovementDirection() -> CGVector {
        // Flying units IGNORE pathfinding completely
        // They fly in a direct line toward the exit with slight wobble
        
        // Update wobble phase
        wobblePhase += 0.08
        let wobble = sin(wobblePhase) * 0.15
        
        // Direct path to exit (right side)
        return CGVector(dx: 1, dy: wobble).normalized()
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
        var finalDirection = CGVector(
            dx: direction.dx + separation.dx * 0.1,
            dy: direction.dy + separation.dy * 0.1
        ).normalized()
        
        // Very smooth direction changes
        currentDirection = CGVector(
            dx: currentDirection.dx * 0.85 + finalDirection.dx * 0.15,
            dy: currentDirection.dy * 0.85 + finalDirection.dy * 0.15
        ).normalized()
        
        // Move with slow effect
        let actualSpeed = speed * slowMultiplier
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
        
        // Check exit
        let exitX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - CGFloat(GameConstants.exitZoneWidth) * GameConstants.cellSize
        if position.x >= exitX {
            isAlive = false
            AudioManager.shared.playSound(.enemyReachExit)
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
