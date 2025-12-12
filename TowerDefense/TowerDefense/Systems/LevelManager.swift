import Foundation

/// Level configuration
struct LevelConfig: Codable {
    let levelNumber: Int
    let name: String
    let description: String
    let startingMoney: Int
    let startingLives: Int
    let waves: [WaveConfig]
    let isTutorial: Bool
    let tutorialSteps: [TutorialStep]?
    let unlockRequirement: Int  // Level number required to unlock (0 = always unlocked)
    
    struct TutorialStep: Codable {
        let message: String
        let highlightElement: String?  // UI element to highlight
        let waitForAction: String?     // Action to wait for before proceeding
        let delay: TimeInterval        // Delay before showing next step
    }
}

/// Manages level progression and unlocks
final class LevelManager {
    
    static let shared = LevelManager()
    
    private(set) var currentLevelIndex: Int = 0
    private(set) var levels: [LevelConfig] = []
    private(set) var completedLevels: Set<Int> = []
    
    // Current level state
    private(set) var currentLevel: LevelConfig?
    private(set) var currentWaveIndex: Int = 0
    
    private init() {
        loadLevels()
        loadProgress()
    }
    
    private func loadLevels() {
        levels = LevelConfig.allLevels
    }
    
    private func loadProgress() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.array(forKey: "completedLevels") as? [Int] {
            completedLevels = Set(data)
        }
    }
    
    private func saveProgress() {
        UserDefaults.standard.set(Array(completedLevels), forKey: "completedLevels")
    }
    
    // MARK: - Level Management
    
    func selectLevel(_ index: Int) -> Bool {
        guard index >= 0 && index < levels.count else { return false }
        
        let level = levels[index]
        
        // Check if unlocked
        if level.unlockRequirement > 0 && !completedLevels.contains(level.unlockRequirement) {
            return false
        }
        
        currentLevelIndex = index
        currentLevel = level
        currentWaveIndex = 0
        return true
    }
    
    func completeLevel(_ index: Int) {
        completedLevels.insert(index)
        saveProgress()
    }
    
    func isLevelUnlocked(_ index: Int) -> Bool {
        guard index >= 0 && index < levels.count else { return false }
        let level = levels[index]
        return level.unlockRequirement == 0 || completedLevels.contains(level.unlockRequirement)
    }
    
    func getNextWave() -> WaveConfig? {
        guard let level = currentLevel else { return nil }
        guard currentWaveIndex < level.waves.count else { return nil }
        
        let wave = level.waves[currentWaveIndex]
        currentWaveIndex += 1
        return wave
    }
    
    func getTotalWaves() -> Int {
        return currentLevel?.waves.count ?? 0
    }
    
    func resetProgress() {
        completedLevels.removeAll()
        saveProgress()
    }
}

// MARK: - Level Definitions

extension LevelConfig {
    
    static var allLevels: [LevelConfig] {
        return [
            tutorialLevel,
            level1,
            level2,
            level3,
            level4,
            level5,
            level6,
            level7,
            level8,
            level9,
            level10
        ]
    }
    
    // MARK: - Tutorial Level
    
    static var tutorialLevel: LevelConfig {
        LevelConfig(
            levelNumber: 0,
            name: "Training Ground",
            description: "Learn the basics of tower defense",
            startingMoney: 500,
            startingLives: 50,
            waves: generateTutorialWaves(),
            isTutorial: true,
            tutorialSteps: [
                TutorialStep(message: "Welcome! Enemies spawn on the LEFT and try to reach the RIGHT.", highlightElement: "spawnZone", waitForAction: nil, delay: 3.0),
                TutorialStep(message: "Tap a tower in the menu to select it.", highlightElement: "buildMenu", waitForAction: "selectTower", delay: 0),
                TutorialStep(message: "Tap on the field to place your tower.", highlightElement: "playField", waitForAction: "placeTower", delay: 0),
                TutorialStep(message: "Great! Towers block enemy paths. Try building a maze!", highlightElement: nil, waitForAction: nil, delay: 3.0),
                TutorialStep(message: "Tap 'Start Wave' when ready.", highlightElement: "startWaveButton", waitForAction: "startWave", delay: 0),
                TutorialStep(message: "FLYING enemies (cyan) ignore your maze! Use MachineGun or AntiAir towers.", highlightElement: nil, waitForAction: nil, delay: 5.0),
                TutorialStep(message: "CAVALRY (orange) are armored. Cannon towers deal bonus damage to them.", highlightElement: nil, waitForAction: nil, delay: 5.0),
                TutorialStep(message: "Tap a placed tower to upgrade or sell it.", highlightElement: nil, waitForAction: "selectPlacedTower", delay: 0),
                TutorialStep(message: "Upgrades are more cost-effective than buying new towers!", highlightElement: nil, waitForAction: nil, delay: 3.0),
                TutorialStep(message: "Good luck, Commander!", highlightElement: nil, waitForAction: nil, delay: 2.0)
            ],
            unlockRequirement: 0
        )
    }
    
