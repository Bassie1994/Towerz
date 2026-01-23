import SpriteKit

/// Delegate for wave events
protocol WaveManagerDelegate: AnyObject {
    func waveDidStart(waveNumber: Int)
    func waveDidComplete(waveNumber: Int)
    func allWavesCompleted()
    func spawnEnemy(type: EnemyType, level: Int)
}

/// Manages wave spawning and progression
final class WaveManager {
    
    // MARK: - Properties
    
    weak var delegate: WaveManagerDelegate?
    
    private(set) var currentWave: Int = 0
    private(set) var totalWaves: Int = 0
    private(set) var isWaveActive: Bool = false
    private(set) var remainingEnemiesInWave: Int = 0
    
    private var waveConfigs: [WaveConfig] = []
    private var spawnQueue: [(type: EnemyType, level: Int, delay: TimeInterval)] = []
    private var lastSpawnTime: TimeInterval = 0
    private var waveStartTime: TimeInterval = 0
    
    // Track alive enemies for wave completion
    var aliveEnemyCount: Int = 0
    
    // MARK: - Initialization
    
    init() {
        loadWaveConfigs()
    }
    
    private func loadWaveConfigs() {
        // Use generated 50 waves
        waveConfigs = WaveConfig.defaultWaves
        totalWaves = waveConfigs.count
    }
    
    // MARK: - Wave Control
    
    /// Set current wave (for loading saves)
    func setWave(_ wave: Int) {
        currentWave = max(0, min(wave, totalWaves))
        isWaveActive = false
        spawnQueue.removeAll()
        aliveEnemyCount = 0
    }
    
    func startNextWave(currentTime: TimeInterval) {
        guard !isWaveActive else { return }
        guard currentWave < totalWaves else {
            delegate?.allWavesCompleted()
            return
        }
        
        currentWave += 1
        isWaveActive = true
        waveStartTime = currentTime
        lastSpawnTime = currentTime
        
        // Build spawn queue from wave config
        let config = waveConfigs[currentWave - 1]
        buildSpawnQueue(from: config)
        
        remainingEnemiesInWave = spawnQueue.count
        aliveEnemyCount = 0
        
        delegate?.waveDidStart(waveNumber: currentWave)
    }
    
    private func buildSpawnQueue(from config: WaveConfig) {
        spawnQueue.removeAll()
        
        var currentDelay: TimeInterval = 0
        
        for group in config.groups {
            for i in 0..<group.count {
                spawnQueue.append((
                    type: group.type,
                    level: group.level,
                    delay: currentDelay + Double(i) * group.spawnInterval
                ))
            }
            currentDelay += Double(group.count) * group.spawnInterval + group.groupDelay
        }
        
        // Sort by delay
        spawnQueue.sort { $0.delay < $1.delay }
    }
    
    // MARK: - Update
    
    func update(currentTime: TimeInterval) {
        guard isWaveActive else { return }
        
        let timeSinceWaveStart = currentTime - waveStartTime
        
        // Safety: don't spawn if time is invalid
        guard timeSinceWaveStart >= 0 && timeSinceWaveStart < 10000 else { return }
        
        // Spawn enemies from queue - LIMIT to max 3 per frame for performance
        var spawnedThisFrame = 0
        let maxSpawnsPerFrame = 3
        
        while let next = spawnQueue.first, 
              next.delay <= timeSinceWaveStart,
              spawnedThisFrame < maxSpawnsPerFrame {
            spawnQueue.removeFirst()
            delegate?.spawnEnemy(type: next.type, level: next.level)
            aliveEnemyCount += 1
            spawnedThisFrame += 1
        }
        
        // Check if wave is complete (all spawned and all dead)
        if spawnQueue.isEmpty && aliveEnemyCount <= 0 {
            completeWave()
        }
    }
    
    func enemyKilled() {
        aliveEnemyCount -= 1
    }
    
    func enemyReachedExit() {
        aliveEnemyCount -= 1
    }
    
    private func completeWave() {
        isWaveActive = false
        delegate?.waveDidComplete(waveNumber: currentWave)
        
        if currentWave >= totalWaves {
            delegate?.allWavesCompleted()
        }
    }
    
    // MARK: - Info
    
