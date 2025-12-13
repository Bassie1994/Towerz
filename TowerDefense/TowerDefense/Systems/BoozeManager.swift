import Foundation

/// Manages the Booze power-up state
final class BoozeManager {
    
    static let shared = BoozeManager()
    
    // Configuration
    let boozeDuration: TimeInterval = 7.0      // How long booze lasts
    let boozeCooldown: TimeInterval = 30.0     // Cooldown between uses
    
    // State
    private(set) var isActive: Bool = false
    private(set) var activationTime: TimeInterval = 0
    private(set) var lastUsedTime: TimeInterval = -1000  // Start ready
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if booze can be activated
    func canActivate(currentTime: TimeInterval) -> Bool {
        if isActive { return false }
        let timeSinceLastUse = currentTime - lastUsedTime
        return timeSinceLastUse >= boozeCooldown
    }
    
    /// Get cooldown progress (0.0 = just used, 1.0 = ready)
    func getCooldownProgress(currentTime: TimeInterval) -> CGFloat {
        if isActive { return 0.0 }
        let timeSinceLastUse = currentTime - lastUsedTime
        return CGFloat(min(1.0, timeSinceLastUse / boozeCooldown))
    }
    
    /// Get remaining active time (0 if not active)
    func getRemainingActiveTime(currentTime: TimeInterval) -> TimeInterval {
        guard isActive else { return 0 }
        let elapsed = currentTime - activationTime
        return max(0, boozeDuration - elapsed)
    }
    
    /// Activate booze effect
    func activate(currentTime: TimeInterval) {
        guard canActivate(currentTime: currentTime) else { return }
        isActive = true
        activationTime = currentTime
    }
    
    /// Update state - called each frame
    func update(currentTime: TimeInterval) {
        if isActive {
            let elapsed = currentTime - activationTime
            if elapsed >= boozeDuration {
                isActive = false
                lastUsedTime = currentTime
            }
        }
    }
    
    /// Reset state (for new game)
    func reset() {
        isActive = false
        lastUsedTime = -1000
    }
}