    private static func generateTutorialWaves() -> [WaveConfig] {
        return [
            // Wave 1: Simple infantry
            WaveConfig(waveNumber: 1, groups: [
                WaveConfig.EnemyGroup(type: .infantry, count: 5, level: 1, spawnInterval: 2.0)
            ]),
            // Wave 2: More infantry
            WaveConfig(waveNumber: 2, groups: [
                WaveConfig.EnemyGroup(type: .infantry, count: 8, level: 1, spawnInterval: 1.5)
            ]),
            // Wave 3: Introduce flying
            WaveConfig(waveNumber: 3, groups: [
                WaveConfig.EnemyGroup(type: .infantry, count: 5, level: 1, spawnInterval: 1.5),
                WaveConfig.EnemyGroup(type: .flying, count: 3, level: 1, spawnInterval: 2.0, groupDelay: 3.0)
            ]),
            // Wave 4: Introduce cavalry
            WaveConfig(waveNumber: 4, groups: [
                WaveConfig.EnemyGroup(type: .infantry, count: 6, level: 1, spawnInterval: 1.2),
                WaveConfig.EnemyGroup(type: .cavalry, count: 2, level: 1, spawnInterval: 2.5, groupDelay: 2.0)
            ]),
            // Wave 5: Mixed
            WaveConfig(waveNumber: 5, groups: [
                WaveConfig.EnemyGroup(type: .infantry, count: 8, level: 1, spawnInterval: 1.0),
                WaveConfig.EnemyGroup(type: .flying, count: 4, level: 1, spawnInterval: 1.5, groupDelay: 2.0),
                WaveConfig.EnemyGroup(type: .cavalry, count: 3, level: 1, spawnInterval: 2.0, groupDelay: 2.0)
            ])
        ]
    }
    
    // MARK: - Level 1: First Defense (20 waves)
    
    static var level1: LevelConfig {
        LevelConfig(
            levelNumber: 1,
            name: "First Defense",
            description: "Defend against the initial assault",
            startingMoney: 250,
            startingLives: 25,
            waves: generateLevel1Waves(),
            isTutorial: false,
            tutorialSteps: nil,
            unlockRequirement: 0
        )
    }
    
    private static func generateLevel1Waves() -> [WaveConfig] {
        var waves: [WaveConfig] = []
        
        for i in 1...20 {
            let level = 1 + (i - 1) / 5
            var groups: [WaveConfig.EnemyGroup] = []
            
            // Infantry base
            groups.append(WaveConfig.EnemyGroup(
                type: .infantry,
                count: 5 + i,
                level: level,
                spawnInterval: max(0.5, 1.5 - Double(i) * 0.05)
            ))
            
            // Add flying from wave 5
            if i >= 5 {
                groups.append(WaveConfig.EnemyGroup(
                    type: .flying,
                    count: 2 + (i - 5) / 3,
                    level: level,
                    spawnInterval: 1.5,
                    groupDelay: 2.0
                ))
            }
            
            // Add cavalry from wave 10
            if i >= 10 {
                groups.append(WaveConfig.EnemyGroup(
                    type: .cavalry,
                    count: 1 + (i - 10) / 4,
                    level: level,
                    spawnInterval: 2.0,
                    groupDelay: 2.0
                ))
            }
            
            waves.append(WaveConfig(waveNumber: i, groups: groups))
        }
        
        return waves
    }
    
    // MARK: - Level 2: Air Raid (25 waves)
    
    static var level2: LevelConfig {
        LevelConfig(
            levelNumber: 2,
            name: "Air Raid",
            description: "Heavy flying enemy presence",
            startingMoney: 300,
            startingLives: 25,
            waves: generateLevel2Waves(),
            isTutorial: false,
            tutorialSteps: nil,
            unlockRequirement: 1
        )
    }
    
    private static func generateLevel2Waves() -> [WaveConfig] {
        var waves: [WaveConfig] = []
        
        for i in 1...25 {
            let level = 1 + (i - 1) / 6
            var groups: [WaveConfig.EnemyGroup] = []
            
            // Light infantry
            groups.append(WaveConfig.EnemyGroup(
                type: .infantry,
                count: 4 + i / 2,
                level: level,
                spawnInterval: 1.2
            ))
            
            // Heavy flying emphasis
            groups.append(WaveConfig.EnemyGroup(
                type: .flying,
                count: 3 + i / 2,
                level: level,
                spawnInterval: max(0.6, 1.2 - Double(i) * 0.02),
                groupDelay: 1.5
            ))
            
            // Some cavalry for variety
            if i >= 8 && i % 3 == 0 {
                groups.append(WaveConfig.EnemyGroup(
                    type: .cavalry,
                    count: 2 + i / 8,
                    level: level,
                    spawnInterval: 2.0,
                    groupDelay: 2.0
                ))
            }
            
            waves.append(WaveConfig(waveNumber: i, groups: groups))
        }
        
        return waves
    }
    