    func getWaveInfo() -> String {
        if isWaveActive {
            return "Wave \(currentWave)/\(totalWaves) - \(aliveEnemyCount) enemies"
        } else if currentWave >= totalWaves {
            return "All waves complete!"
        } else {
            return "Wave \(currentWave)/\(totalWaves) - Ready"
        }
    }
    
    func canStartNextWave() -> Bool {
        return !isWaveActive && currentWave < totalWaves
    }
}

// MARK: - Wave Configuration

struct WaveConfig: Codable {
    let waveNumber: Int
    let groups: [EnemyGroup]
    
    struct EnemyGroup: Codable {
        let type: EnemyType
        let count: Int
        let level: Int
        let spawnInterval: TimeInterval
        let groupDelay: TimeInterval
        
        init(type: EnemyType, count: Int, level: Int = 1, spawnInterval: TimeInterval = 1.0, groupDelay: TimeInterval = 2.0) {
            self.type = type
            self.count = count
            self.level = level
            self.spawnInterval = spawnInterval
            self.groupDelay = groupDelay
        }
    }
    
    // MARK: - Wave Generation Constants
    
    /// Enemy distribution ratios for different wave phases
    private enum EnemyDistribution {
        /// Waves 1-2: Infantry only
        static let earlyInfantry: Double = 1.0
        
        /// Waves 3-5: Infantry + Flying
        static let midEarlyInfantry: Double = 0.7
        static let midEarlyFlying: Double = 0.3
        
        /// Waves 6-9: Infantry + Flying + Cavalry
        static let midInfantry: Double = 0.5
        static let midFlying: Double = 0.3
        static let midCavalry: Double = 0.2
        
        /// Late game: Mixed composition (default)
        static let lateInfantry: Double = 0.4
        static let lateFlying: Double = 0.3
        static let lateCavalry: Double = 0.3
    }
    
    /// Base HP values for enemy types (for boss HP calculation)
    private enum EnemyBaseHP {
        static let infantry: CGFloat = 200
        static let flying: CGFloat = 80
        static let cavalry: CGFloat = 600
        
        static let infantryScaling: CGFloat = 0.3
        static let flyingScaling: CGFloat = 0.2
        static let cavalryScaling: CGFloat = 0.35
    }
    
    // MARK: - Wave Generation
    
    /// Generate 50 waves with scaling difficulty + boss every 5 waves
    static var defaultWaves: [WaveConfig] {
        return (1...50).map { generateWave(number: $0) }
    }
    
    /// Get wave stats (enemy count and level) for a given wave number
    private static func getWaveStats(number: Int) -> (totalEnemies: Int, enemyLevel: Int) {
        let baseCount: Double
        if number <= 10 {
            baseCount = 8.0 * pow(1.5, Double(number - 1))
        } else if number <= 30 {
            let wave10Base = 8.0 * pow(1.5, 9.0)
            baseCount = wave10Base * pow(1.15, Double(number - 10))
        } else {
            let wave10Base = 8.0 * pow(1.5, 9.0)
            let wave30Base = wave10Base * pow(1.15, 20.0)
            baseCount = wave30Base * pow(1.10, Double(number - 30))
        }
        
        // Cap max enemies per wave for performance
        let totalEnemies = min(Int(baseCount), 100)
        let enemyLevel = max(1, (number - 1) / 5 + 1)
        
        return (totalEnemies, enemyLevel)
    }
    
    /// Get enemy distribution ratios for a given wave number
    private static func getEnemyDistribution(waveNumber: Int) -> (infantry: Double, flying: Double, cavalry: Double) {
        if waveNumber < 3 {
            return (EnemyDistribution.earlyInfantry, 0.0, 0.0)
        } else if waveNumber < 6 {
            return (EnemyDistribution.midEarlyInfantry, EnemyDistribution.midEarlyFlying, 0.0)
        } else if waveNumber < 10 {
            return (EnemyDistribution.midInfantry, EnemyDistribution.midFlying, EnemyDistribution.midCavalry)
        } else {
            return (EnemyDistribution.lateInfantry, EnemyDistribution.lateFlying, EnemyDistribution.lateCavalry)
        }
    }
    
