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
    private(set) var endlessModeEnabled: Bool = false
    private(set) var endlessCycle: Int = 0
    
    private var waveConfigs: [WaveConfig] = []
    private var spawnQueue: [(type: EnemyType, level: Int, delay: TimeInterval)] = []
    private var lastSpawnTime: TimeInterval = 0
    private var waveStartTime: TimeInterval = 0
    
    // Track alive enemies for wave completion
    var aliveEnemyCount: Int = 0

    var endlessDifficultyMultiplier: Double {
        return pow(2.0, Double(endlessCycle))
    }
    
    // MARK: - Initialization
    
    init() {
        loadWaveConfigs()
    }
    
    private func loadWaveConfigs() {
        // 50 curated level-waves with explicit special wave rules
        waveConfigs = WaveConfig.defaultWaves
        totalWaves = waveConfigs.count
    }
    
    // MARK: - Wave Control

    func setEndlessMode(_ enabled: Bool) {
        endlessModeEnabled = enabled
        endlessCycle = 0
    }

    func isEndlessCycleBoundary() -> Bool {
        return endlessModeEnabled && !isWaveActive && currentWave >= totalWaves
    }

    func advanceEndlessCycle() {
        guard endlessModeEnabled else { return }
        endlessCycle += 1
        currentWave = 0
        isWaveActive = false
        remainingEnemiesInWave = 0
        aliveEnemyCount = 0
        spawnQueue.removeAll()
    }
    
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
            if !endlessModeEnabled {
                delegate?.allWavesCompleted()
            }
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
            let adjustedCount = adjustedEnemyCount(for: group, waveNumber: config.waveNumber)
            let adjustedLevel = adjustedEnemyLevel(for: group.type, baseLevel: group.level)
            for i in 0..<adjustedCount {
                spawnQueue.append((
                    type: group.type,
                    level: adjustedLevel,
                    delay: currentDelay + Double(i) * group.spawnInterval
                ))
            }
            currentDelay += Double(adjustedCount) * group.spawnInterval + group.groupDelay
        }
        
        // Sort by delay
        spawnQueue.sort { $0.delay < $1.delay }
    }

    private func adjustedEnemyCount(for group: WaveConfig.EnemyGroup, waveNumber: Int) -> Int {
        guard group.count > 0 else { return 0 }

        // Bosses explicitly ignore count multipliers.
        if group.type == .boss {
            let capped = WaveConfig.isSpecialWave(number: waveNumber) ? min(group.count, WaveConfig.specialWaveMaxEnemyCount) : group.count
            return max(1, capped)
        }

        var scaled = Double(group.count) * GameConstants.Balance.enemyCountMultiplier
        if endlessModeEnabled {
            scaled *= endlessDifficultyMultiplier
        }

        var adjusted = Int(scaled.rounded(.toNearestOrAwayFromZero))
        adjusted = max(1, adjusted)

        // Special waves should never exceed 25 spawned units.
        if WaveConfig.isSpecialWave(number: waveNumber) {
            adjusted = min(adjusted, WaveConfig.specialWaveMaxEnemyCount)
        }

        return adjusted
    }

    private func adjustedEnemyLevel(for type: EnemyType, baseLevel: Int) -> Int {
        guard endlessModeEnabled else { return max(1, baseLevel) }
        if type == .boss {
            return max(1, baseLevel)
        }

        // Every endless cycle adds two effective levels on top.
        return max(1, baseLevel + endlessCycle * 2)
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
        
        if currentWave >= totalWaves && !endlessModeEnabled {
            delegate?.allWavesCompleted()
        }
    }
    
    // MARK: - Info
    
    func getWaveInfo() -> String {
        if isWaveActive {
            return "Level \(currentWave)/\(totalWaves) - \(aliveEnemyCount) enemies"
        } else if currentWave >= totalWaves && !endlessModeEnabled {
            return "All levels complete!"
        } else {
            return "Level \(currentWave)/\(totalWaves) - Ready"
        }
    }
    
    func canStartNextWave() -> Bool {
        return !isWaveActive && (endlessModeEnabled || currentWave < totalWaves)
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
    
    static let totalLevels: Int = 50
    static let specialWaveMaxEnemyCount: Int = 25

    // MARK: - Wave Generation Constants

    /// Base HP values used to estimate special boss level health.
    private enum EnemyBaseHP {
        static let infantry: CGFloat = 200
        static let flying: CGFloat = 80
        static let cavalry: CGFloat = 600
        static let shielded: CGFloat = 260
        static let support: CGFloat = 180
        
        static let infantryScaling: CGFloat = 0.3
        static let flyingScaling: CGFloat = 0.2
        static let cavalryScaling: CGFloat = 0.35
        static let shieldedScaling: CGFloat = 0.28
        static let supportScaling: CGFloat = 0.22
    }
    
    // MARK: - Wave Generation
    
    /// Generate exactly 50 level-waves.
    static var defaultWaves: [WaveConfig] {
        return (1...totalLevels).map { generateWave(number: $0) }
    }

    static func isFlyingSpecialWave(number: Int) -> Bool {
        return number % 10 == 7
    }

    static func isShieldedSpecialWave(number: Int) -> Bool {
        return number % 10 == 8
    }

    static func isBossSpecialWave(number: Int) -> Bool {
        return number == 10 || number == 20 || number == 30 || number == 50
    }

    static func isSpecialWave(number: Int) -> Bool {
        return isFlyingSpecialWave(number: number) ||
            isShieldedSpecialWave(number: number) ||
            isBossSpecialWave(number: number)
    }

    /// Slowly increasing difficulty multiplier across all 50 levels.
    private static func difficultyMultiplier(for number: Int) -> Double {
        let linear = 1.0 + Double(max(0, number - 1)) * 0.045
        let lateGameBoost = number > 25 ? (1.0 + Double(number - 25) * 0.02) : 1.0
        return linear * lateGameBoost
    }

    /// Get level stats (enemy count and enemy level).
    private static func getWaveStats(number: Int) -> (totalEnemies: Int, enemyLevel: Int) {
        let difficulty = difficultyMultiplier(for: number)
        let baseEnemies = 14 + number * 2
        let scaledCount = Int((Double(baseEnemies) * difficulty).rounded(.toNearestOrAwayFromZero))
        let totalEnemies = min(scaledCount, 180)
        let enemyLevel = max(1, Int((Double(number) * 0.28 + difficulty).rounded(.down)))
        return (totalEnemies, enemyLevel)
    }

    private static func calculateWaveHP(number: Int) -> CGFloat {
        let (totalEnemies, enemyLevel) = getWaveStats(number: number)
        let infantryCount = Int(Double(totalEnemies) * 0.42)
        let flyingCount = Int(Double(totalEnemies) * 0.2)
        let cavalryCount = Int(Double(totalEnemies) * 0.2)
        let shieldedCount = Int(Double(totalEnemies) * 0.1)
        let supportCount = max(0, totalEnemies - infantryCount - flyingCount - cavalryCount - shieldedCount)
        let levelMultiplier = CGFloat(enemyLevel - 1)

        var totalHP: CGFloat = 0
        totalHP += CGFloat(infantryCount) * EnemyBaseHP.infantry * (1.0 + levelMultiplier * EnemyBaseHP.infantryScaling)
        totalHP += CGFloat(flyingCount) * EnemyBaseHP.flying * (1.0 + levelMultiplier * EnemyBaseHP.flyingScaling)
        totalHP += CGFloat(cavalryCount) * EnemyBaseHP.cavalry * (1.0 + levelMultiplier * EnemyBaseHP.cavalryScaling)
        totalHP += CGFloat(shieldedCount) * EnemyBaseHP.shielded * (1.0 + levelMultiplier * EnemyBaseHP.shieldedScaling)
        totalHP += CGFloat(supportCount) * EnemyBaseHP.support * (1.0 + levelMultiplier * EnemyBaseHP.supportScaling)

        return totalHP
    }

    private static func generateWave(number: Int) -> WaveConfig {
        if isBossSpecialWave(number: number) {
            return generateBossSpecialWave(number: number)
        }

        if isFlyingSpecialWave(number: number) {
            return generateFlyingSpecialWave(number: number)
        }

        if isShieldedSpecialWave(number: number) {
            return generateShieldedSpecialWave(number: number)
        }

        let (totalEnemies, enemyLevel) = getWaveStats(number: number)
        let baseInterval = max(0.22, 0.95 - Double(number) * 0.012)

        var groups: [EnemyGroup] = []

        if number < 4 {
            groups.append(EnemyGroup(
                type: .infantry,
                count: totalEnemies,
                level: enemyLevel,
                spawnInterval: baseInterval
            ))
        } else if number < 8 {
            let infantryCount = Int(Double(totalEnemies) * 0.72)
            let flyingCount = totalEnemies - infantryCount

            groups.append(EnemyGroup(
                type: .infantry,
                count: infantryCount,
                level: enemyLevel,
                spawnInterval: baseInterval
            ))
            groups.append(EnemyGroup(
                type: .flying,
                count: flyingCount,
                level: max(1, enemyLevel),
                spawnInterval: baseInterval * 1.15,
                groupDelay: 1.5
            ))
        } else if number < 12 {
            let infantryCount = Int(Double(totalEnemies) * 0.5)
            let flyingCount = Int(Double(totalEnemies) * 0.25)
            let cavalryCount = totalEnemies - infantryCount - flyingCount

            groups.append(EnemyGroup(
                type: .infantry,
                count: infantryCount,
                level: enemyLevel,
                spawnInterval: baseInterval
            ))
            groups.append(EnemyGroup(
                type: .cavalry,
                count: cavalryCount,
                level: max(1, enemyLevel),
                spawnInterval: baseInterval * 1.5,
                groupDelay: 1.3
            ))
            groups.append(EnemyGroup(
                type: .flying,
                count: flyingCount,
                level: enemyLevel,
                spawnInterval: baseInterval * 1.2,
                groupDelay: 1.1
            ))
        } else {
            let supportCount = max(1, Int(Double(totalEnemies) * 0.10))
            let shieldedCount = max(1, Int(Double(totalEnemies) * 0.12))
            let remaining = max(0, totalEnemies - supportCount - shieldedCount)

            switch number % 4 {
            case 0: // balanced mixed
                let infantryCount = Int(Double(remaining) * 0.44)
                let flyingCount = Int(Double(remaining) * 0.30)
                let cavalryCount = remaining - infantryCount - flyingCount

                groups.append(EnemyGroup(
                    type: .infantry,
                    count: infantryCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval
                ))
                groups.append(EnemyGroup(
                    type: .support,
                    count: supportCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 1.1,
                    groupDelay: 1.0
                ))
                groups.append(EnemyGroup(
                    type: .flying,
                    count: flyingCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 1.15,
                    groupDelay: 1.2
                ))
                groups.append(EnemyGroup(
                    type: .shielded,
                    count: shieldedCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 1.35,
                    groupDelay: 1.2
                ))
                groups.append(EnemyGroup(
                    type: .cavalry,
                    count: cavalryCount,
                    level: enemyLevel,
                    spawnInterval: baseInterval * 1.55,
                    groupDelay: 1.4
                ))
            case 1: // swarm pressure
                let infantryCount = Int(Double(remaining) * 0.62)
                let cavalryCount = Int(Double(remaining) * 0.2)
                let flyingCount = remaining - infantryCount - cavalryCount

                groups.append(EnemyGroup(type: .infantry, count: infantryCount, level: enemyLevel, spawnInterval: baseInterval * 0.78))
                groups.append(EnemyGroup(type: .shielded, count: shieldedCount, level: enemyLevel, spawnInterval: baseInterval * 1.25, groupDelay: 0.8))
                groups.append(EnemyGroup(type: .support, count: supportCount, level: max(1, enemyLevel - 1), spawnInterval: baseInterval * 1.05, groupDelay: 0.7))
                groups.append(EnemyGroup(type: .cavalry, count: cavalryCount, level: enemyLevel, spawnInterval: baseInterval * 1.6, groupDelay: 1.0))
                groups.append(EnemyGroup(type: .flying, count: flyingCount, level: enemyLevel, spawnInterval: baseInterval * 1.1, groupDelay: 1.2))
            case 2: // air-heavy pressure
                let flyingCount = Int(Double(remaining) * 0.56)
                let infantryCount = Int(Double(remaining) * 0.24)
                let cavalryCount = remaining - flyingCount - infantryCount

                groups.append(EnemyGroup(type: .flying, count: flyingCount, level: enemyLevel, spawnInterval: baseInterval))
                groups.append(EnemyGroup(type: .support, count: supportCount, level: enemyLevel, spawnInterval: baseInterval * 1.1, groupDelay: 0.9))
                groups.append(EnemyGroup(type: .infantry, count: infantryCount, level: enemyLevel, spawnInterval: baseInterval * 0.95, groupDelay: 1.1))
                groups.append(EnemyGroup(type: .shielded, count: shieldedCount, level: enemyLevel, spawnInterval: baseInterval * 1.25, groupDelay: 0.9))
                groups.append(EnemyGroup(type: .cavalry, count: cavalryCount, level: enemyLevel, spawnInterval: baseInterval * 1.6, groupDelay: 1.2))
            default: // armored grind
                let cavalryCount = Int(Double(remaining) * 0.42)
                let infantryCount = Int(Double(remaining) * 0.36)
                let flyingCount = remaining - cavalryCount - infantryCount

                groups.append(EnemyGroup(type: .cavalry, count: cavalryCount, level: enemyLevel + 1, spawnInterval: baseInterval * 1.6))
                groups.append(EnemyGroup(type: .shielded, count: shieldedCount, level: enemyLevel + 1, spawnInterval: baseInterval * 1.35, groupDelay: 0.9))
                groups.append(EnemyGroup(type: .infantry, count: infantryCount, level: enemyLevel, spawnInterval: baseInterval, groupDelay: 1.0))
                groups.append(EnemyGroup(type: .support, count: supportCount, level: max(1, enemyLevel - 1), spawnInterval: baseInterval * 1.1, groupDelay: 0.8))
                groups.append(EnemyGroup(type: .flying, count: flyingCount, level: enemyLevel, spawnInterval: baseInterval * 1.2, groupDelay: 1.0))
            }
        }

        return WaveConfig(waveNumber: number, groups: groups)
    }

    /// Special wave: flying only (7, 17, 27, 37, 47).
    private static func generateFlyingSpecialWave(number: Int) -> WaveConfig {
        let (totalEnemies, enemyLevel) = getWaveStats(number: number)
        let capped = min(totalEnemies, specialWaveMaxEnemyCount)
        let interval = max(0.22, 0.7 - Double(number) * 0.006)
        return WaveConfig(
            waveNumber: number,
            groups: [
                EnemyGroup(
                    type: .flying,
                    count: capped,
                    level: enemyLevel + 1,
                    spawnInterval: interval,
                    groupDelay: 0
                )
            ]
        )
    }

    /// Special wave: shielded only (8, 18, 28, 38, 48).
    private static func generateShieldedSpecialWave(number: Int) -> WaveConfig {
        let (totalEnemies, enemyLevel) = getWaveStats(number: number)
        let capped = min(totalEnemies, specialWaveMaxEnemyCount)
        let interval = max(0.28, 0.85 - Double(number) * 0.007)
        return WaveConfig(
            waveNumber: number,
            groups: [
                EnemyGroup(
                    type: .shielded,
                    count: capped,
                    level: enemyLevel + 1,
                    spawnInterval: interval,
                    groupDelay: 0
                )
            ]
        )
    }

    /// Special wave: bosses only (10, 20, 30, 50).
    private static func generateBossSpecialWave(number: Int) -> WaveConfig {
        let previousWave = max(1, number - 1)
        let bossHP = max(6000, calculateWaveHP(number: previousWave) * 0.75)
        let bossCount = min(specialWaveMaxEnemyCount, max(1, number / 10))
        let encodedLevel = Int((bossHP / 1000).rounded(.toNearestOrAwayFromZero)) + 1000
        let interval = max(0.9, 1.8 - Double(number) * 0.01)

        let groups: [EnemyGroup] = [
            EnemyGroup(
                type: .boss,
                count: bossCount,
                level: encodedLevel,
                spawnInterval: interval,
                groupDelay: 0
            )
        ]

        return WaveConfig(waveNumber: number, groups: groups)
    }
}