    // MARK: - Level 3: Armored Assault (25 waves)
    
    static var level3: LevelConfig {
        LevelConfig(
            levelNumber: 3,
            name: "Armored Assault",
            description: "Heavy cavalry presence",
            startingMoney: 300,
            startingLives: 25,
            waves: generateLevel3Waves(),
            isTutorial: false,
            tutorialSteps: nil,
            unlockRequirement: 2
        )
    }
    
    private static func generateLevel3Waves() -> [WaveConfig] {
        var waves: [WaveConfig] = []
        
        for i in 1...25 {
            let level = 1 + (i - 1) / 5
            var groups: [WaveConfig.EnemyGroup] = []
            
            // Infantry support
            groups.append(WaveConfig.EnemyGroup(
                type: .infantry,
                count: 6 + i / 2,
                level: level,
                spawnInterval: 1.0
            ))
            
            // Heavy cavalry emphasis
            groups.append(WaveConfig.EnemyGroup(
                type: .cavalry,
                count: 2 + i / 3,
                level: level,
                spawnInterval: max(0.8, 1.5 - Double(i) * 0.02),
                groupDelay: 2.0
            ))
            
            // Light flying
            if i % 4 == 0 {
                groups.append(WaveConfig.EnemyGroup(
                    type: .flying,
                    count: 3 + i / 6,
                    level: level,
                    spawnInterval: 1.5,
                    groupDelay: 1.5
                ))
            }
            
            waves.append(WaveConfig(waveNumber: i, groups: groups))
        }
        
        return waves
    }
    
    // MARK: - Level 4-10 (30-50 waves each)
    
    static var level4: LevelConfig {
        generateAdvancedLevel(
            number: 4,
            name: "The Swarm",
            description: "Massive infantry waves",
            money: 350,
            lives: 25,
            waveCount: 30,
            emphasis: .infantry
        )
    }
    
    static var level5: LevelConfig {
        generateAdvancedLevel(
            number: 5,
            name: "Combined Arms",
            description: "Balanced mixed forces",
            money: 350,
            lives: 22,
            waveCount: 35,
            emphasis: .mixed
        )
    }
    
    static var level6: LevelConfig {
        generateAdvancedLevel(
            number: 6,
            name: "Sky Terror",
            description: "Air superiority assault",
            money: 400,
            lives: 22,
            waveCount: 35,
            emphasis: .flying
        )
    }
    
    static var level7: LevelConfig {
        generateAdvancedLevel(
            number: 7,
            name: "Iron Legion",
            description: "Elite armored forces",
            money: 400,
            lives: 20,
            waveCount: 40,
            emphasis: .cavalry
        )
    }
    
    static var level8: LevelConfig {
        generateAdvancedLevel(
            number: 8,
            name: "Blitzkrieg",
            description: "Fast and relentless",
            money: 450,
            lives: 20,
            waveCount: 40,
            emphasis: .fast
        )
    }
    
    static var level9: LevelConfig {
        generateAdvancedLevel(
            number: 9,
            name: "Endless Tide",
            description: "The largest assault yet",
            money: 500,
            lives: 18,
            waveCount: 45,
            emphasis: .massive
        )
    }
    
    static var level10: LevelConfig {
        generateAdvancedLevel(
            number: 10,
            name: "Final Stand",
            description: "The ultimate challenge",
            money: 500,
            lives: 15,
            waveCount: 50,
            emphasis: .ultimate
        )
    }
    
    private enum WaveEmphasis {
        case infantry, flying, cavalry, mixed, fast, massive, ultimate
    }
    
