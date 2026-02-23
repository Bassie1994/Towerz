import SpriteKit

/// Central game state manager
final class GameManager {
    
    // MARK: - Properties
    
    weak var scene: GameScene?
    
    // Game state
    private(set) var gameState: GameState = .preparing
    private(set) var gameMode: GameMode = .campaign
    private(set) var lives: Int = GameConstants.startingLives
    private(set) var maxTowerUpgradeLevel: Int = 5
    
    // Stats tracking
    private(set) var totalEnemiesKilled: Int = 0
    private(set) var totalMoneyEarned: Int = 0
    
    // Sub-systems
    let economyManager: EconomyManager
    let waveManager: WaveManager
    
    // Pathfinding
    let pathfindingGrid: PathfindingGrid
    let placementValidator: PlacementValidator

    private var startingWave: Int = 1
    private var configuredStartingMoney: Int = GameConstants.startingMoney
    private var configuredStartingLives: Int = GameConstants.startingLives
    private var pendingEndlessTransition: EndlessCycleTransition?

    struct EndlessCycleTransition {
        let cycle: Int
        let difficultyMultiplier: Double
        let maxUpgradeLevel: Int
    }
    
    // MARK: - Initialization
    
    init() {
        economyManager = EconomyManager()
        waveManager = WaveManager()
        
        pathfindingGrid = PathfindingGrid(
            width: GameConstants.gridWidth,
            height: GameConstants.gridHeight
        )
        placementValidator = PlacementValidator(grid: pathfindingGrid)
    }
    
    func setup(scene: GameScene) {
        self.scene = scene
        waveManager.delegate = scene
        economyManager.delegate = scene
    }
    
    // MARK: - Game Flow

    func configureGameMode(_ mode: GameMode) {
        gameMode = mode
        maxTowerUpgradeLevel = 5
        pendingEndlessTransition = nil

        switch mode {
        case .campaign:
            configuredStartingMoney = GameConstants.startingMoney
            configuredStartingLives = GameConstants.startingLives
            startingWave = 1
            waveManager.setEndlessMode(false)
        case .endless:
            configuredStartingMoney = GameConstants.Endless.startingMoney
            configuredStartingLives = GameConstants.startingLives
            startingWave = GameConstants.Endless.startingWave
            waveManager.setEndlessMode(true)
        case .puzzle:
            configuredStartingMoney = GameConstants.startingMoney
            configuredStartingLives = GameConstants.startingLives
            startingWave = 1
            waveManager.setEndlessMode(false)
        }
    }

    func consumePendingEndlessTransition() -> EndlessCycleTransition? {
        defer { pendingEndlessTransition = nil }
        return pendingEndlessTransition
    }
    
    func startGame() {
        gameState = .preparing
        lives = configuredStartingLives
        totalEnemiesKilled = 0
        totalMoneyEarned = 0
        waveManager.setWave(max(0, startingWave - 1))
        economyManager.setMoney(configuredStartingMoney)
        scene?.applyTowerUpgradeLevelCap(maxTowerUpgradeLevel)
        scene?.updateUI()
    }
    
    func startWave(currentTime: TimeInterval) {
        guard gameState != .gameOver && gameState != .victory else { return }

        if waveManager.isEndlessCycleBoundary() {
            waveManager.advanceEndlessCycle()
            maxTowerUpgradeLevel += 1
            scene?.applyTowerUpgradeLevelCap(maxTowerUpgradeLevel)
            pendingEndlessTransition = EndlessCycleTransition(
                cycle: waveManager.endlessCycle,
                difficultyMultiplier: waveManager.endlessDifficultyMultiplier,
                maxUpgradeLevel: maxTowerUpgradeLevel
            )
        }

        gameState = .playing
        waveManager.startNextWave(currentTime: currentTime)
    }
    
    func pauseGame() {
        guard gameState == .playing || gameState == .preparing else { return }
        gameState = .paused
    }
    
    func resumeGame() {
        guard gameState == .paused else { return }
        // Resume to preparing if no wave is active, otherwise continue playing.
        gameState = waveManager.isWaveActive ? .playing : .preparing
    }
    
    func togglePause() {
        if gameState == .paused {
            resumeGame()
        } else if gameState == .playing || gameState == .preparing {
            pauseGame()
        }
    }
    
    // MARK: - Lives
    
    /// Set lives directly (for loading saves)
    func setLives(_ newLives: Int) {
        lives = max(0, newLives)
        scene?.hudNode.updateLives(lives)
    }
    
    func loseLife() {
        lives -= 1
        scene?.hudNode.updateLives(lives)
        
        if lives <= 0 {
            gameOver()
        }
    }
    
    private func gameOver() {
        gameState = .gameOver
        scene?.handleGameOver()
    }
    
    func victory() {
        gameState = .victory
        scene?.handleVictory()
    }
    
    // MARK: - Tower Placement
    
    func canPlaceTower(at gridPosition: GridPosition, type: TowerType) -> PlacementValidationResult {
        return placementValidator.validate(gridPosition: gridPosition, towerType: type)
    }
    
    func placeTower(type: TowerType, at gridPosition: GridPosition) -> Tower? {
        // Validate
        let result = canPlaceTower(at: gridPosition, type: type)
        guard result.isValid else { return nil }
        
        // Purchase
        guard economyManager.purchaseTower(type: type) else { return nil }
        
        // Block cell
        pathfindingGrid.blockCell(gridPosition)
        
        // Notify scene to create tower
        return scene?.createTower(type: type, at: gridPosition)
    }
    
    func sellTower(_ tower: Tower) {
        // Unblock cell
        pathfindingGrid.unblockCell(tower.gridPosition)
        
        // Get money back
        economyManager.sellTower(tower)
        
        // Remove from scene
        scene?.removeTower(tower)
    }
    
    func upgradeTower(_ tower: Tower) -> Bool {
        guard tower.canUpgrade() else { return false }
        guard economyManager.upgradeTower(tower) else { return false }
        
        return tower.upgrade()
    }
    
    // MARK: - Enemy Events
    
    func enemyKilled(_ enemy: Enemy) {
        totalEnemiesKilled += 1
        let reward = economyManager.rewardForKill(enemy: enemy)
        totalMoneyEarned += reward
        waveManager.enemyKilled()
    }
    
    func enemyReachedExit(_ enemy: Enemy) {
        loseLife()
        waveManager.enemyReachedExit()
    }
    
    // MARK: - Wave Events
    
    func waveCompleted(waveNumber: Int) {
        economyManager.waveCompletionBonus(waveNumber: waveNumber)
        
        if waveNumber >= waveManager.totalWaves {
            if gameMode == .endless {
                gameState = .preparing
            } else {
                victory()
            }
        } else {
            gameState = .preparing
        }
    }
    
    // MARK: - Query
    
    func getFlowField() -> FlowField? {
        return pathfindingGrid.getFlowField()
    }
    
    func isGameActive() -> Bool {
        return gameState == .playing || gameState == .preparing
    }
}
