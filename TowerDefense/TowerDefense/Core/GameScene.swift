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
    private var gameTime: TimeInterval = 0  // Accumulated game time (respects speed)
    
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
        towerInfoNode.zPosition = 500  // Highest priority, above all other UI
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
        
        // Draw exit zone in bottom-right corner only
        drawExitZone()
        
    }
    
    private func drawExitZone() {
        // Exit zone is bottom-right: last 2 columns, bottom 4 rows
        let width = CGFloat(GameConstants.exitZoneWidth) * GameConstants.cellSize
        let height = CGFloat(4) * GameConstants.cellSize  // 4 rows
        let color = SKColor(red: 0.4, green: 0.2, blue: 0.2, alpha: 0.4)
        
        let zone = SKShapeNode(rectOf: CGSize(width: width, height: height))
        zone.fillColor = color
        zone.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
        zone.lineWidth = 3
        zone.position = CGPoint(
            x: GameConstants.playFieldOrigin.x + GameConstants.playFieldSize.width - width / 2,
            y: GameConstants.playFieldOrigin.y + height / 2
        )
        zone.zPosition = GameConstants.ZPosition.grid.rawValue - 1
        gameLayer.addChild(zone)
        
        // Label
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.fontSize = 16
        labelNode.fontColor = .white
        labelNode.text = "EXIT"
        labelNode.position = CGPoint(x: 0, y: 0)
        zone.addChild(labelNode)
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
        // Calculate real delta time first (not scaled)
        let realDeltaTime = lastUpdateTime > 0 ? (currentTime - lastUpdateTime) : 0
        lastUpdateTime = currentTime
        
        // Scale delta by game speed
        let scaledDeltaTime = realDeltaTime * Double(gameSpeed)
        
        // Accumulate game time (respects speed changes properly)
        gameTime += scaledDeltaTime
        
        guard gameManager.isGameActive() else { return }
        
        // Update wave manager with accumulated game time
        gameManager.waveManager.update(currentTime: gameTime)
        
        // Update enemies with scaled delta
        for enemy in enemies where enemy.isAlive {
            enemy.update(deltaTime: scaledDeltaTime, currentTime: gameTime, enemies: enemies)
        }
        
        // Clean up dead enemies
        enemies.removeAll { !$0.isAlive && $0.parent == nil }
        
        // Update towers with game time
        for tower in towers {
            tower.update(currentTime: gameTime)
        }
        
        // Update booze power
        BoozeManager.shared.update(currentTime: gameTime)
        hudNode.updateBooze(currentTime: gameTime)
        
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
        
        // Check if dragging over trash zone
        let inTrash = hudNode.isInTrashZone(location)
        hudNode.highlightTrashZone(inTrash)
        
        // Update placement preview if in placement mode
        if selectedTowerType != nil {
            updatePlacementPreview(at: location)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if dropped in trash zone
        if hudNode.isInTrashZone(location) {
            hudNode.highlightTrashZone(false)
            hudDidDropInTrash()
            return
        }
        
        hudNode.highlightTrashZone(false)
        
        // Attempt placement if in placement mode
        if let towerType = selectedTowerType {
            attemptPlacement(at: location, type: towerType)
        }
    }
    
    private func handleTouch(at location: CGPoint) {
        // Check conversion overlay first
        if let overlay = childNode(withName: "conversionOverlay") {
            handleConversionTouch(at: location, overlay: overlay)
            return
        }
        
        // Check for game over/victory restart
        if gameManager.gameState == .gameOver || gameManager.gameState == .victory {
            restartGame()
            return
        }
        
        // Check tower info panel FIRST (highest priority popup)
        print("GameScene touch at: \(location), towerInfo hidden: \(towerInfoNode.isHidden)")
        if !towerInfoNode.isHidden {
            let containsTouch = towerInfoNode.containsTouchPoint(location)
            print("GameScene: towerInfo containsTouch: \(containsTouch)")
            if containsTouch {
                let handled = towerInfoNode.handleTouch(at: location)
                print("GameScene: towerInfo handled touch: \(handled)")
                return
            }
        }
        
        // Check HUD
        if hudNode.handleTouch(at: location) {
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
    
    private func handleConversionTouch(at location: CGPoint, overlay: SKNode) {
        // Find what was touched
        let nodesAtPoint = nodes(at: location)
        
        for node in nodesAtPoint {
            // Cancel button
            if node.name == "cancelConversion" || node.name == "conversionDimmer" {
                overlay.removeFromParent()
                return
            }
            
            // Conversion button
            if let nodeName = node.name, nodeName.hasPrefix("convert_") {
                let typeString = String(nodeName.dropFirst("convert_".count))
                if let targetType = TowerType(rawValue: typeString),
                   let wallTower = overlay.userData?["wallTower"] as? Tower {
                    performConversion(wallTower: wallTower, to: targetType)
                    overlay.removeFromParent()
                    towerInfoNode.hide()
                }
                return
            }
        }
    }
    
    private func performConversion(wallTower: Tower, to targetType: TowerType) {
        let conversionCost = targetType.baseCost - TowerType.wall.baseCost
        
        guard gameManager.economyManager.canAfford(conversionCost) else {
            // AudioManager.shared.playSound(.invalidPlacement)
            return
        }
        
        // Spend money
        _ = gameManager.economyManager.spend(conversionCost)
        
        // Remove wall tower from our array
        let gridPos = wallTower.gridPosition
        wallTower.removeFromParent()
        towers.removeAll { $0 === wallTower }
        
        // Don't unblock grid - we're replacing with another tower
        // Create new tower
        let newTower = createTower(type: targetType, at: gridPos)
        newTower.position = gridPos.toWorldPosition()
        newTower.delegate = self
        towers.append(newTower)
        towerLayer.addChild(newTower)
        
        // AudioManager.shared.playSound(.towerPlace)
        updateUI()
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
        
        if gameManager.placeTower(type: type, at: gridPos) != nil {
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
        // Use distance-based selection for better touch accuracy
        let touchRadius: CGFloat = 40  // Generous touch area
        
        var closestTower: Tower?
        var closestDistance: CGFloat = touchRadius
        
        for tower in towers {
            let distance = location.distance(to: tower.position)
            if distance < closestDistance {
                closestDistance = distance
                closestTower = tower
            }
        }
        
        return closestTower
    }
    
    // MARK: - Game Object Management
    
    func createTower(type: TowerType, at gridPosition: GridPosition) -> Tower {
        let tower: Tower
        
        switch type {
        case .wall:
            tower = WallTower(gridPosition: gridPosition)
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
        // AudioManager.shared.playSound(.towerPlace)
        
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
        // AudioManager.shared.playSound(.towerSell)
        
        // Update enemies' paths
        notifyPathfindingChanged()
    }
    
    func spawnEnemy(type: EnemyType, level: Int) {
        // Safety: limit max enemies on screen to prevent memory issues
        guard enemies.count < 150 else { return }
        
        let enemy: Enemy
        
        switch type {
        case .infantry:
            enemy = InfantryEnemy(level: max(1, level))
        case .cavalry:
            enemy = CavalryEnemy(level: max(1, level))
        case .flying:
            enemy = FlyingEnemy(level: max(1, level))
        }
        
        enemy.delegate = self
        
        // Random spawn position (with safety bounds)
        let minY = GameConstants.playFieldOrigin.y + 50
        let maxY = GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - 50
        let spawnY = CGFloat.random(in: minY...max(minY + 1, maxY))
        
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
        // AudioManager.shared.playSound(.gameOver)
        hudNode.showGameOver(
            wave: gameManager.waveManager.currentWave,
            enemiesKilled: gameManager.totalEnemiesKilled,
            livesRemaining: gameManager.lives
        )
    }
    
    func handleVictory() {
        // AudioManager.shared.playSound(.victory)
        hudNode.showVictory(
            wave: gameManager.waveManager.currentWave,
            enemiesKilled: gameManager.totalEnemiesKilled,
            livesRemaining: gameManager.lives
        )
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
        
        // Reset timing
        gameTime = 0
        lastUpdateTime = 0
        gameSpeed = 1.0
        
        // Reset booze power
        BoozeManager.shared.reset()
        
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
        // Ensure gameTime has started (at least a small value)
        if gameTime < 0.1 {
            gameTime = 0.1
        }
        gameManager.startWave(currentTime: gameTime)
    }
    
    func hudDidTapAutoStart() {
        // Auto-start toggled - nothing extra needed, HUD handles visual
    }
    
    func hudDidTapFastForward() {
        gameSpeed = hudNode.getSpeedMultiplier()
    }
    
    func hudDidTapBooze() {
        if BoozeManager.shared.canActivate(currentTime: gameTime) {
            BoozeManager.shared.activate(currentTime: gameTime)
        }
    }
    
    func hudDidDropInTrash() {
        // Sell selected tower or cancel placement
        if let tower = towerInfoNode.selectedTower {
            gameManager.sellTower(tower)
            towerInfoNode.hide()
            updateUI()
        } else if selectedTowerType != nil {
            exitPlacementMode()
        }
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
            // AudioManager.shared.playSound(.towerUpgrade)
        }
        towerInfoNode.updateContent()
        updateUI()
    }
    
    func towerInfoDidTapSell(_ tower: Tower) {
        towerInfoNode.hide()
        gameManager.sellTower(tower)
        updateUI()
    }
    
    func towerInfoDidTapConvert(_ tower: Tower) {
        // Show conversion menu for wall tower
        guard tower.towerType == .wall else { return }
        showConversionMenu(for: tower)
    }
    
    private func showConversionMenu(for wallTower: Tower) {
        // Create a simple conversion overlay
        let overlay = SKNode()
        overlay.name = "conversionOverlay"
        overlay.zPosition = GameConstants.ZPosition.ui.rawValue + 20
        
        // Background dimmer
        let dimmer = SKShapeNode(rectOf: CGSize(width: 1400, height: 800))
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.7)
        dimmer.strokeColor = .clear
        dimmer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dimmer.name = "conversionDimmer"
        overlay.addChild(dimmer)
        
        // Panel
        let panelWidth: CGFloat = 400
        let panelHeight: CGFloat = 500
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 15)
        panel.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.95)
        panel.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)
        panel.lineWidth = 2
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(panel)
        
        // Title
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.text = "Convert Wall To:"
        title.fontSize = 20
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelHeight / 2 - 35)
        panel.addChild(title)
        
        // Tower buttons - excluding wall
        let convertibleTypes: [TowerType] = [.machineGun, .cannon, .slow, .buff, .shotgun, .splash, .laser, .antiAir]
        let buttonWidth: CGFloat = 170
        let buttonHeight: CGFloat = 45
        let startY: CGFloat = panelHeight / 2 - 80
        
        for (index, type) in convertibleTypes.enumerated() {
            let row = index / 2
            let col = index % 2
            let x: CGFloat = col == 0 ? -buttonWidth / 2 - 10 : buttonWidth / 2 + 10
            let y: CGFloat = startY - CGFloat(row) * 55
            
            let cost = type.baseCost - TowerType.wall.baseCost
            
            let button = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 8)
            button.fillColor = type.color.withAlphaComponent(0.6)
            button.strokeColor = type.color
            button.lineWidth = 2
            button.position = CGPoint(x: x, y: y)
            button.name = "convert_\(type.rawValue)"
            
            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.text = "\(type.displayName) ($\(cost))"
            label.fontSize = 14
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            button.addChild(label)
            
            panel.addChild(button)
        }
        
        // Cancel button
        let cancelButton = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 8)
        cancelButton.fillColor = SKColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 1.0)
        cancelButton.strokeColor = .white
        cancelButton.lineWidth = 1
        cancelButton.position = CGPoint(x: 0, y: -panelHeight / 2 + 40)
        cancelButton.name = "cancelConversion"
        
        let cancelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        cancelLabel.text = "Cancel"
        cancelLabel.fontSize = 14
        cancelLabel.fontColor = .white
        cancelLabel.verticalAlignmentMode = .center
        cancelButton.addChild(cancelLabel)
        panel.addChild(cancelButton)
        
        // Store wall tower reference
        overlay.userData = NSMutableDictionary()
        overlay.userData?["wallTower"] = wallTower
        
        addChild(overlay)
    }
    
    func towerInfoDidClose() {
        // Nothing special needed
    }
}

