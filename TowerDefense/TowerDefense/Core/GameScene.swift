import SpriteKit

/// Main game scene - integrates all systems
final class GameScene: SKScene {
    
    // MARK: - Properties
    
    // Game management
    private var gameManager: GameManager!
    private var targetingSystem: TargetingSystem!
    
    // Containers
    private let gameLayer = SKNode()
    private let enemyLayer = SKNode()
    private let towerLayer = SKNode()
    private let projectileLayer = SKNode()
    private let effectsLayer = SKNode()
    private let uiLayer = SKNode()
    
    // UI Components
    private(set) var hudNode: HUDNode!
    private var buildMenuNode: BuildMenuNode!
    private var towerInfoNode: TowerInfoNode!
    private var placementPreviewNode: PlacementPreviewNode!
    
    // Game Objects
    private var enemies: [Enemy] = []
    private var towers: [Tower] = []
    
    // State
    private var selectedTowerType: TowerType?
    private var lastUpdateTime: TimeInterval = 0
    private var gameSpeed: CGFloat = 1.0
    
    // Grid visualization
    private var gridNode: SKNode?
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.12, blue: 0.15, alpha: 1.0)
        
        setupLayers()
        setupGameManager()
        setupUI()
        setupPlayfield()
        
        gameManager.startGame()
    }
    
    // MARK: - Setup
    
    private func setupLayers() {
        gameLayer.zPosition = 0
        addChild(gameLayer)
        
        enemyLayer.zPosition = GameConstants.ZPosition.enemy.rawValue
        gameLayer.addChild(enemyLayer)
        
        towerLayer.zPosition = GameConstants.ZPosition.tower.rawValue
        gameLayer.addChild(towerLayer)
        
        projectileLayer.zPosition = GameConstants.ZPosition.projectile.rawValue
        gameLayer.addChild(projectileLayer)
        
        effectsLayer.zPosition = GameConstants.ZPosition.effects.rawValue
        gameLayer.addChild(effectsLayer)
        
        uiLayer.zPosition = GameConstants.ZPosition.ui.rawValue
        addChild(uiLayer)
    }
    
    private func setupGameManager() {
        gameManager = GameManager()
        gameManager.setup(scene: self)
        
        targetingSystem = TargetingSystem(gameScene: self)
    }
    
    private func setupUI() {
        // HUD
        hudNode = HUDNode()
        hudNode.delegate = self
        uiLayer.addChild(hudNode)
        
        // Build Menu
        buildMenuNode = BuildMenuNode()
        buildMenuNode.delegate = self
        uiLayer.addChild(buildMenuNode)
        
        // Tower Info Panel
        towerInfoNode = TowerInfoNode()
        towerInfoNode.delegate = self
        uiLayer.addChild(towerInfoNode)
        
        // Placement Preview
        placementPreviewNode = PlacementPreviewNode()
        gameLayer.addChild(placementPreviewNode)
    }
    
    private func setupPlayfield() {
        // Background
        let background = SKShapeNode(rectOf: GameConstants.playFieldSize)
        background.fillColor = SKColor(red: 0.08, green: 0.1, blue: 0.12, alpha: 1.0)
        background.strokeColor = SKColor(red: 0.2, green: 0.25, blue: 0.3, alpha: 1.0)
        background.lineWidth = 2
        background.position = CGPoint(
            x: GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width / 2,
            y: GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height / 2
        )
        background.zPosition = GameConstants.ZPosition.background.rawValue
        gameLayer.addChild(background)
        
        // Draw grid
        drawGrid()
        
        // Draw spawn zone
        drawZone(
            startX: 0,
            endX: GameConstants.spawnZoneWidth,
            color: SKColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 0.3),
            label: "SPAWN"
        )
        
        // Draw exit zone
        drawZone(
            startX: GameConstants.gridWidth - GameConstants.exitZoneWidth,
            endX: GameConstants.gridWidth,
            color: SKColor(red: 0.4, green: 0.2, blue: 0.2, alpha: 0.3),
            label: "EXIT"
        )
    }
    
    private func drawGrid() {
        let gridContainer = SKNode()
        gridContainer.zPosition = GameConstants.ZPosition.grid.rawValue
        
        // Draw grid lines
        for x in 0...GameConstants.gridWidth {
            let startY = GameConstants.playFieldOrigin.y
            let endY = startY + GameConstants.playFieldSize.height
            let xPos = GameConstants.playFieldOrigin.x + CGFloat(x) * GameConstants.cellSize
            
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: xPos, y: startY))
            path.addLine(to: CGPoint(x: xPos, y: endY))
            line.path = path
            line.strokeColor = SKColor(red: 0.2, green: 0.25, blue: 0.3, alpha: 0.5)
            line.lineWidth = 1
            gridContainer.addChild(line)
        }
        
        for y in 0...GameConstants.gridHeight {
            let startX = GameConstants.playFieldOrigin.x
            let endX = startX + GameConstants.playFieldSize.width
            let yPos = GameConstants.playFieldOrigin.y + CGFloat(y) * GameConstants.cellSize
            
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: startX, y: yPos))
            path.addLine(to: CGPoint(x: endX, y: yPos))
            line.path = path
            line.strokeColor = SKColor(red: 0.2, green: 0.25, blue: 0.3, alpha: 0.5)
            line.lineWidth = 1
            gridContainer.addChild(line)
        }
        
        gameLayer.addChild(gridContainer)
        gridNode = gridContainer
    }
    
    private func drawZone(startX: Int, endX: Int, color: SKColor, label: String) {
        let width = CGFloat(endX - startX) * GameConstants.cellSize
        let height = GameConstants.playFieldSize.height
        
        let zone = SKShapeNode(rectOf: CGSize(width: width, height: height))
        zone.fillColor = color
        zone.strokeColor = color.withAlphaComponent(0.8)
        zone.lineWidth = 2
        zone.position = CGPoint(
            x: GameConstants.playFieldOrigin.x + CGFloat(startX) * GameConstants.cellSize + width / 2,
            y: GameConstants.playFieldOrigin.y + height / 2
        )
        zone.zPosition = GameConstants.ZPosition.grid.rawValue - 1
        gameLayer.addChild(zone)
        
        // Label
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.fontSize = 14
        labelNode.fontColor = color.withAlphaComponent(0.8)
        labelNode.text = label
        labelNode.zRotation = .pi / 2
        zone.addChild(labelNode)
    }
    
    // MARK: - Update Loop
    
    override func update(_ currentTime: TimeInterval) {
        // Calculate delta time
        let deltaTime = lastUpdateTime > 0 ? (currentTime - lastUpdateTime) * Double(gameSpeed) : 0
        lastUpdateTime = currentTime
        
        guard gameManager.isGameActive() else { return }
        
        // Update wave manager
        gameManager.waveManager.update(currentTime: currentTime * Double(gameSpeed))
        
        // Update enemies
        for enemy in enemies where enemy.isAlive {
            enemy.update(deltaTime: deltaTime, currentTime: currentTime, enemies: enemies)
        }
        
        // Clean up dead enemies
        enemies.removeAll { !$0.isAlive && $0.parent == nil }
        
        // Update towers
        for tower in towers {
            tower.update(currentTime: currentTime * Double(gameSpeed))
        }
        
        // Update UI
        updateUI()
    }
    
    func updateUI() {
        hudNode.updateLives(gameManager.lives)
        hudNode.updateMoney(gameManager.economyManager.money)
        hudNode.updateWave(
            gameManager.waveManager.currentWave,
            total: gameManager.waveManager.totalWaves,
            active: gameManager.waveManager.isWaveActive
        )
        buildMenuNode.updateAffordability(money: gameManager.economyManager.money)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        handleTouch(at: location)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Update placement preview if in placement mode
        if selectedTowerType != nil {
            updatePlacementPreview(at: location)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Attempt placement if in placement mode
        if let towerType = selectedTowerType {
            attemptPlacement(at: location, type: towerType)
        }
    }
    
    private func handleTouch(at location: CGPoint) {
        // Check for game over/victory restart
        if gameManager.gameState == .gameOver || gameManager.gameState == .victory {
            restartGame()
            return
        }
        
        // Check HUD
        if hudNode.handleTouch(at: location) {
            return
        }
        
        // Check tower info panel
        if towerInfoNode.handleTouch(at: location) {
            return
        }
        
        // Check build menu
        if buildMenuNode.handleTouch(at: location) {
            return
        }
        
        // Check if in menu area
        if buildMenuNode.isInMenuArea(location) {
            return
        }
        
        // If not in placement mode, check for tower selection
        if selectedTowerType == nil {
            if let tower = getTowerAt(location) {
                selectTower(tower)
                return
            } else {
                // Deselect current tower
                towerInfoNode.hide()
            }
        }
        
        // Update placement preview
        if selectedTowerType != nil {
            updatePlacementPreview(at: location)
        }
    }
    
    private func updatePlacementPreview(at location: CGPoint) {
        guard let towerType = selectedTowerType else { return }
        
        let gridPos = gameManager.placementValidator.snapToGrid(worldPosition: location)
        let result = gameManager.canPlaceTower(at: gridPos, type: towerType)
        
        placementPreviewNode.updatePosition(
            gridPosition: gridPos,
            isValid: result.isValid,
            invalidReason: result.reason
        )
    }
    
    private func attemptPlacement(at location: CGPoint, type: TowerType) {
        guard gameManager.placementValidator.isInPlayableArea(worldPosition: location) else {
            return
        }
        
        let gridPos = gameManager.placementValidator.snapToGrid(worldPosition: location)
        
        if let tower = gameManager.placeTower(type: type, at: gridPos) {
            placementPreviewNode.animatePlacementSuccess()
            
            // Keep placement mode active for consecutive placements
            // Or exit if desired:
            // exitPlacementMode()
        } else {
            placementPreviewNode.animatePlacementFailed()
        }
    }
    
    private func enterPlacementMode(type: TowerType) {
        selectedTowerType = type
        placementPreviewNode.startPreview(towerType: type)
        towerInfoNode.hide()
    }
    
    private func exitPlacementMode() {
        selectedTowerType = nil
        placementPreviewNode.endPreview()
        buildMenuNode.setSelectedTower(nil)
    }
    
    private func selectTower(_ tower: Tower) {
        // Deselect previous
        towerInfoNode.selectedTower?.setSelected(false)
        
        // Select new
        tower.setSelected(true)
        towerInfoNode.show(for: tower)
        
        // Exit placement mode
        exitPlacementMode()
    }
    
    private func getTowerAt(_ location: CGPoint) -> Tower? {
        let gridPos = location.toGridPosition()
        return towers.first { $0.gridPosition == gridPos }
    }
    
    // MARK: - Game Object Management
    
    func createTower(type: TowerType, at gridPosition: GridPosition) -> Tower {
        let tower: Tower
        
        switch type {
        case .machineGun:
            tower = MachineGunTower(gridPosition: gridPosition)
        case .cannon:
            tower = CannonTower(gridPosition: gridPosition)
        case .slow:
            tower = SlowTower(gridPosition: gridPosition)
        case .buff:
            tower = BuffTower(gridPosition: gridPosition)
        case .shotgun:
            tower = ShotgunTower(gridPosition: gridPosition)
        case .splash:
            tower = SplashTower(gridPosition: gridPosition)
        case .laser:
            tower = LaserTower(gridPosition: gridPosition)
        case .antiAir:
            tower = AntiAirTower(gridPosition: gridPosition)
        }
        
        tower.delegate = self
        towers.append(tower)
        towerLayer.addChild(tower)
        
        // Play placement sound
        AudioManager.shared.playSound(.towerPlace)
        
        // Update enemies' paths
        notifyPathfindingChanged()
        
        return tower
    }
    
    func removeTower(_ tower: Tower) {
        // Handle buff tower cleanup
        if let buffTower = tower as? BuffTower {
            buffTower.removeAllBuffs()
        }
        
        towers.removeAll { $0.id == tower.id }
        tower.removeFromParent()
        
        // Play sell sound
        AudioManager.shared.playSound(.towerSell)
        
        // Update enemies' paths
        notifyPathfindingChanged()
    }
    
    private func spawnEnemy(type: EnemyType, level: Int) {
        let enemy: Enemy
        
        switch type {
        case .infantry:
            enemy = InfantryEnemy(level: level)
        case .cavalry:
            enemy = CavalryEnemy(level: level)
        case .flying:
            enemy = FlyingEnemy(level: level)
        }
        
        enemy.delegate = self
        
        // Random spawn position
        let spawnY = CGFloat.random(
            in: GameConstants.playFieldOrigin.y + 50...GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - 50
        )
        enemy.position = CGPoint(
            x: GameConstants.playFieldOrigin.x + GameConstants.cellSize,
            y: spawnY
        )
        
        enemies.append(enemy)
        enemyLayer.addChild(enemy)
    }
    
    private func notifyPathfindingChanged() {
        // Flow field will be recalculated on next access
        gameManager.pathfindingGrid.invalidateFlowField()
    }
    
    // MARK: - Game State
    
    func handleGameOver() {
        AudioManager.shared.playSound(.gameOver)
        hudNode.showGameOver()
    }
    
    func handleVictory() {
        AudioManager.shared.playSound(.victory)
        hudNode.showVictory()
    }
    
    private func restartGame() {
        // Remove all game objects
        enemies.forEach { $0.removeFromParent() }
        enemies.removeAll()
        
        towers.forEach { $0.removeFromParent() }
        towers.removeAll()
        
        // Reset pathfinding grid
        for x in 0..<GameConstants.gridWidth {
            for y in 0..<GameConstants.gridHeight {
                gameManager.pathfindingGrid.unblockCell(GridPosition(x: x, y: y))
            }
        }
        
        // Reset managers
        gameManager = GameManager()
        gameManager.setup(scene: self)
        
        // Remove overlays
        hudNode.childNode(withName: "gameOverOverlay")?.removeFromParent()
        hudNode.childNode(withName: "victoryOverlay")?.removeFromParent()
        
        // Restart
        gameManager.startGame()
        updateUI()
    }
    
    // MARK: - Public Accessors
    
    func getAllEnemies() -> [Enemy] {
        return enemies
    }
    
    func getAllTowers() -> [Tower] {
        return towers
    }
}

