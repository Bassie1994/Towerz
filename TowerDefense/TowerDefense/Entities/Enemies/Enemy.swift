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
        
        // Safety check for valid delta time
        guard deltaTime > 0 && deltaTime < 1.0 else { return }
        
        // Update slow status
        updateSlowStatus(currentTime: currentTime)
        
        // Calculate movement
        var direction = calculateMovementDirection()
        
        // Safety: ensure direction is valid
        if direction.dx.isNaN || direction.dy.isNaN || 
           (direction.dx == 0 && direction.dy == 0) {
            direction = CGVector(dx: 1, dy: 0)
        }
        
        // Apply separation from other enemies
        let separation = calculateSeparation(from: enemies)
        
        // Combine forces
        var combinedDirection = CGVector(
            dx: direction.dx + separation.dx * 0.3,
            dy: direction.dy + separation.dy * 0.3
        )
        
        // Safety: ensure combined direction is valid before normalizing
        let magnitude = sqrt(combinedDirection.dx * combinedDirection.dx + combinedDirection.dy * combinedDirection.dy)
        if magnitude > 0 {
            combinedDirection = CGVector(dx: combinedDirection.dx / magnitude, dy: combinedDirection.dy / magnitude)
        } else {
            combinedDirection = CGVector(dx: 1, dy: 0)
        }
        
        // Smooth direction change to prevent jittering
        currentDirection = CGVector(
            dx: currentDirection.dx * 0.7 + combinedDirection.dx * 0.3,
            dy: currentDirection.dy * 0.7 + combinedDirection.dy * 0.3
        )
        
        // Normalize current direction safely
        let currentMag = sqrt(currentDirection.dx * currentDirection.dx + currentDirection.dy * currentDirection.dy)
        if currentMag > 0 {
            currentDirection = CGVector(dx: currentDirection.dx / currentMag, dy: currentDirection.dy / currentMag)
        } else {
            currentDirection = CGVector(dx: 1, dy: 0)
        }
        
        // Calculate actual speed (with slow effect)
        let actualSpeed = moveSpeed * slowMultiplier
        
        // Move
        let movement = CGVector(
            dx: currentDirection.dx * actualSpeed * CGFloat(deltaTime),
            dy: currentDirection.dy * actualSpeed * CGFloat(deltaTime)
        )
        
        // Calculate new position
        var newPosition = CGPoint(
            x: position.x + movement.dx,
            y: position.y + movement.dy
        )
        
        // Collision detection with towers/blocked cells
        let newGridPos = newPosition.toGridPosition()
        if newGridPos.x >= 0 && newGridPos.x < GameConstants.gridWidth &&
           newGridPos.y >= 0 && newGridPos.y < GameConstants.gridHeight {
            
            // Check if new position is blocked
            if let flowField = delegate?.getFlowField() {
                let isBlocked = flowField.getDirection(at: newGridPos) == nil && 
                                !newGridPos.isInSpawnZone() && 
                                !newGridPos.isInExitZone()
                
                if isBlocked {
                    // Try multiple alternatives to find a way around
                    let moveDistance = actualSpeed * CGFloat(deltaTime)
                    
                    // Try 8 different directions to find a valid path
                    let alternatives: [(CGFloat, CGFloat)] = [
                        (movement.dx, 0),           // Horizontal only
                        (0, movement.dy),           // Vertical only
                        (moveDistance, 0),          // Pure right
                        (-moveDistance, 0),         // Pure left
                        (0, moveDistance),          // Pure up
                        (0, -moveDistance),         // Pure down
                        (moveDistance, -moveDistance), // Diagonal down-right
                        (moveDistance, moveDistance)   // Diagonal up-right
                    ]
                    
                    var foundPath = false
                    for (dx, dy) in alternatives {
                        let testPos = CGPoint(x: position.x + dx, y: position.y + dy)
                        let testGrid = testPos.toGridPosition()
                        
                        // Check bounds
                        guard testGrid.x >= 0 && testGrid.x < GameConstants.gridWidth &&
                              testGrid.y >= 0 && testGrid.y < GameConstants.gridHeight else { continue }
                        
                        let testBlocked = flowField.getDirection(at: testGrid) == nil &&
                                         !testGrid.isInSpawnZone() && !testGrid.isInExitZone()
                        
                        if !testBlocked {
                            newPosition = testPos
                            foundPath = true
                            break
                        }
                    }
                    
                    if !foundPath {
                        // Still stuck - try to push away from the blocking cell
                        let currentGrid = position.toGridPosition()
                        if let escapeDir = flowField.getDirection(at: currentGrid) {
                            newPosition = CGPoint(
                                x: position.x + escapeDir.dx * moveDistance * 0.5,
                                y: position.y + escapeDir.dy * moveDistance * 0.5
                            )
                        }
                    }
                }
            }
        }
        
        position = newPosition
        
        // Clamp to playfield bounds
        let minY = GameConstants.playFieldOrigin.y + enemySize / 2
        let maxY = GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - enemySize / 2
        let minX = GameConstants.playFieldOrigin.x + enemySize / 2
        let maxX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - enemySize / 2
        position.y = max(minY, min(maxY, position.y))
        position.x = max(minX, min(maxX, position.x))
        
        // Check if reached exit
        if hasReachedExit() {
            reachExit()
        }
    }
    
    /// Override in subclasses for different movement behavior
    func calculateMovementDirection() -> CGVector {
        // Use flow field for navigation (line-of-sight disabled for stability)
        if let flowField = delegate?.getFlowField(),
           let direction = flowField.getInterpolatedDirection(at: position) {
            return direction
        }
        
        // Fallback: move toward bottom-right
        return CGVector(dx: 1, dy: -1).normalized()
    }
    
    /// Check if there's a clear line to the exit - returns direction if clear
    private func getDirectPathToExit() -> CGVector? {
        // Target is bottom-right corner
        let exitX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - GameConstants.cellSize
        let exitY = GameConstants.playFieldOrigin.y + GameConstants.cellSize * 2
        let targetPoint = CGPoint(x: exitX, y: exitY)
        
        // Check if we have line of sight (no blocked cells in the way)
        if hasLineOfSight(to: targetPoint) {
            let dx = targetPoint.x - position.x
            let dy = targetPoint.y - position.y
            return CGVector(dx: dx, dy: dy).normalized()
        }
        
        return nil
    }
    
    /// Check if there's a clear path (no towers) between current position and target
    private func hasLineOfSight(to target: CGPoint) -> Bool {
        let startGrid = position.toGridPosition()
        let endGrid = target.toGridPosition()
        
        // Safety: ensure valid grid positions
        guard startGrid.x >= 0 && startGrid.x < GameConstants.gridWidth &&
              startGrid.y >= 0 && startGrid.y < GameConstants.gridHeight &&
              endGrid.x >= 0 && endGrid.x < GameConstants.gridWidth &&
              endGrid.y >= 0 && endGrid.y < GameConstants.gridHeight else {
            return false
        }
        
        // Use Bresenham-style line check
        let dx = abs(endGrid.x - startGrid.x)
        let dy = abs(endGrid.y - startGrid.y)
        let sx = startGrid.x < endGrid.x ? 1 : -1
        let sy = startGrid.y < endGrid.y ? 1 : -1
        
        var x = startGrid.x
        var y = startGrid.y
        var err = dx - dy
        
        // Safety: limit iterations to prevent infinite loops
        var iterations = 0
        let maxIterations = GameConstants.gridWidth + GameConstants.gridHeight + 10
        
        // Check each cell along the line
        while iterations < maxIterations {
            iterations += 1
            
            // Bounds check
            guard x >= 0 && x < GameConstants.gridWidth &&
                  y >= 0 && y < GameConstants.gridHeight else {
                return false
            }
            
            // Skip spawn/exit zone check
            let gridPos = GridPosition(x: x, y: y)
            if !gridPos.isInSpawnZone() && !gridPos.isInExitZone() {
                // Check if this cell is blocked by a tower
                if let flowField = delegate?.getFlowField() {
                    if flowField.getDirection(at: gridPos) == nil {
                        return false  // Blocked cell
                    }
                }
            }
            
            // Reached end
            if x == endGrid.x && y == endGrid.y {
                break
            }
            
            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                x += sx
            }
            if e2 < dx {
                err += dx
                y += sy
            }
        }
        
        return true
    }
    
    private func calculateSeparation(from enemies: [Enemy]) -> CGVector {
        var separation = CGVector.zero
        let separationRadius: CGFloat = enemySize * 1.2  // Reduced radius
        let radiusSquared = separationRadius * separationRadius
        
        // Optimization: limit checks to 5 for better performance
        var checksPerformed = 0
        let maxChecks = 5
        
        for other in enemies {
            guard checksPerformed < maxChecks else { break }
            guard other.id != self.id && other.isAlive else { continue }
            
            // Quick distance check first (avoid sqrt)
            let dx = position.x - other.position.x
            let dy = position.y - other.position.y
            let distSquared = dx * dx + dy * dy
            
            if distSquared < radiusSquared && distSquared > 1 {
                checksPerformed += 1
                // Approximate separation without sqrt for performance
                let invDist = 1.0 / (distSquared + 10)  // +10 to avoid division issues
                separation.dx += dx * invDist * 50
                separation.dy += dy * invDist * 50
            }
        }
        
        // Simple normalization
        let len = sqrt(separation.dx * separation.dx + separation.dy * separation.dy)
        if len > 0.1 {
            return CGVector(dx: separation.dx / len, dy: separation.dy / len)
        }
        return .zero
    }
    
    private func hasReachedExit() -> Bool {
        // Exit is in bottom-right corner
        let exitX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - CGFloat(GameConstants.exitZoneWidth) * GameConstants.cellSize
        let exitY = GameConstants.playFieldOrigin.y + CGFloat(4) * GameConstants.cellSize  // Top of exit zone (4 rows)
        
        // Must be in both the right columns AND bottom rows
        return position.x >= exitX && position.y < exitY
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
