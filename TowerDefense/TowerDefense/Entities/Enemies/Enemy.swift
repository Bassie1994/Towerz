import SpriteKit

/// Protocol for enemy event handling
protocol EnemyDelegate: AnyObject {
    func enemyDidReachExit(_ enemy: Enemy)
    func enemyDidDie(_ enemy: Enemy)
    func getFlowField() -> FlowField?
}

/// Base class for all enemy types
class Enemy: SKNode {

    struct NavigationDebugSnapshot {
        let collisionDetours: Int
        let flowRescues: Int
        let recoveryModeEntries: Int
        let nearestCellFallbacks: Int
    }

    private struct NavigationDebugStats {
        var collisionDetours = 0
        var flowRescues = 0
        var recoveryModeEntries = 0
        var nearestCellFallbacks = 0
    }

    private static var navigationDebugStats = NavigationDebugStats()
    
    static func resetNavigationDebugStats() {
        navigationDebugStats = NavigationDebugStats()
    }

    static func navigationDebugSnapshot() -> NavigationDebugSnapshot {
        NavigationDebugSnapshot(
            collisionDetours: navigationDebugStats.collisionDetours,
            flowRescues: navigationDebugStats.flowRescues,
            recoveryModeEntries: navigationDebugStats.recoveryModeEntries,
            nearestCellFallbacks: navigationDebugStats.nearestCellFallbacks
        )
    }
    
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

    // Support buff status
    var supportSpeedMultiplier: CGFloat = 1.0
    var supportDamageReduction: CGFloat = 0.0
    private var supportEndTime: TimeInterval = 0
    
    // Drunk movement (Booze effect) - 1.5 cell amplitude swerving
    var drunkPhase: CGFloat = CGFloat.random(in: 0...(.pi * 2))
    var drunkAmplitude: CGFloat = CGFloat.random(in: 0.8...1.2)  // Very strong sway
    
    // Visual components
    let bodyNode: SKShapeNode
    let healthBarBackground: SKShapeNode
    let healthBarFill: SKShapeNode
    let slowIndicator: SKShapeNode
    let supportIndicator: SKShapeNode
    var healthBarBaseScaleX: CGFloat = 1.0
    var healthBarBaseScaleY: CGFloat = 1.0
    
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
    private var lastDistanceToExit: Int = Int.max
    private var progressStallTime: TimeInterval = 0
    
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

        // Create support indicator
        supportIndicator = SKShapeNode(circleOfRadius: enemySize / 2 + 5)
        supportIndicator.fillColor = .clear
        supportIndicator.strokeColor = .buffEffect
        supportIndicator.lineWidth = 2
        supportIndicator.isHidden = true
        
        super.init()
        
        addChild(slowIndicator)
        addChild(supportIndicator)
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
        case .shielded:
            indicator.text = "🛡"
        case .support:
            indicator.text = "+"
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
        updateSupportStatus(currentTime: currentTime)
        moveSpeed = baseMoveSpeed * supportSpeedMultiplier
        
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
        
        // Apply corridor centering - keep units in middle of available path width
        let centering = calculateCorridorCentering()

        // Explicit centerline guidance to keep units on path center segments.
        let centerlineGuidance = calculateCenterlineGuidance()

