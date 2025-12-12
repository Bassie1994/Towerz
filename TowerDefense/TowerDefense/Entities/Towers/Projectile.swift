import SpriteKit

/// Visual type for projectiles
enum ProjectileVisualType {
    case bullet
    case cannonBall
    case energy
}

/// Standard projectile for towers
class Projectile: SKNode {
    
    let damage: CGFloat
    let armorPenetration: CGFloat
    weak var target: Enemy?
    let speed: CGFloat
    
    var visualType: ProjectileVisualType = .bullet {
        didSet {
            updateVisual()
        }
    }
    
    private let projectileNode: SKShapeNode
    private var hasHit = false
    
    init(from startPosition: CGPoint, to target: Enemy, damage: CGFloat, speed: CGFloat, armorPenetration: CGFloat = 0) {
        self.damage = damage
        self.target = target
        self.speed = speed
        self.armorPenetration = armorPenetration
        
        projectileNode = SKShapeNode(circleOfRadius: 4)
        projectileNode.fillColor = .yellow
        projectileNode.strokeColor = .orange
        projectileNode.lineWidth = 1
        
        super.init()
        
        position = startPosition
        zPosition = GameConstants.ZPosition.projectile.rawValue
        addChild(projectileNode)
        
        // Start movement
        moveToTarget()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateVisual() {
        projectileNode.removeAllChildren()
        
        switch visualType {
        case .bullet:
            projectileNode.fillColor = .yellow
            projectileNode.strokeColor = .orange
            projectileNode.path = CGPath(ellipseIn: CGRect(x: -4, y: -2, width: 8, height: 4), transform: nil)
            
        case .cannonBall:
            projectileNode.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
            projectileNode.strokeColor = .black
            projectileNode.lineWidth = 2
            projectileNode.path = CGPath(ellipseIn: CGRect(x: -6, y: -6, width: 12, height: 12), transform: nil)
            
            // Add shine
            let shine = SKShapeNode(circleOfRadius: 2)
            shine.fillColor = SKColor.white.withAlphaComponent(0.5)
            shine.strokeColor = .clear
            shine.position = CGPoint(x: -2, y: 2)
            projectileNode.addChild(shine)
            
        case .energy:
            projectileNode.fillColor = .cyan
            projectileNode.strokeColor = .white
            projectileNode.glowWidth = 3
            
            // Pulsing
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            projectileNode.run(SKAction.repeatForever(pulse))
        }
    }
    
    private func moveToTarget() {
        guard let target = target else {
            removeFromParent()
            return
        }
        
        // Calculate initial direction
        let direction = CGVector(
            dx: target.position.x - position.x,
            dy: target.position.y - position.y
        ).normalized()
        
        // Rotate to face direction
        zRotation = atan2(direction.dy, direction.dx)
        
        // Create update action
        let updateAction = SKAction.customAction(withDuration: 10.0) { [weak self] _, _ in
            self?.updatePosition()
        }
        
        run(updateAction, withKey: "move")
    }
    
    private func updatePosition() {
        guard !hasHit else { return }
        
        guard let target = target, target.isAlive else {
            // Target lost - continue in current direction briefly then remove
            let continueAction = SKAction.sequence([
                SKAction.move(by: CGVector(dx: cos(zRotation) * 50, dy: sin(zRotation) * 50), duration: 0.2),
                SKAction.fadeOut(withDuration: 0.1),
                SKAction.removeFromParent()
            ])
            run(continueAction)
            return
        }
        
        // Home in on target
        let direction = CGVector(
            dx: target.position.x - position.x,
            dy: target.position.y - position.y
        )
        
        let distance = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
        
        // Check for hit
        if distance < 15 {
            hit()
            return
        }
        
        // Move toward target
        let normalizedDirection = CGVector(
            dx: direction.dx / distance,
            dy: direction.dy / distance
        )
        
        let moveSpeed = speed / 60.0  // Assuming 60 FPS
        position = CGPoint(
            x: position.x + normalizedDirection.dx * moveSpeed,
            y: position.y + normalizedDirection.dy * moveSpeed
        )
        
        // Update rotation
        zRotation = atan2(normalizedDirection.dy, normalizedDirection.dx)
        
        // Trail effect
        createTrail()
    }
    
    private func createTrail() {
        let trail = SKShapeNode(circleOfRadius: 2)
        trail.fillColor = projectileNode.fillColor.withAlphaComponent(0.5)
        trail.strokeColor = .clear
        trail.position = position
        trail.zPosition = zPosition - 1
        parent?.addChild(trail)
        
        let fade = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ])
        trail.run(fade)
    }
    
    private func hit() {
        guard !hasHit else { return }
        hasHit = true
        
        removeAction(forKey: "move")
        
        // Apply damage
        target?.takeDamage(damage, armorPenetration: armorPenetration)
        
        // Impact effect
        let impact = SKShapeNode(circleOfRadius: 8)
        impact.fillColor = projectileNode.fillColor
        impact.strokeColor = .white
        impact.position = position
        impact.zPosition = GameConstants.ZPosition.effects.rawValue
        parent?.addChild(impact)
        
        let impactAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.1, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ])
        impact.run(impactAnimation)
        
        removeFromParent()
    }
}