    private static func generateAdvancedLevel(number: Int, name: String, description: String, money: Int, lives: Int, waveCount: Int, emphasis: WaveEmphasis) -> LevelConfig {
        var waves: [WaveConfig] = []
        
        for i in 1...waveCount {
            let level = 1 + (i - 1) / 8 + (number - 4)
            var groups: [WaveConfig.EnemyGroup] = []
            
            let progress = Double(i) / Double(waveCount)
            let baseCount = 8 + Int(progress * 15)
            let spawnSpeed = max(0.3, 1.2 - progress * 0.5)
            
            switch emphasis {
            case .infantry:
                groups.append(WaveConfig.EnemyGroup(type: .infantry, count: baseCount + i / 2, level: level, spawnInterval: spawnSpeed))
                if i % 5 == 0 { groups.append(WaveConfig.EnemyGroup(type: .flying, count: 3 + i / 10, level: level, spawnInterval: 1.2, groupDelay: 2.0)) }
                if i % 7 == 0 { groups.append(WaveConfig.EnemyGroup(type: .cavalry, count: 2 + i / 12, level: level, spawnInterval: 1.5, groupDelay: 2.0)) }
                
            case .flying:
                groups.append(WaveConfig.EnemyGroup(type: .flying, count: baseCount / 2 + i / 3, level: level, spawnInterval: max(0.5, spawnSpeed)))
                groups.append(WaveConfig.EnemyGroup(type: .infantry, count: baseCount / 3, level: level, spawnInterval: 1.0, groupDelay: 1.5))
                if i % 6 == 0 { groups.append(WaveConfig.EnemyGroup(type: .cavalry, count: 2 + i / 10, level: level, spawnInterval: 1.5, groupDelay: 2.0)) }
                
            case .cavalry:
                groups.append(WaveConfig.EnemyGroup(type: .cavalry, count: baseCount / 3 + i / 4, level: level, spawnInterval: max(0.6, spawnSpeed + 0.3)))
                groups.append(WaveConfig.EnemyGroup(type: .infantry, count: baseCount / 2, level: level, spawnInterval: 0.8, groupDelay: 1.5))
                if i % 4 == 0 { groups.append(WaveConfig.EnemyGroup(type: .flying, count: 3 + i / 8, level: level, spawnInterval: 1.0, groupDelay: 2.0)) }
                
            case .mixed:
                groups.append(WaveConfig.EnemyGroup(type: .infantry, count: baseCount / 2, level: level, spawnInterval: spawnSpeed))
                groups.append(WaveConfig.EnemyGroup(type: .flying, count: baseCount / 4, level: level, spawnInterval: spawnSpeed + 0.2, groupDelay: 1.5))
                groups.append(WaveConfig.EnemyGroup(type: .cavalry, count: baseCount / 4, level: level, spawnInterval: spawnSpeed + 0.4, groupDelay: 1.5))
                
            case .fast:
                let fastLevel = level + 1
                groups.append(WaveConfig.EnemyGroup(type: .infantry, count: baseCount, level: fastLevel, spawnInterval: max(0.25, spawnSpeed - 0.3)))
                groups.append(WaveConfig.EnemyGroup(type: .flying, count: baseCount / 3, level: fastLevel, spawnInterval: 0.5, groupDelay: 1.0))
                groups.append(WaveConfig.EnemyGroup(type: .cavalry, count: baseCount / 4, level: fastLevel, spawnInterval: 0.8, groupDelay: 1.0))
                
            case .massive:
                groups.append(WaveConfig.EnemyGroup(type: .infantry, count: baseCount + i, level: level, spawnInterval: max(0.2, spawnSpeed - 0.4)))
                groups.append(WaveConfig.EnemyGroup(type: .flying, count: baseCount / 2, level: level, spawnInterval: 0.6, groupDelay: 1.0))
                groups.append(WaveConfig.EnemyGroup(type: .cavalry, count: baseCount / 3, level: level, spawnInterval: 0.8, groupDelay: 1.0))
                if i % 3 == 0 {
                    groups.append(WaveConfig.EnemyGroup(type: .infantry, count: baseCount / 2, level: level + 1, spawnInterval: 0.3, groupDelay: 2.0))
                }
                
            case .ultimate:
                let eliteLevel = level + 2
                groups.append(WaveConfig.EnemyGroup(type: .infantry, count: baseCount + i * 2, level: eliteLevel, spawnInterval: max(0.15, 0.5 - progress * 0.3)))
                groups.append(WaveConfig.EnemyGroup(type: .flying, count: baseCount / 2 + i / 2, level: eliteLevel, spawnInterval: 0.4, groupDelay: 0.5))
                groups.append(WaveConfig.EnemyGroup(type: .cavalry, count: baseCount / 3 + i / 3, level: eliteLevel, spawnInterval: 0.6, groupDelay: 0.5))
                // Boss waves every 10
                if i % 10 == 0 {
                    groups.append(WaveConfig.EnemyGroup(type: .cavalry, count: 5 + i / 5, level: eliteLevel + 1, spawnInterval: 1.0, groupDelay: 1.0))
                    groups.append(WaveConfig.EnemyGroup(type: .flying, count: 8 + i / 4, level: eliteLevel + 1, spawnInterval: 0.3, groupDelay: 0.5))
                }
            }
            
            waves.append(WaveConfig(waveNumber: i, groups: groups))
        }
        
        return LevelConfig(
            levelNumber: number,
            name: name,
            description: description,
            startingMoney: money,
            startingLives: lives,
            waves: waves,
            isTutorial: false,
            tutorialSteps: nil,
            unlockRequirement: number - 1
        )
    }
}
