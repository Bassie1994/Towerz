import SpriteKit

/// Protocol for enemy event handling
protocol EnemyDelegate: AnyObject {
    func enemyDidReachExit(_ enemy: Enemy)
    func enemyDidDie(_ enemy: Enemy)
    func getFlowField() -> FlowField?
}

/// Base class for all enemy types
class Enemy: SKNode {
    
    // MARK: - Properties
    
    weak var delegate: EnemyDelegate?
    
    let enemyType: EnemyType
    let id: UUID = UUID()
    
    // Stats
    var maxHealth: CGFloat
    var currentHealth: CGFloat
    var moveSpeed: CGFloat
    var baseMoveSpeed: CGFloat
    var armor: CGFloat
    var killReward: Int
    
    // State
    var isAlive: Bool = true
    var isSlowed: Bool = false
    var slowEndTime: TimeInterval = 0
    var slowMultiplier: CGFloat = 1.0
    
    // Visual components
    let bodyNode: SKShapeNode
    let healthBarBackground: SKShapeNode
    let healthBarFill: SKShapeNode
    let slowIndicator: SKShapeNode
    
    // Movement
    var currentDirection: CGVector = CGVector(dx: 1, dy: 0)
    var separationForce: CGVector = .zero
    
    // Size
    let enemySize: CGFloat = 30
    
    // MARK: - Initialization
    
