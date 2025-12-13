import SpriteKit

/// Central game state manager
final class GameManager {
    
    // MARK: - Properties
    
    weak var scene: GameScene?
    
    // Game state
    private(set) var gameState: GameState = .preparing
    private(set) var lives: Int = GameConstants.startingLives
    
    // Stats tracking
    private(set) var totalEnemiesKilled: Int = 0
    private(set) var totalMoneyEarned: Int = 0
    
    // Sub-systems
    let economyManager: EconomyManager
    let waveManager: WaveManager
    
    // Pathfinding
    let pathfindingGrid: PathfindingGrid
    let placementValidator: PlacementValidator
    
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
    
    func startGame() {
        gameState = .preparing
        lives = GameConstants.startingLives
        totalEnemiesKilled = 0
        totalMoneyEarned = 0
        scene?.updateUI()
    }
    
    func startWave(currentTime: TimeInterval) {
        guard gameState != .gameOver && gameState != .victory else { return }
        gameState = .playing
        waveManager.startNextWave(currentTime: currentTime)
    }
    
    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        scene?.isPaused = true
    }
    
    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        scene?.isPaused = false
    }
    
    func togglePause() {
        if gameState == .paused {
            resumeGame()
        } else if gameState == .playing {
            pauseGame()
        }
    }
    
    // MARK: - Lives
    
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
            victory()
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
