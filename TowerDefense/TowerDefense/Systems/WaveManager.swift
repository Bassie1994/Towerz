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
        // Try to load from JSON file
        if let url = Bundle.main.url(forResource: "WaveConfig", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let configs = try? JSONDecoder().decode([WaveConfig].self, from: data) {
            waveConfigs = configs
        } else {
            // Fallback to hardcoded waves
            waveConfigs = WaveConfig.defaultWaves
        }
        
        totalWaves = waveConfigs.count
    }
    
    // MARK: - Wave Control
    
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
        
        // Spawn enemies from queue
        while let next = spawnQueue.first, next.delay <= timeSinceWaveStart {
            spawnQueue.removeFirst()
            delegate?.spawnEnemy(type: next.type, level: next.level)
            aliveEnemyCount += 1
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
    
    // Default waves for fallback
    static var defaultWaves: [WaveConfig] {
        return [
            // Wave 1: Easy intro
            WaveConfig(waveNumber: 1, groups: [
                EnemyGroup(type: .infantry, count: 8, level: 1, spawnInterval: 1.2)
            ]),
            
            // Wave 2: More infantry
            WaveConfig(waveNumber: 2, groups: [
                EnemyGroup(type: .infantry, count: 10, level: 1, spawnInterval: 1.0),
                EnemyGroup(type: .infantry, count: 5, level: 1, spawnInterval: 0.8, groupDelay: 3.0)
            ]),
            
            // Wave 3: Introduce flying
            WaveConfig(waveNumber: 3, groups: [
                EnemyGroup(type: .infantry, count: 8, level: 1, spawnInterval: 1.0),
                EnemyGroup(type: .flying, count: 4, level: 1, spawnInterval: 1.5, groupDelay: 2.0)
            ]),
            
            // Wave 4: Introduce cavalry
            WaveConfig(waveNumber: 4, groups: [
                EnemyGroup(type: .infantry, count: 6, level: 2, spawnInterval: 0.9),
                EnemyGroup(type: .cavalry, count: 3, level: 1, spawnInterval: 2.0, groupDelay: 2.0),
                EnemyGroup(type: .flying, count: 4, level: 1, spawnInterval: 1.2, groupDelay: 1.0)
            ]),
            
            // Wave 5: Mixed assault
            WaveConfig(waveNumber: 5, groups: [
                EnemyGroup(type: .infantry, count: 12, level: 2, spawnInterval: 0.7),
                EnemyGroup(type: .cavalry, count: 4, level: 2, spawnInterval: 1.5, groupDelay: 2.0),
                EnemyGroup(type: .flying, count: 6, level: 2, spawnInterval: 1.0, groupDelay: 1.0),
                EnemyGroup(type: .infantry, count: 8, level: 2, spawnInterval: 0.6, groupDelay: 2.0)
            ]),
            
            // Wave 6: Cavalry rush
            WaveConfig(waveNumber: 6, groups: [
                EnemyGroup(type: .cavalry, count: 8, level: 2, spawnInterval: 1.0),
                EnemyGroup(type: .cavalry, count: 4, level: 3, spawnInterval: 1.2, groupDelay: 3.0)
            ]),
            
            // Wave 7: Air superiority
            WaveConfig(waveNumber: 7, groups: [
                EnemyGroup(type: .flying, count: 10, level: 2, spawnInterval: 0.8),
                EnemyGroup(type: .flying, count: 6, level: 3, spawnInterval: 0.7, groupDelay: 2.0),
                EnemyGroup(type: .infantry, count: 10, level: 2, spawnInterval: 0.6, groupDelay: 1.0)
            ]),
            
            // Wave 8: Full assault
            WaveConfig(waveNumber: 8, groups: [
                EnemyGroup(type: .infantry, count: 15, level: 3, spawnInterval: 0.5),
                EnemyGroup(type: .cavalry, count: 6, level: 3, spawnInterval: 1.0, groupDelay: 2.0),
                EnemyGroup(type: .flying, count: 8, level: 3, spawnInterval: 0.8, groupDelay: 1.0),
                EnemyGroup(type: .infantry, count: 10, level: 3, spawnInterval: 0.4, groupDelay: 2.0)
            ]),
            
            // Wave 9: Elite wave
            WaveConfig(waveNumber: 9, groups: [
                EnemyGroup(type: .cavalry, count: 10, level: 4, spawnInterval: 0.8),
                EnemyGroup(type: .flying, count: 10, level: 4, spawnInterval: 0.6, groupDelay: 1.0),
                EnemyGroup(type: .infantry, count: 20, level: 4, spawnInterval: 0.3, groupDelay: 2.0)
            ]),
            
            // Wave 10: Final boss wave
            WaveConfig(waveNumber: 10, groups: [
                EnemyGroup(type: .infantry, count: 25, level: 4, spawnInterval: 0.3),
                EnemyGroup(type: .cavalry, count: 12, level: 5, spawnInterval: 0.6, groupDelay: 1.0),
                EnemyGroup(type: .flying, count: 15, level: 5, spawnInterval: 0.5, groupDelay: 1.0),
                EnemyGroup(type: .cavalry, count: 5, level: 5, spawnInterval: 1.0, groupDelay: 2.0),
                EnemyGroup(type: .infantry, count: 15, level: 5, spawnInterval: 0.2, groupDelay: 1.0)
            ])
        ]
    }
}