// MARK: - EnemyDelegate

extension GameScene: EnemyDelegate {
    func enemyDidReachExit(_ enemy: Enemy) {
        // AudioManager.shared.playSound(.lifeLost)
        gameManager.enemyReachedExit(enemy)
    }
    
    func enemyDidDie(_ enemy: Enemy) {
        // AudioManager.shared.playSound(.enemyDeath)
        // AudioManager.shared.playSound(.coinEarn)
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
    
    // getAllTowers() is defined in main class body
}

// MARK: - WaveManagerDelegate

extension GameScene: WaveManagerDelegate {
    func waveDidStart(waveNumber: Int) {
        // AudioManager.shared.playSound(.waveStart)
        
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
        // AudioManager.shared.playSound(.waveComplete)
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
        
        // Auto-start next wave if enabled
        if hudNode.isAutoStartEnabled {
            // Small delay before starting next wave
            let autoStartAction = SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.run { [weak self] in
                    self?.hudDidTapStartWave()
                }
            ])
            run(autoStartAction, withKey: "autoStart")
        }
    }
    
    func allWavesCompleted() {
        // Handled by gameManager.victory()
    }
    
    // spawnEnemy is defined in main class body
}

// MARK: - EconomyManagerDelegate

extension GameScene: EconomyManagerDelegate {
    func moneyDidChange(newAmount: Int) {
        hudNode.updateMoney(newAmount)
        buildMenuNode.updateAffordability(money: newAmount)
        buildMenuNode.updateMoney(newAmount)
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