        // Combine forces:
        // - centering keeps units away from walls
        // - centerline keeps them on the middle of the active flow segment
        let centeringStrength: CGFloat = enemyType == .boss ? 0.35 : (enemyType == .cavalry ? 0.30 : 0.25)
        let centerlineStrength: CGFloat = enemyType == .boss ? 0.95 : (enemyType == .cavalry ? 0.80 : 0.70)
        var combinedDirection = CGVector(
            dx: direction.dx + separation.dx * 0.3 + centering.dx * centeringStrength + centerlineGuidance.dx * centerlineStrength,
            dy: direction.dy + separation.dy * 0.3 + centering.dy * centeringStrength + centerlineGuidance.dy * centerlineStrength
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
        let moveDistance = actualSpeed * CGFloat(deltaTime)
        
        // Calculate desired new position
        var newPosition = CGPoint(
            x: position.x + currentDirection.dx * moveDistance,
            y: position.y + currentDirection.dy * moveDistance
        )
        
        // HARD COLLISION: Check if new position is in a blocked cell
        newPosition = validateAndAdjustPosition(newPosition, moveDistance: moveDistance)
        
        position = newPosition

        // Clamp to playfield bounds
        let minY = GameConstants.playFieldOrigin.y + enemySize / 2
        let maxY = GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - enemySize / 2
        let minX = GameConstants.playFieldOrigin.x + enemySize / 2
        let maxX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - enemySize / 2
        position.y = max(minY, min(maxY, position.y))
        position.x = max(minX, min(maxX, position.x))

        // Track progress toward the exit; if it stalls, snap back onto the flow field
        if let flowField = delegate?.getFlowField() {
            let currentGrid = position.toGridPosition()
            let currentDistance = flowField.getDistance(at: currentGrid)

            if currentDistance < lastDistanceToExit {
                progressStallTime = 0
            } else {
                progressStallTime += deltaTime
            }

            lastDistanceToExit = currentDistance

            if progressStallTime > 2.5, let reachable = flowField.nearestReachableCell(from: currentGrid, maxSearchRadius: 8) {
                Enemy.navigationDebugStats.flowRescues += 1
                position = reachable.toWorldPosition()
                lastPosition = position
                stuckTime = 0
                progressStallTime = 0
                isInRecoveryMode = false
                recoveryCellsRemaining = 0
                currentDirection = CGVector(dx: 1, dy: 0)
            }
        }

        // Time-based stuck detection (7 seconds triggers recovery mode)
        let movedDistance = position.distance(to: lastPosition)
        let cellSize = GameConstants.cellSize
        
        if movedDistance < cellSize * 0.1 {
            // Barely moved - accumulate stuck time
            stuckTime += deltaTime
            
            if stuckTime >= 7.0 && !isInRecoveryMode {
                Enemy.navigationDebugStats.recoveryModeEntries += 1
                // Enter recovery mode - snap to current cell center and follow path centers
                isInRecoveryMode = true
                recoveryCellsRemaining = 6
                progressStallTime = 0

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
        let separationRadius: CGFloat = {
            switch enemyType {
            case .boss: return enemySize * 1.7
            case .cavalry: return enemySize * 1.45
            case .shielded: return enemySize * 1.4
            case .support: return enemySize * 1.3
            case .infantry, .flying: return enemySize * 1.2
            }
        }()
        let radiusSquared = separationRadius * separationRadius
        
        // Optimization: cap checks, but allow enough neighbors to react in chokepoints.
        var checksPerformed = 0
        let maxChecks = 12
        var closeNeighborCount = 0
        
        for other in enemies {
            guard checksPerformed < maxChecks else { break }
            guard other.id != self.id && other.isAlive else { continue }
            
            // Quick distance check first (avoid sqrt)
            let dx = position.x - other.position.x
            let dy = position.y - other.position.y
            let distSquared = dx * dx + dy * dy
            
            if distSquared < radiusSquared && distSquared > 1 {
                checksPerformed += 1
                closeNeighborCount += 1
                // Approximate separation without sqrt for performance
                let invDist = 1.0 / (distSquared + 10)  // +10 to avoid division issues
                separation.dx += dx * invDist * 50
                separation.dy += dy * invDist * 50
            }
        }

        // Stronger push when units pile up in narrow corridors.
        if closeNeighborCount > 2 {
            let crowdMultiplier = min(2.4, 1.0 + CGFloat(closeNeighborCount - 2) * 0.18)
            separation.dx *= crowdMultiplier
            separation.dy *= crowdMultiplier
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

    /// Calculate steering toward the centerline of the current flow segment.
    /// This prevents units from riding along cell edges and clipping tower corners.
    private func calculateCenterlineGuidance() -> CGVector {
        guard let flowField = delegate?.getFlowField() else { return .zero }

        let gridPos = position.toGridPosition()
        guard gridPos.x >= 0 && gridPos.x < GameConstants.gridWidth &&
              gridPos.y >= 0 && gridPos.y < GameConstants.gridHeight else {
            return .zero
        }

        let currentCenter = gridPos.toWorldPosition()

        guard let dir = flowField.getDirection(at: gridPos) else {
            // If direction is unavailable, fall back to local cell center.
            let toCenter = CGVector(dx: currentCenter.x - position.x, dy: currentCenter.y - position.y)
            let len = sqrt(toCenter.dx * toCenter.dx + toCenter.dy * toCenter.dy)
            guard len > 0.05 else { return .zero }
            return CGVector(dx: toCenter.dx / len, dy: toCenter.dy / len)
        }

        // Convert flow vector to a reliable grid step.
        var stepX = 0
        var stepY = 0
        if dir.dx > 0.2 { stepX = 1 }
        else if dir.dx < -0.2 { stepX = -1 }

        if dir.dy > 0.2 { stepY = 1 }
        else if dir.dy < -0.2 { stepY = -1 }

        // Fallback when vector is shallow.
        if stepX == 0 && stepY == 0 {
            if abs(dir.dx) >= abs(dir.dy) {
                stepX = dir.dx >= 0 ? 1 : -1
            } else {
                stepY = dir.dy >= 0 ? 1 : -1
            }
        }

        let nextGrid = GridPosition(
            x: max(0, min(GameConstants.gridWidth - 1, gridPos.x + stepX)),
            y: max(0, min(GameConstants.gridHeight - 1, gridPos.y + stepY))
        )
        let nextCenter = nextGrid.toWorldPosition()

        let segX = nextCenter.x - currentCenter.x
        let segY = nextCenter.y - currentCenter.y
        let segLenSq = segX * segX + segY * segY

        // Degenerate segment: just steer to current center.
        guard segLenSq > 0.001 else {
            let toCenter = CGVector(dx: currentCenter.x - position.x, dy: currentCenter.y - position.y)
            let len = sqrt(toCenter.dx * toCenter.dx + toCenter.dy * toCenter.dy)
            guard len > 0.05 else { return .zero }
            return CGVector(dx: toCenter.dx / len, dy: toCenter.dy / len)
        }

        // Project position onto currentCenter->nextCenter to get closest point on centerline.
        let relX = position.x - currentCenter.x
        let relY = position.y - currentCenter.y
        let tRaw = (relX * segX + relY * segY) / segLenSq
        let t = max(0, min(1, tRaw))

        let closestPoint = CGPoint(
            x: currentCenter.x + segX * t,
            y: currentCenter.y + segY * t
        )

        let toLine = CGVector(dx: closestPoint.x - position.x, dy: closestPoint.y - position.y)
        let toCenter = CGVector(dx: currentCenter.x - position.x, dy: currentCenter.y - position.y)

        // Blend line attraction with cell-center attraction for stable movement.
        let guide = CGVector(
            dx: toLine.dx * 0.85 + toCenter.dx * 0.35,
            dy: toLine.dy * 0.85 + toCenter.dy * 0.35
        )

        let len = sqrt(guide.dx * guide.dx + guide.dy * guide.dy)
        guard len > 0.05 else { return .zero }
        return CGVector(dx: guide.dx / len, dy: guide.dy / len)
    }
    
    /// Robust maze collision:
    /// - keeps units out of blocked cells
    /// - avoids hugging tower corners
    /// - picks the best fallback step when direct movement is blocked
    private func validateAndAdjustPosition(_ desiredPos: CGPoint, moveDistance: CGFloat) -> CGPoint {
        let cellSize = GameConstants.cellSize
        let origin = GameConstants.playFieldOrigin
        let flowField = delegate?.getFlowField()
        let currentGridPos = position.toGridPosition()
        let clearance = cornerClearance(for: cellSize)
        
        // Helper to check if a grid cell is blocked
        func isBlocked(_ gridPos: GridPosition) -> Bool {
            guard gridPos.x >= 0 && gridPos.x < GameConstants.gridWidth &&
                  gridPos.y >= 0 && gridPos.y < GameConstants.gridHeight else { return true }
            if gridPos.isInSpawnZone() || gridPos.isInExitZone() { return false }
            guard let flowField else { return true }
            return flowField.getDirection(at: gridPos) == nil
        }
        
        // Helper to get cell center
        func cellCenter(_ gridPos: GridPosition) -> CGPoint {
            return CGPoint(
                x: origin.x + CGFloat(gridPos.x) * cellSize + cellSize / 2,
                y: origin.y + CGFloat(gridPos.y) * cellSize + cellSize / 2
            )
        }

        func flowDistanceScore(at gridPos: GridPosition) -> CGFloat {
            guard let flowField else { return 9_999 }
            let distance = flowField.getDistance(at: gridPos)
            if distance >= 1_000_000 { return 9_999 }
            return CGFloat(distance)
        }

        // Validate not just by cell occupancy, but also by local clearance to blocked neighbors.
        func isSafePosition(_ worldPos: CGPoint) -> Bool {
            let gridPos = worldPos.toGridPosition()
            guard !isBlocked(gridPos) else { return false }

            let center = cellCenter(gridPos)
            let localX = worldPos.x - center.x
            let localY = worldPos.y - center.y
            let halfCell = cellSize / 2

            let nearRight = localX > halfCell - clearance
            let nearLeft = localX < -halfCell + clearance
            let nearTop = localY > halfCell - clearance
            let nearBottom = localY < -halfCell + clearance

            if nearRight && isBlocked(GridPosition(x: gridPos.x + 1, y: gridPos.y)) { return false }
            if nearLeft && isBlocked(GridPosition(x: gridPos.x - 1, y: gridPos.y)) { return false }
            if nearTop && isBlocked(GridPosition(x: gridPos.x, y: gridPos.y + 1)) { return false }
            if nearBottom && isBlocked(GridPosition(x: gridPos.x, y: gridPos.y - 1)) { return false }

            // Extra corner protection to prevent snagging on tower corners.
            if nearRight && nearTop && isBlocked(GridPosition(x: gridPos.x + 1, y: gridPos.y + 1)) { return false }
            if nearRight && nearBottom && isBlocked(GridPosition(x: gridPos.x + 1, y: gridPos.y - 1)) { return false }
            if nearLeft && nearTop && isBlocked(GridPosition(x: gridPos.x - 1, y: gridPos.y + 1)) { return false }
            if nearLeft && nearBottom && isBlocked(GridPosition(x: gridPos.x - 1, y: gridPos.y - 1)) { return false }

            return true
        }

        // Happy path: direct movement is valid.
        if isSafePosition(desiredPos) {
            return desiredPos
        }

        var candidates: [CGPoint] = []
        candidates.reserveCapacity(24)

        // Axis slides often resolve simple corner blocks.
        candidates.append(CGPoint(x: desiredPos.x, y: position.y))
        candidates.append(CGPoint(x: position.x, y: desiredPos.y))
        candidates.append(position)

        // Try small angular variations around current direction.
        let baseAngle = atan2(currentDirection.dy, currentDirection.dx)
        let angleOffsets: [CGFloat] = [0, .pi / 8, -.pi / 8, .pi / 4, -.pi / 4, .pi / 2, -.pi / 2]
        for offset in angleOffsets {
            let angle = baseAngle + offset
            candidates.append(
                CGPoint(
                    x: position.x + cos(angle) * moveDistance,
                    y: position.y + sin(angle) * moveDistance
                )
            )
        }

        // Also try moving toward centers of neighboring walkable cells.
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let neighbor = GridPosition(x: currentGridPos.x + dx, y: currentGridPos.y + dy)
                guard !isBlocked(neighbor) else { continue }

                let center = cellCenter(neighbor)
                let toCenter = CGVector(dx: center.x - position.x, dy: center.y - position.y)
                let len = sqrt(toCenter.dx * toCenter.dx + toCenter.dy * toCenter.dy)
                guard len > 0.001 else { continue }

                let step = min(moveDistance, len)
                candidates.append(
                    CGPoint(
                        x: position.x + toCenter.dx / len * step,
                        y: position.y + toCenter.dy / len * step
                    )
                )
            }
        }

        var bestCandidate: CGPoint?
        var bestScore = CGFloat.greatestFiniteMagnitude

        for candidate in candidates where isSafePosition(candidate) {
            let gridPos = candidate.toGridPosition()
            let score =
                flowDistanceScore(at: gridPos) * 100 +
                candidate.distance(to: desiredPos) +
                candidate.distance(to: cellCenter(gridPos)) * 0.05

            if score < bestScore {
                bestScore = score
                bestCandidate = candidate
            }
        }

        if let bestCandidate {
            Enemy.navigationDebugStats.collisionDetours += 1
            return bestCandidate
        }

        // Last resort: nudge back toward the nearest reachable flow cell.
        if let flowField,
           let reachable = flowField.nearestReachableCell(from: currentGridPos, maxSearchRadius: 5) {
            let center = cellCenter(reachable)
            let toCenter = CGVector(dx: center.x - position.x, dy: center.y - position.y)
            let len = sqrt(toCenter.dx * toCenter.dx + toCenter.dy * toCenter.dy)
            if len > 0.001 {
                Enemy.navigationDebugStats.nearestCellFallbacks += 1
                let step = min(moveDistance, len)
                return CGPoint(
                    x: position.x + toCenter.dx / len * step,
                    y: position.y + toCenter.dy / len * step
                )
            }
        }

        // Absolute fallback: don't move this frame.
        return position
    }
    
    private func hasReachedExit() -> Bool {
        // Exit is in bottom-right corner
        let exitX = GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - CGFloat(GameConstants.exitZoneWidth) * GameConstants.cellSize
        let exitY = GameConstants.playFieldOrigin.y + CGFloat(GameConstants.exitZoneHeight) * GameConstants.cellSize
        
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

    // MARK: - Support Buff

    func applySupportBuff(speedMultiplier: CGFloat, damageReduction: CGFloat, duration: TimeInterval, currentTime: TimeInterval) {
        supportSpeedMultiplier = max(supportSpeedMultiplier, speedMultiplier)
        supportDamageReduction = max(supportDamageReduction, min(0.8, damageReduction))
        supportEndTime = max(supportEndTime, currentTime + duration)
        supportIndicator.isHidden = false

        if supportIndicator.action(forKey: "supportPulse") == nil {
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ])
            supportIndicator.run(SKAction.repeatForever(pulse), withKey: "supportPulse")
        }
    }

    func updateSupportStatus(currentTime: TimeInterval) {
        if supportEndTime > 0 && currentTime >= supportEndTime {
            supportSpeedMultiplier = 1.0
            supportDamageReduction = 0.0
            supportEndTime = 0
            supportIndicator.isHidden = true
            supportIndicator.removeAction(forKey: "supportPulse")
        }
    }
    
    // MARK: - Damage
    
    func takeDamage(_ damage: CGFloat, armorPenetration: CGFloat = 0) {
        guard isAlive else { return }
        
        // Calculate effective damage
        let effectiveArmor = max(0, armor - armorPenetration)
        let damageReduction = effectiveArmor / (effectiveArmor + 100) // Diminishing returns
        let actualDamage = damage * (1 - damageReduction) * (1 - supportDamageReduction)
        
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
        healthBarFill.xScale = healthBarBaseScaleX * healthPercent
        healthBarFill.yScale = healthBarBaseScaleY
        let scaledWidth = fullWidth * healthBarBaseScaleX
        healthBarFill.position.x = -(scaledWidth * (1 - healthPercent)) / 2
        
        // Update color based on health
        if healthPercent > 0.6 {
            healthBarFill.fillColor = .healthBarGreen
        } else if healthPercent > 0.3 {
            healthBarFill.fillColor = .healthBarYellow
        } else {
            healthBarFill.fillColor = .healthBarRed
        }
    }

    func configureHealthBarScale(x: CGFloat, y: CGFloat) {
        healthBarBaseScaleX = max(0.1, x)
        healthBarBaseScaleY = max(0.1, y)
        healthBarFill.xScale = healthBarBaseScaleX
        healthBarFill.yScale = healthBarBaseScaleY
        updateHealthBar()
    }

    private func cornerClearance(for cellSize: CGFloat) -> CGFloat {
        let tunedClearance: CGFloat
        switch enemyType {
        case .boss:
            tunedClearance = min(enemySize * 0.42, cellSize * 0.28)
        case .cavalry:
            tunedClearance = min(enemySize * 0.32, cellSize * 0.24)
        case .shielded:
            tunedClearance = min(enemySize * 0.30, cellSize * 0.23)
        case .support:
            tunedClearance = min(enemySize * 0.26, cellSize * 0.21)
        case .infantry:
            tunedClearance = min(enemySize * 0.24, cellSize * 0.20)
        case .flying:
            tunedClearance = min(enemySize * 0.18, cellSize * 0.14)
        }
        return max(3.0, tunedClearance)
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
