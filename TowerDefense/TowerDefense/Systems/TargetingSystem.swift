import SpriteKit

/// Centralized targeting system for towers
final class TargetingSystem {
    
    // Reference to all enemies (updated by GameScene)
    private weak var gameScene: GameScene?
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    /// Get all enemies within range of a tower (uses effective range including buffs)
    func getEnemiesInRange(of tower: Tower) -> [Enemy] {
        guard let scene = gameScene else { return [] }
        
        let enemies = scene.getAllEnemies()
        let effectiveRange = tower.getEffectiveRange()  // Includes buff multiplier
        
        return enemies.filter { enemy in
            guard enemy.isAlive else { return false }
            return tower.position.distance(to: enemy.position) <= effectiveRange
        }
    }
    
    /// Get the closest enemy to a position within range
    func getClosestEnemy(to position: CGPoint, range: CGFloat) -> Enemy? {
        guard let scene = gameScene else { return nil }
        
        let enemies = scene.getAllEnemies()
        
        return enemies
            .filter { $0.isAlive && position.distance(to: $0.position) <= range }
            .min { position.distance(to: $0.position) < position.distance(to: $1.position) }
    }
    
    /// Get enemies of a specific type within range
    func getEnemiesOfType(_ type: EnemyType, inRangeOf tower: Tower) -> [Enemy] {
        return getEnemiesInRange(of: tower).filter { $0.enemyType == type }
    }
    
    /// Get the enemy with the most progress (closest to exit)
    func getMostProgressedEnemy(inRangeOf tower: Tower) -> Enemy? {
        let enemies = getEnemiesInRange(of: tower)
        return enemies.max { $0.position.x < $1.position.x }
    }
    
    /// Get the enemy with the least health
    func getWeakestEnemy(inRangeOf tower: Tower) -> Enemy? {
        let enemies = getEnemiesInRange(of: tower)
        return enemies.min { $0.currentHealth < $1.currentHealth }
    }
    
    /// Get the enemy with the most health
    func getStrongestEnemy(inRangeOf tower: Tower) -> Enemy? {
        let enemies = getEnemiesInRange(of: tower)
        return enemies.max { $0.currentHealth < $1.currentHealth }
    }
    
    /// Get count of enemies in a radius around a point (for splash targeting)
    func getEnemyCount(around position: CGPoint, radius: CGFloat) -> Int {
        guard let scene = gameScene else { return 0 }
        
        return scene.getAllEnemies()
            .filter { $0.isAlive && position.distance(to: $0.position) <= radius }
            .count
    }
    
    /// Find the position that would hit the most enemies with splash damage
    func getBestSplashTarget(from tower: Tower, splashRadius: CGFloat) -> Enemy? {
        let enemies = getEnemiesInRange(of: tower)
        guard !enemies.isEmpty else { return nil }
        
        var bestTarget: Enemy?
        var bestScore = 0
        
        for enemy in enemies {
            let score = getEnemyCount(around: enemy.position, radius: splashRadius)
            if score > bestScore {
                bestScore = score
                bestTarget = enemy
            }
        }
        
        return bestTarget
    }
}