// MARK: - HUDNodeDelegate

extension GameScene: HUDNodeDelegate {
    func hudDidTapPause() {
        gameManager.togglePause()
    }
    
    func hudDidTapStartWave() {
        gameManager.startWave(currentTime: lastUpdateTime)
    }
    
    func hudDidTapFastForward() {
        gameSpeed = hudNode.isFastForwardEnabled() ? 2.0 : 1.0
    }
}

// MARK: - BuildMenuNodeDelegate

extension GameScene: BuildMenuNodeDelegate {
    func buildMenuDidSelectTower(_ type: TowerType) {
        enterPlacementMode(type: type)
    }
    
    func buildMenuDidDeselect() {
        exitPlacementMode()
    }
    
    func canAfford(_ cost: Int) -> Bool {
        return gameManager.economyManager.canAfford(cost)
    }
}

// MARK: - TowerInfoNodeDelegate

extension GameScene: TowerInfoNodeDelegate {
    func towerInfoDidTapUpgrade(_ tower: Tower) {
        if gameManager.upgradeTower(tower) {
            AudioManager.shared.playSound(.towerUpgrade)
        }
        towerInfoNode.updateContent()
        updateUI()
    }
    
    func towerInfoDidTapSell(_ tower: Tower) {
        gameManager.sellTower(tower)
        updateUI()
    }
    