    init(type: EnemyType, health: CGFloat, speed: CGFloat, armor: CGFloat, reward: Int) {
        self.enemyType = type
        self.maxHealth = health
        self.currentHealth = health
        self.moveSpeed = speed
        self.baseMoveSpeed = speed
        self.armor = armor
        self.killReward = reward
        
        // Create body
        bodyNode = SKShapeNode(circleOfRadius: enemySize / 2)
        bodyNode.fillColor = type.color
        bodyNode.strokeColor = .white
        bodyNode.lineWidth = 2
        
        // Create health bar background
        let healthBarWidth: CGFloat = enemySize + 10
        let healthBarHeight: CGFloat = 5
        healthBarBackground = SKShapeNode(rectOf: CGSize(width: healthBarWidth, height: healthBarHeight))
        healthBarBackground.fillColor = .darkGray
        healthBarBackground.strokeColor = .black
        healthBarBackground.lineWidth = 1
        healthBarBackground.position = CGPoint(x: 0, y: enemySize / 2 + 8)
        
        // Create health bar fill
        healthBarFill = SKShapeNode(rectOf: CGSize(width: healthBarWidth - 2, height: healthBarHeight - 2))
        healthBarFill.fillColor = .healthBarGreen
        healthBarFill.strokeColor = .clear
        healthBarFill.position = CGPoint(x: 0, y: enemySize / 2 + 8)
        
        // Create slow indicator
        slowIndicator = SKShapeNode(circleOfRadius: enemySize / 2 + 3)
        slowIndicator.fillColor = .clear
        slowIndicator.strokeColor = .slowEffect
        slowIndicator.lineWidth = 2
        slowIndicator.isHidden = true
        
        super.init()
        
        addChild(slowIndicator)
        addChild(bodyNode)
        addChild(healthBarBackground)
        addChild(healthBarFill)
        
        zPosition = GameConstants.ZPosition.enemy.rawValue
        
        // Add type indicator
        addTypeIndicator()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addTypeIndicator() {
        let indicator = SKLabelNode(fontNamed: "Helvetica-Bold")
        indicator.fontSize = 12
        indicator.fontColor = .white
        indicator.verticalAlignmentMode = .center
        indicator.horizontalAlignmentMode = .center
        
        switch enemyType {
        case .infantry:
            indicator.text = "I"
        case .cavalry:
            indicator.text = "C"
        case .flying:
            indicator.text = "F"
            // Add wing indicators for flying
            let wing1 = SKShapeNode(ellipseOf: CGSize(width: 12, height: 6))
            wing1.fillColor = enemyType.color.withAlphaComponent(0.6)
            wing1.strokeColor = .clear
            wing1.position = CGPoint(x: -12, y: 0)
            wing1.zRotation = 0.3
            bodyNode.addChild(wing1)
            
            let wing2 = SKShapeNode(ellipseOf: CGSize(width: 12, height: 6))
            wing2.fillColor = enemyType.color.withAlphaComponent(0.6)
            wing2.strokeColor = .clear
            wing2.position = CGPoint(x: 12, y: 0)
            wing2.zRotation = -0.3
            bodyNode.addChild(wing2)
        }
        
        bodyNode.addChild(indicator)
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval, currentTime: TimeInterval, enemies: [Enemy]) {
        guard isAlive else { return }
        
        // Update slow status
        updateSlowStatus(currentTime: currentTime)
        
        // Calculate movement
        let direction = calculateMovementDirection()
        
        // Apply separation from other enemies
        let separation = calculateSeparation(from: enemies)
        
        // Combine forces
        let finalDirection = CGVector(
            dx: direction.dx + separation.dx * 0.3,
            dy: direction.dy + separation.dy * 0.3
        ).normalized()
        
        // Smooth direction change to prevent jittering
        currentDirection = CGVector(
            dx: currentDirection.dx * 0.7 + finalDirection.dx * 0.3,
            dy: currentDirection.dy * 0.7 + finalDirection.dy * 0.3
        ).normalized()
        
        // Calculate actual speed (with slow effect)
        let actualSpeed = moveSpeed * slowMultiplier
        
        // Move
        let movement = CGVector(
            dx: currentDirection.dx * actualSpeed * CGFloat(deltaTime),
            dy: currentDirection.dy * actualSpeed * CGFloat(deltaTime)
        )
        
        position = CGPoint(
            x: position.x + movement.dx,
            y: position.y + movement.dy
        )
        
        // Clamp to playfield bounds (vertical only)
        let minY = GameConstants.playFieldOrigin.y + enemySize / 2
        let maxY = GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - enemySize / 2
        position.y = max(minY, min(maxY, position.y))
        
        // Check if reached exit
        if hasReachedExit() {
            reachExit()
        }
    }
    
    /// Override in subclasses for different movement behavior
    func calculateMovementDirection() -> CGVector {
        // Default: use flow field
        if let flowField = delegate?.getFlowField(),
           let direction = flowField.getInterpolatedDirection(at: position) {
            return direction
        }
        // Fallback: move right
        return CGVector(dx: 1, dy: 0)
    }
    
    private func calculateSeparation(from enemies: [Enemy]) -> CGVector {
        var separation = CGVector.zero
        let separationRadius: CGFloat = enemySize * 1.5
        
        for other in enemies {
            guard other.id != self.id && other.isAlive else { continue }
            
            let distance = position.distance(to: other.position)
            if distance < separationRadius && distance > 0 {
                let strength = (separationRadius - distance) / separationRadius
                let dx = (position.x - other.position.x) / distance
                let dy = (position.y - other.position.y) / distance
                separation.dx += dx * strength
                separation.dy += dy * strength
            }
        }
        
        return separation.normalized()
    }
    
    private func hasReachedExit() -> Bool {
        let exitX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - CGFloat(GameConstants.exitZoneWidth) * GameConstants.cellSize
        return position.x >= exitX
    }
    
    // MARK: - Slow Effect
    
    func applySlow(multiplier: CGFloat, duration: TimeInterval, currentTime: TimeInterval) {
        slowMultiplier = min(slowMultiplier, multiplier) // Use strongest slow
        slowEndTime = max(slowEndTime, currentTime + duration) // Use longest duration
        isSlowed = true
        slowIndicator.isHidden = false
        
        // Visual feedback
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        slowIndicator.run(SKAction.repeatForever(pulse), withKey: "slowPulse")
    }
    
    private func updateSlowStatus(currentTime: TimeInterval) {
        if isSlowed && currentTime >= slowEndTime {
            isSlowed = false
            slowMultiplier = 1.0
            slowIndicator.isHidden = true
            slowIndicator.removeAction(forKey: "slowPulse")
        }
    }
    
    // MARK: - Damage
    
    func takeDamage(_ damage: CGFloat, armorPenetration: CGFloat = 0) {
        guard isAlive else { return }
        
        // Calculate effective damage
        let effectiveArmor = max(0, armor - armorPenetration)
        let damageReduction = effectiveArmor / (effectiveArmor + 100) // Diminishing returns
        let actualDamage = damage * (1 - damageReduction)
        
        currentHealth -= actualDamage
        
        // Update health bar
        updateHealthBar()
        
        // Flash effect
        let flash = SKAction.sequence([
            SKAction.run { self.bodyNode.fillColor = .white },
            SKAction.wait(forDuration: 0.05),
            SKAction.run { self.bodyNode.fillColor = self.enemyType.color }
        ])
        bodyNode.run(flash)
        
        // Check death
        if currentHealth <= 0 {
            die()
        }
    }
    
    private func updateHealthBar() {
        let healthPercent = max(0, currentHealth / maxHealth)
        let fullWidth: CGFloat = enemySize + 8
        
        // Update fill width using scale
        healthBarFill.xScale = healthPercent
        healthBarFill.position.x = -(fullWidth * (1 - healthPercent)) / 2
        
        // Update color based on health
        if healthPercent > 0.6 {
            healthBarFill.fillColor = .healthBarGreen
        } else if healthPercent > 0.3 {
            healthBarFill.fillColor = .healthBarYellow
        } else {
            healthBarFill.fillColor = .healthBarRed
        }
    }
    
    // MARK: - Death & Exit
    
    private func die() {
        guard isAlive else { return }
        isAlive = false
        
        // Death animation
        let deathAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        
        // Spawn particles
        spawnDeathParticles()
        
        run(deathAnimation)
        delegate?.enemyDidDie(self)
    }
    
    private func reachExit() {
        guard isAlive else { return }
        isAlive = false
        
        // Exit animation
        let exitAnimation = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        
        run(exitAnimation)
        delegate?.enemyDidReachExit(self)
    }
    
    private func spawnDeathParticles() {
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: 4)
            particle.fillColor = enemyType.color
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = GameConstants.ZPosition.effects.rawValue
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...40)
            let destination = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let animation = SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: destination, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 0.1, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ])
            
            parent?.addChild(particle)
            particle.run(animation)
        }
    }
}
