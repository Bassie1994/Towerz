import SpriteKit

/// Manages the Lava power-up state
final class LavaManager {
    
    static let shared = LavaManager()
    
    // Configuration
    let lavaDuration: TimeInterval = 10.0     // How long lava lasts
    let lavaCooldown: TimeInterval = 45.0     // Cooldown between uses
    let lavaDamagePerSecond: CGFloat = 25.0   // Damage dealt per second
    let lavaRadius: CGFloat = 80.0            // Area of effect
    
    // State
    private(set) var isActive: Bool = false
    private(set) var activationTime: TimeInterval = 0
    private(set) var lastUsedTime: TimeInterval = -1000  // Start ready
    private(set) var lavaPosition: CGPoint = .zero
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if lava can be activated
    func canActivate(currentTime: TimeInterval) -> Bool {
        if isActive { return false }
        let timeSinceLastUse = currentTime - lastUsedTime
        return timeSinceLastUse >= lavaCooldown
    }
    
    /// Get cooldown progress (0.0 = just used, 1.0 = ready)
    func getCooldownProgress(currentTime: TimeInterval) -> CGFloat {
        if isActive { return 0.0 }
        let timeSinceLastUse = currentTime - lastUsedTime
        return CGFloat(min(1.0, timeSinceLastUse / lavaCooldown))
    }
    
    /// Get remaining active time (0 if not active)
    func getRemainingActiveTime(currentTime: TimeInterval) -> TimeInterval {
        guard isActive else { return 0 }
        let elapsed = currentTime - activationTime
        return max(0, lavaDuration - elapsed)
    }
    
    /// Activate lava effect at position
    func activate(currentTime: TimeInterval, position: CGPoint) {
        guard canActivate(currentTime: currentTime) else { return }
        isActive = true
        activationTime = currentTime
        lavaPosition = position
    }
    
    /// Update state and deal damage - called each frame
    func update(currentTime: TimeInterval, enemies: [Enemy]) {
        guard isActive else { return }
        
        let elapsed = currentTime - activationTime
        if elapsed >= lavaDuration {
            isActive = false
            lastUsedTime = currentTime
            return
        }
        
        // Deal damage to enemies in range (done per-frame in GameScene)
    }
    
    /// Check if enemy is in lava area
    func isInLavaArea(_ enemy: Enemy) -> Bool {
        guard isActive else { return false }
        let distance = enemy.position.distance(to: lavaPosition)
        return distance <= lavaRadius
    }
    
    /// Reset state (for new game)
    func reset() {
        isActive = false
        lastUsedTime = -1000
    }
}