    func towerInfoDidClose() {
        // Nothing special needed
    }
}

// MARK: - EnemyDelegate

extension GameScene: EnemyDelegate {
    func enemyDidReachExit(_ enemy: Enemy) {
        AudioManager.shared.playSound(.lifeLost)
        gameManager.enemyReachedExit(enemy)
    }
    
    func enemyDidDie(_ enemy: Enemy) {
        AudioManager.shared.playSound(.enemyDeath)
        AudioManager.shared.playSound(.coinEarn)
        gameManager.enemyKilled(enemy)
    }
    
    func getFlowField() -> FlowField? {
        return gameManager.getFlowField()
    }
}

// MARK: - TowerDelegate

extension GameScene: TowerDelegate {
    func towerDidFire(_ tower: Tower, at target: Enemy) {
        // Could add global effects here
    }
    
    func getEnemiesInRange(of tower: Tower) -> [Enemy] {
        return targetingSystem.getEnemiesInRange(of: tower)
    }
    
    func getAllTowers() -> [Tower] {
        return towers
    }
}

// MARK: - WaveManagerDelegate

extension GameScene: WaveManagerDelegate {
    func waveDidStart(waveNumber: Int) {
        AudioManager.shared.playSound(.waveStart)
        
        // Show wave start notification
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.fontSize = 36
        label.fontColor = .white
        label.text = "Wave \(waveNumber)"
        label.position = CGPoint(x: 667, y: 375)
        label.zPosition = GameConstants.ZPosition.effects.rawValue + 100
        addChild(label)
        
        let animation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ])
        label.run(animation)
    }
    
    func waveDidComplete(waveNumber: Int) {
        AudioManager.shared.playSound(.waveComplete)
        gameManager.waveCompleted(waveNumber: waveNumber)
        
        // Show completion notification
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.fontSize = 24
        label.fontColor = .healthBarGreen
        label.text = "Wave \(waveNumber) Complete!"
        label.position = CGPoint(x: 667, y: 375)
        label.zPosition = GameConstants.ZPosition.effects.rawValue + 100
        addChild(label)
        
        let animation = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        label.run(animation)
    }
    
    func allWavesCompleted() {
        // Handled by gameManager.victory()
    }
    
    func spawnEnemy(type: EnemyType, level: Int) {
        self.spawnEnemy(type: type, level: level)
    }
}

// MARK: - EconomyManagerDelegate

extension GameScene: EconomyManagerDelegate {
    func moneyDidChange(newAmount: Int) {
        hudNode.updateMoney(newAmount)
        buildMenuNode.updateAffordability(money: newAmount)
    }
    
    func purchaseFailed(reason: String) {
        // Show notification
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.fontSize = 16
        label.fontColor = .healthBarRed
        label.text = reason
        label.position = CGPoint(x: 667, y: 300)
        label.zPosition = GameConstants.ZPosition.effects.rawValue + 100
        addChild(label)
        
        let animation = SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        label.run(animation)
    }
}
