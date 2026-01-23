import SpriteKit

/// Manages the Block power-up state
/// Places a temporary obstacle that blocks enemy movement for 7 seconds
final class BlockManager {
    
    static let shared = BlockManager()
    
    // Configuration
    let blockDuration: TimeInterval = 7.0      // How long block lasts
    let blockCooldown: TimeInterval = 25.0     // Cooldown between uses
    
    // State
    private(set) var isActive: Bool = false
    private(set) var activationTime: TimeInterval = 0
    private(set) var lastUsedTime: TimeInterval = -1000  // Start ready
    private(set) var blockPosition: GridPosition?
    
    // Callback when block expires (to unblock the cell)
    var onBlockExpired: ((GridPosition) -> Void)?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if block can be activated
    func canActivate(currentTime: TimeInterval) -> Bool {
        if isActive { return false }
        let timeSinceLastUse = currentTime - lastUsedTime
        return timeSinceLastUse >= blockCooldown
    }
    
    /// Get cooldown progress (0.0 = just used, 1.0 = ready)
    func getCooldownProgress(currentTime: TimeInterval) -> CGFloat {
        if isActive { return 0.0 }
        let timeSinceLastUse = currentTime - lastUsedTime
        return CGFloat(min(1.0, timeSinceLastUse / blockCooldown))
    }
    
    /// Get remaining active time (0 if not active)
    func getRemainingActiveTime(currentTime: TimeInterval) -> TimeInterval {
        guard isActive else { return 0 }
        let elapsed = currentTime - activationTime
        return max(0, blockDuration - elapsed)
    }
    
    /// Activate block effect at grid position
    func activate(currentTime: TimeInterval, gridPosition: GridPosition) {
        guard canActivate(currentTime: currentTime) else { return }
        isActive = true
        activationTime = currentTime
        blockPosition = gridPosition
    }
    
    /// Update state - called each frame
    func update(currentTime: TimeInterval) {
        guard isActive else { return }
        
        let elapsed = currentTime - activationTime
        if elapsed >= blockDuration {
            // Block expired
            if let pos = blockPosition {
                onBlockExpired?(pos)
            }
            isActive = false
            lastUsedTime = currentTime
            blockPosition = nil
        }
    }
    
    /// Get the current block position if active
    func getBlockPosition() -> GridPosition? {
        return isActive ? blockPosition : nil
    }
    
    /// Reset state (for new game)
    func reset() {
        isActive = false
        lastUsedTime = -1000
        blockPosition = nil
    }
}