    /// Calculate total HP of a wave (for boss HP calculation)
    private static func calculateWaveHP(number: Int) -> CGFloat {
        let (totalEnemies, enemyLevel) = getWaveStats(number: number)
        let distribution = getEnemyDistribution(waveNumber: number)
        
        let infantryCount = Int(Double(totalEnemies) * distribution.infantry)
        let flyingCount = Int(Double(totalEnemies) * distribution.flying)
        let cavalryCount = totalEnemies - infantryCount - flyingCount
        
        let levelMultiplier = CGFloat(enemyLevel - 1)
        
        var totalHP: CGFloat = 0
        totalHP += CGFloat(infantryCount) * EnemyBaseHP.infantry * (1.0 + levelMultiplier * EnemyBaseHP.infantryScaling)
        totalHP += CGFloat(flyingCount) * EnemyBaseHP.flying * (1.0 + levelMultiplier * EnemyBaseHP.flyingScaling)
        totalHP += CGFloat(cavalryCount) * EnemyBaseHP.cavalry * (1.0 + levelMultiplier * EnemyBaseHP.cavalryScaling)
        
        return totalHP
    }
    
    private static func generateWave(number: Int) -> WaveConfig {
        // Check if this is a boss wave (every 5th wave: 5, 10, 15, etc.)
        if number % 5 == 0 && number > 0 {
            return generateBossWave(number: number)
        }
        
        // Base enemy count that scales
        let (totalEnemies, enemyLevel) = getWaveStats(number: number)
        
        // Spawn interval gets faster as waves progress (but not too fast)
        let baseInterval = max(0.3, 1.0 - Double(number) * 0.015)
        
        // Distribute enemies among types based on wave number
        var groups: [WaveConfig.EnemyGroup] = []
        
        if number < 3 {
            // Early waves: infantry only
            groups.append(WaveConfig.EnemyGroup(
                type: .infantry,
                count: totalEnemies,
                level: enemyLevel,
                spawnInterval: baseInterval
            ))
        } else if number < 6 {
            // Waves 3-5: introduce flying
            let infantryCount = Int(Double(totalEnemies) * 0.7)
            let flyingCount = totalEnemies - infantryCount
            
            groups.append(WaveConfig.EnemyGroup(
                type: .infantry,
                count: infantryCount,
                level: enemyLevel,
                spawnInterval: baseInterval
            ))
            groups.append(WaveConfig.EnemyGroup(
                type: .flying,
                count: flyingCount,
                level: max(1, enemyLevel - 1),
                spawnInterval: baseInterval * 1.5,
                groupDelay: 2.0
            ))
        } else if number < 10 {
            // Waves 6-9: introduce cavalry
            let infantryCount = Int(Double(totalEnemies) * 0.5)
            let flyingCount = Int(Double(totalEnemies) * 0.3)
            let cavalryCount = totalEnemies - infantryCount - flyingCount
            
            groups.append(WaveConfig.EnemyGroup(
                type: .infantry,
                count: infantryCount,
                level: enemyLevel,
                spawnInterval: baseInterval
            ))
            groups.append(WaveConfig.EnemyGroup(
                type: .cavalry,
                count: cavalryCount,
                level: max(1, enemyLevel - 1),
                spawnInterval: baseInterval * 2.0,
                groupDelay: 2.0
            ))
            groups.append(WaveConfig.EnemyGroup(
                type: .flying,
                count: flyingCount,
                level: enemyLevel,
                spawnInterval: baseInterval * 1.2,
                groupDelay: 1.5
            ))
        } else {
            // Waves 10+: full mixed with varying compositions
            let waveType = number % 5
            
            switch waveType {
            case 0: // Boss wave - heavy cavalry
                let cavalryCount = Int(Double(totalEnemies) * 0.5)
                let infantryCount = Int(Double(totalEnemies) * 0.3)
                let flyingCount = totalEnemies - cavalryCount - infantryCount
                
                groups.append(WaveConfig.EnemyGroup(
                    type: .cavalry,
                    count: cavalryCount,
                    level: enemyLevel + 1,
                    spawnInterval: baseInterval * 1.5
                ))
                groups.append(WaveConfig.EnemyGroup(
                    type: .infantry,
                    count: infantryCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval,
                    groupDelay: 2.0
                ))
                groups.append(WaveConfig.EnemyGroup(
                    type: .flying,
                    count: flyingCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 1.2,
                    groupDelay: 1.5
                ))
                
            case 1: // Swarm wave - lots of infantry
                let infantryCount = Int(Double(totalEnemies) * 0.8)
                let flyingCount = totalEnemies - infantryCount
                
                groups.append(WaveConfig.EnemyGroup(
                    type: .infantry,
                    count: infantryCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 0.7
                ))
                groups.append(WaveConfig.EnemyGroup(
                    type: .flying,
                    count: flyingCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval,
                    groupDelay: 3.0
                ))
                
            case 2: // Air raid - heavy flying
                let flyingCount = Int(Double(totalEnemies) * 0.6)
                let infantryCount = totalEnemies - flyingCount
                
                groups.append(WaveConfig.EnemyGroup(
                    type: .flying,
                    count: flyingCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval
                ))
                groups.append(WaveConfig.EnemyGroup(
                    type: .infantry,
                    count: infantryCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval,
                    groupDelay: 2.0
                ))
                
            case 3: // Tank rush
                let cavalryCount = Int(Double(totalEnemies) * 0.4)
                let infantryCount = Int(Double(totalEnemies) * 0.4)
                let flyingCount = totalEnemies - cavalryCount - infantryCount
                
                groups.append(WaveConfig.EnemyGroup(
                    type: .cavalry,
                    count: cavalryCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 1.8
                ))
                groups.append(WaveConfig.EnemyGroup(
                    type: .infantry,
                    count: infantryCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval,
                    groupDelay: 1.5
                ))
                groups.append(WaveConfig.EnemyGroup(
                    type: .flying,
                    count: flyingCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 1.2,
                    groupDelay: 1.5
                ))
                
            default: // Balanced
                let infantryCount = Int(Double(totalEnemies) * 0.4)
                let flyingCount = Int(Double(totalEnemies) * 0.35)
                let cavalryCount = totalEnemies - infantryCount - flyingCount
                
                groups.append(WaveConfig.EnemyGroup(
                    type: .infantry,
                    count: infantryCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval
                ))
                groups.append(WaveConfig.EnemyGroup(
                    type: .flying,
                    count: flyingCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 1.1,
                    groupDelay: 1.5
                ))
                groups.append(WaveConfig.EnemyGroup(
                    type: .cavalry,
                    count: cavalryCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 2.0,
                    groupDelay: 2.0
                ))
            }
        }
        
        return WaveConfig(waveNumber: number, groups: groups)
    }
    
