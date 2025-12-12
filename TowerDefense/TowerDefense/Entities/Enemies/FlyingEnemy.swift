import SpriteKit

/// Flying unit that ignores ground obstacles (towers)
/// Moves in a straight line toward the exit
/// Best countered by Machine Gun tower
final class FlyingEnemy: Enemy {
    
    // Flying stats per level
    static let baseStats: (health: CGFloat, speed: CGFloat, armor: CGFloat, reward: Int) = (
        health: 60,
        speed: 100,
        armor: 0,
        reward: 15
    )
    
    // Hover animation offset
    private var hoverOffset: CGFloat = 0
    private var hoverDirection: CGFloat = 1
    
    init(level: Int = 1) {
        // Scale stats with level
        let healthMultiplier = 1.0 + (CGFloat(level - 1) * 0.25)
        let health = FlyingEnemy.baseStats.health * healthMultiplier
        let speed = FlyingEnemy.baseStats.speed + CGFloat(level - 1) * 8
        let armor = FlyingEnemy.baseStats.armor
        let reward = FlyingEnemy.baseStats.reward + (level - 1) * 3
        
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
        // Flying units are slightly elevated visually
        bodyNode.position.y = 5
        healthBarBackground.position.y += 5
        healthBarFill.position.y += 5
        slowIndicator.position.y = 5
        
        // Add shadow to indicate flying
        let shadow = SKShapeNode(ellipseOf: CGSize(width: enemySize * 0.8, height: enemySize * 0.3))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 5, y: -10)
        shadow.zPosition = -2
        addChild(shadow)
        
        // Wing flapping animation (enhanced from base)
        if let wing1 = bodyNode.children.first(where: { ($0 as? SKShapeNode)?.position.x == -12 }) as? SKShapeNode,
           let wing2 = bodyNode.children.first(where: { ($0 as? SKShapeNode)?.position.x == 12 }) as? SKShapeNode {
            
            let flapUp = SKAction.group([
                SKAction.rotate(toAngle: 0.5, duration: 0.1),
                SKAction.moveBy(x: 0, y: 2, duration: 0.1)
            ])
            let flapDown = SKAction.group([
                SKAction.rotate(toAngle: 0.1, duration: 0.1),
                SKAction.moveBy(x: 0, y: -2, duration: 0.1)
            ])
            let flap = SKAction.sequence([flapUp, flapDown])
            wing1.run(SKAction.repeatForever(flap), withKey: "flap")
            
            let flapUp2 = SKAction.group([
                SKAction.rotate(toAngle: -0.5, duration: 0.1),
                SKAction.moveBy(x: 0, y: 2, duration: 0.1)
            ])
            let flapDown2 = SKAction.group([
                SKAction.rotate(toAngle: -0.1, duration: 0.1),
                SKAction.moveBy(x: 0, y: -2, duration: 0.1)
            ])
            let flap2 = SKAction.sequence([flapUp2, flapDown2])
            wing2.run(SKAction.repeatForever(flap2), withKey: "flap")
        }
        
        // Hover animation for shadow
        let shadowHover = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 3, duration: 0.5),
                SKAction.scale(to: 0.9, duration: 0.5)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: -3, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
        ])
        shadow.run(SKAction.repeatForever(shadowHover))
        
        // Body hover
        let bodyHover = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.5),
            SKAction.moveBy(x: 0, y: -3, duration: 0.5)
        ])
        bodyNode.run(SKAction.repeatForever(bodyHover), withKey: "hover")
    }
    
    override func calculateMovementDirection() -> CGVector {
        // Flying units ignore obstacles and move directly toward exit
        // They can have slight vertical variation for visual interest
        
        // Calculate direct path to center-right of field
        let targetX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width
        let targetY = position.y // Maintain current Y with slight wobble
        
        // Add slight sine wave movement for visual interest
        hoverOffset += 0.05
        let wobble = sin(hoverOffset) * 0.1
        
        return CGVector(dx: 1, dy: wobble).normalized()
    }
    
    override func update(deltaTime: TimeInterval, currentTime: TimeInterval, enemies: [Enemy]) {
        guard isAlive else { return }
        
        // Flying enemies have reduced separation (they can overlap more)
        // Call parent update but with modified behavior
        
        // Update slow status
        if isSlowed && currentTime >= slowEndTime {
            isSlowed = false
            slowMultiplier = 1.0
            slowIndicator.isHidden = true
            slowIndicator.removeAction(forKey: "slowPulse")
        }
        
        // Calculate movement (straight line, ignore flow field)
        let direction = calculateMovementDirection()
        
        // Minimal separation for flying units
        var separation = CGVector.zero
        let separationRadius: CGFloat = enemySize * 0.8
        
        for other in enemies {
            guard other.id != self.id && other.isAlive && other.enemyType == .flying else { continue }
            
            let distance = position.distance(to: other.position)
            if distance < separationRadius && distance > 0 {
                let strength = (separationRadius - distance) / separationRadius * 0.3
                let dx = (position.x - other.position.x) / distance
                let dy = (position.y - other.position.y) / distance
                separation.dx += dx * strength
                separation.dy += dy * strength
            }
        }
        
        // Combine direction and separation
        var finalDirection = CGVector(
            dx: direction.dx + separation.dx * 0.2,
            dy: direction.dy + separation.dy * 0.2
        ).normalized()
        
        // Smooth direction
        currentDirection = CGVector(
            dx: currentDirection.dx * 0.8 + finalDirection.dx * 0.2,
            dy: currentDirection.dy * 0.8 + finalDirection.dy * 0.2
        ).normalized()
        
        // Move
        let actualSpeed = speed * slowMultiplier
        let movement = CGVector(
            dx: currentDirection.dx * actualSpeed * CGFloat(deltaTime),
            dy: currentDirection.dy * actualSpeed * CGFloat(deltaTime)
        )
        
        position = CGPoint(
            x: position.x + movement.dx,
            y: position.y + movement.dy
        )
        
        // Clamp vertical position
        let minY = GameConstants.playFieldOrigin.y + enemySize / 2
        let maxY = GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - enemySize / 2
        position.y = max(minY, min(maxY, position.y))
        
        // Check exit
        let exitX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - CGFloat(GameConstants.exitZoneWidth) * GameConstants.cellSize
        if position.x >= exitX {
            isAlive = false
            let exitAnimation = SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ])
            run(exitAnimation)
            delegate?.enemyDidReachExit(self)
        }
    }
}
