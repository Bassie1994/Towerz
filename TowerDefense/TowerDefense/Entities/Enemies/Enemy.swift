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
    
    // Drunk movement (Booze effect) - 1.5 cell amplitude swerving
    var drunkPhase: CGFloat = CGFloat.random(in: 0...(.pi * 2))
    var drunkAmplitude: CGFloat = CGFloat.random(in: 0.8...1.2)  // Very strong sway
    
    // Visual components
    let bodyNode: SKShapeNode
    let healthBarBackground: SKShapeNode
    let healthBarFill: SKShapeNode
    let slowIndicator: SKShapeNode
    
    // Movement
    var currentDirection: CGVector = CGVector(dx: 1, dy: 0)
    var separationForce: CGVector = .zero
    
    // Stuck detection and recovery
    private var lastPosition: CGPoint = .zero
    private var stuckTime: TimeInterval = 0
    private var lastMoveTime: TimeInterval = 0
    private var isInRecoveryMode: Bool = false
    private var recoveryCellsRemaining: Int = 0
    private var recoveryTargetCenter: CGPoint = .zero
    
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
        case .boss:
            indicator.text = "💀"
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
        
        // Calculate actual speed first (needed for recovery mode)
        let actualSpeed = moveSpeed * slowMultiplier
        
        // Check if in recovery mode (stuck for 7+ seconds, following cell centers)
        if let recoveryPos = handleRecoveryMode(deltaTime: deltaTime, actualSpeed: actualSpeed) {
            position = recoveryPos
            
            // Clamp to playfield bounds
            let minY = GameConstants.playFieldOrigin.y + enemySize / 2
            let maxY = GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - enemySize / 2
            let minX = GameConstants.playFieldOrigin.x + enemySize / 2
            let maxX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - enemySize / 2
            position.y = max(minY, min(maxY, position.y))
            position.x = max(minX, min(maxX, position.x))
            
            lastPosition = position
            
            if hasReachedExit() {
                reachExit()
            }
            return
        }
        
        // Calculate movement
        var direction = calculateMovementDirection()
        
        // Safety: ensure direction is valid
        if direction.dx.isNaN || direction.dy.isNaN || 
           (direction.dx == 0 && direction.dy == 0) {
            direction = CGVector(dx: 1, dy: 0)
        }
        
        // Apply separation from other enemies
        let separation = calculateSeparation(from: enemies)
        
        // Apply corridor centering - keep units in middle 25% of available path
        let centering = calculateCorridorCentering()
        
        // Combine forces (centering is stronger for larger units)
        let centeringStrength: CGFloat = enemyType == .boss ? 0.6 : (enemyType == .cavalry ? 0.5 : 0.4)
        var combinedDirection = CGVector(
            dx: direction.dx + separation.dx * 0.3 + centering.dx * centeringStrength,
            dy: direction.dy + separation.dy * 0.3 + centering.dy * centeringStrength
        )
        
        // Safety: ensure combined direction is valid before normalizing
        let magnitude = sqrt(combinedDirection.dx * combinedDirection.dx + combinedDirection.dy * combinedDirection.dy)
        if magnitude > 0 {
            combinedDirection = CGVector(dx: combinedDirection.dx / magnitude, dy: combinedDirection.dy / magnitude)
        } else {
            combinedDirection = CGVector(dx: 1, dy: 0)
        }
        
        // Apply drunk movement if booze is active - 1.5 cell amplitude swerving!
        if BoozeManager.shared.isActive {
            // Base 5-degree deviation (wrong direction)
            let baseDeviation: CGFloat = 5.0 * .pi / 180.0
            let currentAngle = atan2(combinedDirection.dy, combinedDirection.dx)
            let deviatedAngle = currentAngle + baseDeviation
            
            // Very strong swerving - up to 60 degrees (1.5 cell width at typical distances)
            drunkPhase += CGFloat(deltaTime) * 5.0  // Oscillation speed
            
            // Primary sway: huge amplitude (±60 degrees max)
            let maxSwayAngle: CGFloat = 60.0 * .pi / 180.0  // 60 degrees in radians
            let swayAngle = sin(drunkPhase) * maxSwayAngle * drunkAmplitude
            
            // Secondary wobble for more chaotic movement
            let secondarySway = cos(drunkPhase * 2.3) * maxSwayAngle * 0.4 * drunkAmplitude
            let tertiarySway = sin(drunkPhase * 0.7) * maxSwayAngle * 0.2
            
            let swayedAngle = deviatedAngle + swayAngle + secondarySway + tertiarySway
            combinedDirection = CGVector(
                dx: cos(swayedAngle),
                dy: sin(swayedAngle)
            )
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
        
        // Move (actualSpeed already calculated at start of update)
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
                    
                    // Calculate direction to exit for smarter pathing
                    let exitX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width
                    let exitY = GameConstants.playFieldOrigin.y + GameConstants.cellSize * 2
                    let toExitX = exitX - position.x
                    let toExitY = exitY - position.y
                    let preferDown = toExitY < 0
                    
                    // Try directions in priority order based on where exit is
                    var alternatives: [(CGFloat, CGFloat)] = []
                    
                    if preferDown {
                        // Exit is below - prefer going down and right
                        alternatives = [
                            (moveDistance, -moveDistance),  // Down-right diagonal
                            (0, -moveDistance),             // Pure down
                            (moveDistance, 0),              // Pure right
                            (moveDistance, -moveDistance * 2), // Steep down-right
                            (-moveDistance, -moveDistance), // Down-left diagonal
                            (0, -moveDistance * 2),         // Double down
                            (moveDistance * 2, 0),          // Double right
                            (-moveDistance, 0),             // Left (escape)
                            (0, moveDistance),              // Up (escape)
                        ]
                    } else {
                        // Exit is above or level - prefer going up and right
                        alternatives = [
                            (moveDistance, moveDistance),   // Up-right diagonal
                            (0, moveDistance),              // Pure up
                            (moveDistance, 0),              // Pure right
                            (moveDistance, moveDistance * 2), // Steep up-right
                            (-moveDistance, moveDistance),  // Up-left diagonal
                            (0, moveDistance * 2),          // Double up
                            (moveDistance * 2, 0),          // Double right
                            (-moveDistance, 0),             // Left (escape)
                            (0, -moveDistance),             // Down (escape)
                        ]
                    }
                    
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
                        // Still stuck - try sliding along the tower edge
                        let currentGrid = position.toGridPosition()
                        
                        // Check which adjacent cells are free
                        let cellSize = GameConstants.cellSize
                        let cellCenterX = GameConstants.playFieldOrigin.x + CGFloat(newGridPos.x) * cellSize + cellSize / 2
                        let cellCenterY = GameConstants.playFieldOrigin.y + CGFloat(newGridPos.y) * cellSize + cellSize / 2
                        
                        // Push away from the blocked cell center
                        let pushX = position.x - cellCenterX
                        let pushY = position.y - cellCenterY
                        let pushMag = sqrt(pushX * pushX + pushY * pushY)
                        
                        if pushMag > 0 {
                            // Slide perpendicular to the push direction, biased toward exit
                            let slideX = preferDown ? moveDistance : moveDistance
                            let slideY = preferDown ? -moveDistance * 0.5 : moveDistance * 0.5
                            newPosition = CGPoint(
                                x: position.x + slideX + (pushX / pushMag) * moveDistance * 0.3,
                                y: position.y + slideY + (pushY / pushMag) * moveDistance * 0.3
                            )
                        } else if let escapeDir = flowField.getDirection(at: currentGrid) {
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
        
        // Time-based stuck detection (7 seconds triggers recovery mode)
        let movedDistance = position.distance(to: lastPosition)
        let cellSize = GameConstants.cellSize
        
        if movedDistance < cellSize * 0.1 {
            // Barely moved - accumulate stuck time
            stuckTime += deltaTime
            
            if stuckTime >= 7.0 && !isInRecoveryMode {
                // Enter recovery mode - snap to current cell center and follow path centers
                isInRecoveryMode = true
                recoveryCellsRemaining = 6
                
                // Find current cell center
                let currentGrid = position.toGridPosition()
                recoveryTargetCenter = CGPoint(
                    x: GameConstants.playFieldOrigin.x + CGFloat(currentGrid.x) * cellSize + cellSize / 2,
                    y: GameConstants.playFieldOrigin.y + CGFloat(currentGrid.y) * cellSize + cellSize / 2
                )
                stuckTime = 0
            }
        } else {
            // Moving normally
            if movedDistance > cellSize * 0.3 {
                stuckTime = 0  // Reset if moved significantly
            }
            lastMoveTime = currentTime
        }
        lastPosition = position
        
        // Check if reached exit
        if hasReachedExit() {
            reachExit()
        }
    }
    
    /// Handle recovery mode movement - follow cell centers
    private func handleRecoveryMode(deltaTime: TimeInterval, actualSpeed: CGFloat) -> CGPoint? {
        guard isInRecoveryMode else { return nil }
        
        let cellSize = GameConstants.cellSize
        let distToTarget = position.distance(to: recoveryTargetCenter)
        
        if distToTarget < cellSize * 0.3 {
            // Reached current target center
            recoveryCellsRemaining -= 1
            
            if recoveryCellsRemaining <= 0 {
                // Exit recovery mode
                isInRecoveryMode = false
                return nil
            }
            
            // Find next cell center using flow field
            let currentGrid = recoveryTargetCenter.toGridPosition()
            if let flowField = delegate?.getFlowField(),
               let dir = flowField.getDirection(at: currentGrid) {
                let nextGrid = GridPosition(
                    x: currentGrid.x + Int(round(dir.dx)),
                    y: currentGrid.y + Int(round(dir.dy))
                )
                recoveryTargetCenter = CGPoint(
                    x: GameConstants.playFieldOrigin.x + CGFloat(nextGrid.x) * cellSize + cellSize / 2,
                    y: GameConstants.playFieldOrigin.y + CGFloat(nextGrid.y) * cellSize + cellSize / 2
                )
            } else {
                // No flow field direction, exit recovery
                isInRecoveryMode = false
                return nil
            }
        }
        
        // Move toward target center
        let toTarget = CGVector(
            dx: recoveryTargetCenter.x - position.x,
            dy: recoveryTargetCenter.y - position.y
        ).normalized()
        
        return CGPoint(
            x: position.x + toTarget.dx * actualSpeed * CGFloat(deltaTime),
            y: position.y + toTarget.dy * actualSpeed * CGFloat(deltaTime)
        )
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
    
    /// Calculate force to keep unit in middle 25% of corridor
    /// Checks perpendicular distance to walls (blocked cells) and steers away from edges
    private func calculateCorridorCentering() -> CGVector {
        let gridPos = position.toGridPosition()
        
        // Scan perpendicular to movement to find corridor width
        // We'll check up/down (vertical corridor width)
        var openUp: CGFloat = 0
        var openDown: CGFloat = 0
        var openLeft: CGFloat = 0
        var openRight: CGFloat = 0
        
        let maxScan = 4  // Check up to 4 cells in each direction
        
        // Scan up
        for i in 1...maxScan {
            let checkPos = GridPosition(x: gridPos.x, y: gridPos.y + i)
            if checkPos.y < GameConstants.gridHeight {
                if let flowField = delegate?.getFlowField(),
                   flowField.getDirection(at: checkPos) != nil || checkPos.isInExitZone() || checkPos.isInSpawnZone() {
                    openUp = CGFloat(i)
                } else {
                    break
                }
            }
        }
        
        // Scan down
        for i in 1...maxScan {
            let checkPos = GridPosition(x: gridPos.x, y: gridPos.y - i)
            if checkPos.y >= 0 {
                if let flowField = delegate?.getFlowField(),
                   flowField.getDirection(at: checkPos) != nil || checkPos.isInExitZone() || checkPos.isInSpawnZone() {
                    openDown = CGFloat(i)
                } else {
                    break
                }
            }
        }
        
        // Scan left
        for i in 1...maxScan {
            let checkPos = GridPosition(x: gridPos.x - i, y: gridPos.y)
            if checkPos.x >= 0 {
                if let flowField = delegate?.getFlowField(),
                   flowField.getDirection(at: checkPos) != nil || checkPos.isInExitZone() || checkPos.isInSpawnZone() {
                    openLeft = CGFloat(i)
                } else {
                    break
                }
            }
        }
        
        // Scan right
        for i in 1...maxScan {
            let checkPos = GridPosition(x: gridPos.x + i, y: gridPos.y)
            if checkPos.x < GameConstants.gridWidth {
                if let flowField = delegate?.getFlowField(),
                   flowField.getDirection(at: checkPos) != nil || checkPos.isInExitZone() || checkPos.isInSpawnZone() {
                    openRight = CGFloat(i)
                } else {
                    break
                }
            }
        }
        
        // Calculate offset from center of corridor
        var centeringForce = CGVector.zero
        
        // Vertical centering
        let verticalCorridor = openUp + openDown + 1
        if verticalCorridor > 1 {
            let verticalCenter = openDown - openUp  // Positive = above center, negative = below
            // Only apply force if not in middle 25%
            let threshold = verticalCorridor * 0.375  // 37.5% from edge = middle 25%
            if abs(verticalCenter) > threshold {
                centeringForce.dy = -verticalCenter / verticalCorridor  // Push toward center
            }
        }
        
        // Horizontal centering (less aggressive since we want to move forward)
        let horizontalCorridor = openLeft + openRight + 1
        if horizontalCorridor > 1 {
            let horizontalCenter = openRight - openLeft  // Positive = left of center
            let threshold = horizontalCorridor * 0.375
            if abs(horizontalCenter) > threshold {
                centeringForce.dx = horizontalCenter / horizontalCorridor * 0.5  // Half strength for horizontal
            }
        }
        
        // Also add wall avoidance for immediate neighbors (stronger)
        let immediateCheck = 1
        for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
            let checkPos = GridPosition(x: gridPos.x + dx * immediateCheck, y: gridPos.y + dy * immediateCheck)
            if checkPos.x >= 0 && checkPos.x < GameConstants.gridWidth &&
               checkPos.y >= 0 && checkPos.y < GameConstants.gridHeight {
                if let flowField = delegate?.getFlowField(),
                   flowField.getDirection(at: checkPos) == nil && !checkPos.isInExitZone() && !checkPos.isInSpawnZone() {
                    // Wall nearby - push away
                    centeringForce.dx -= CGFloat(dx) * 0.8
                    centeringForce.dy -= CGFloat(dy) * 0.8
                }
            }
        }
        
        // Normalize if significant
        let len = sqrt(centeringForce.dx * centeringForce.dx + centeringForce.dy * centeringForce.dy)
        if len > 0.1 {
            return CGVector(dx: centeringForce.dx / len, dy: centeringForce.dy / len)
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
    
    func die() {
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