    /// Generate a boss wave - BOSS spawns FIRST, then escorts follow
    private static func generateBossWave(number: Int) -> WaveConfig {
        // Calculate HP from previous wave (wave 4 for boss 5, wave 9 for boss 10, etc.)
        let previousWave = number - 1
        let bossHP = calculateWaveHP(number: previousWave)
        
        // Boss level scales with wave number
        let bossLevel = max(1, number / 5)
        
        // Escort count scales with boss level
        let escortCount = 5 + bossLevel * 2
        
        var groups: [WaveConfig.EnemyGroup] = []
        
        // BOSS spawns FIRST - single massive enemy
        // Level encodes the boss HP in thousands (we'll decode in spawnEnemy)
        let encodedLevel = Int(bossHP / 1000) + 1000  // Add 1000 marker to identify as boss HP
        groups.append(WaveConfig.EnemyGroup(
            type: .boss,
            count: 1,
            level: encodedLevel,  // Encoded HP
            spawnInterval: 0,
            groupDelay: 0  // Spawns immediately
        ))
        
        // Escort infantry after boss
        groups.append(WaveConfig.EnemyGroup(
            type: .infantry,
            count: escortCount,
            level: bossLevel + 1,
            spawnInterval: 0.6,
            groupDelay: 2.0  // After boss starts moving
        ))
        
        // Cavalry escorts
        groups.append(WaveConfig.EnemyGroup(
            type: .cavalry,
            count: escortCount / 2,
            level: bossLevel,
            spawnInterval: 1.5,
            groupDelay: 4.0
        ))
        
        // Flying escorts
        groups.append(WaveConfig.EnemyGroup(
            type: .flying,
            count: escortCount / 2 + 1,
            level: bossLevel + 1,
            spawnInterval: 1.0,
            groupDelay: 3.0
        ))
        
        return WaveConfig(waveNumber: number, groups: groups)
    }
}
