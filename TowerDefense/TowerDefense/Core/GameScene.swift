import SpriteKit
import UIKit

/// Main game scene - integrates all systems
final class GameScene: SKScene {

    // MARK: - Properties

    // Game management
    private var gameManager: GameManager!
    private var targetingSystem: TargetingSystem!

    // Safe area from the hosting view (for responsive HUD/borders)
    var safeAreaInsets: UIEdgeInsets = .zero
    
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
        hudNode = HUDNode(sceneSize: size, safeAreaInsets: safeAreaInsets)
        hudNode.delegate = self
        uiLayer.addChild(hudNode)

        // Build Menu
        buildMenuNode = BuildMenuNode(sceneSize: size, safeAreaInsets: safeAreaInsets)
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
        
        // Draw spawn zone in top-left corner
        drawSpawnZone()
        
        // Draw exit zone in bottom-right corner only
        drawExitZone()
        
    }
    
    private func drawSpawnZone() {
        // Spawn zone is top-left: first 2 columns, top 4 rows
        let width = CGFloat(GameConstants.spawnZoneWidth) * GameConstants.cellSize
        let height = CGFloat(GameConstants.spawnZoneHeight) * GameConstants.cellSize
        let color = SKColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 0.4)
        
        let zone = SKShapeNode(rectOf: CGSize(width: width, height: height))
        zone.fillColor = color
        zone.strokeColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
        zone.lineWidth = 3
        zone.position = CGPoint(
            x: GameConstants.playFieldOrigin.x + width / 2,
            y: GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - height / 2
        )
        zone.zPosition = GameConstants.ZPosition.grid.rawValue - 1
        gameLayer.addChild(zone)
        
        // Label
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.fontSize = 14
        labelNode.fontColor = .white
        labelNode.text = "SPAWN"
        labelNode.position = CGPoint(x: 0, y: 0)
        zone.addChild(labelNode)
    }
    
    private func drawExitZone() {
        // Exit zone is bottom-right: last 2 columns, bottom 4 rows
        let width = CGFloat(GameConstants.exitZoneWidth) * GameConstants.cellSize
        let height = CGFloat(GameConstants.exitZoneHeight) * GameConstants.cellSize
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
        
        // Update AA missiles (they need to track moving targets)
        // Check both gameLayer and towerLayer for missiles
        for child in gameLayer.children {
            if let missile = child as? AntiAirMissile {
                missile.update(currentTime: gameTime)
            }
        }
        for child in towerLayer.children {
            if let missile = child as? AntiAirMissile {
                missile.update(currentTime: gameTime)
            }
        }
        
        // Update block power
        BlockManager.shared.update(currentTime: gameTime)
        hudNode.updateBlock(currentTime: gameTime)
        
        // Update lava power and deal damage
        LavaManager.shared.update(currentTime: gameTime, enemies: enemies)
        if LavaManager.shared.isActive {
            let lavaDPS = LavaManager.shared.lavaDamagePerSecond
            let scaledDamage = lavaDPS * CGFloat(scaledDeltaTime)
            for enemy in enemies where enemy.isAlive && LavaManager.shared.isInLavaArea(enemy) {
                enemy.takeDamage(scaledDamage)
            }
        }
        hudNode.updateLava(currentTime: gameTime)
        
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
        if !towerInfoNode.isHidden {
            let containsTouch = towerInfoNode.containsTouchPoint(location)
            if containsTouch {
                _ = towerInfoNode.handleTouch(at: location)
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
        
        // Check for lava placement mode
        if hudNode.isLavaPlacementMode {
            // Check if click is in playfield
            let playFieldRect = CGRect(
                origin: GameConstants.playFieldOrigin,
                size: GameConstants.playFieldSize
            )
            if playFieldRect.contains(location) {
                hudDidTapLava(at: location)
                hudNode.cancelLavaPlacement()
            } else {
                // Cancel placement if clicked outside
                hudNode.cancelLavaPlacement()
            }
            return
        }
        
        // Check for block placement mode
        if hudNode.isBlockPlacementMode {
            // Check if click is in playfield
            let playFieldRect = CGRect(
                origin: GameConstants.playFieldOrigin,
                size: GameConstants.playFieldSize
            )
            if playFieldRect.contains(location) {
                placeBlockObstacle(at: location)
                hudNode.cancelBlockPlacement()
            } else {
                // Cancel placement if clicked outside
                hudNode.cancelBlockPlacement()
            }
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
        // Create new tower - createTower already adds to towers array and towerLayer
        _ = createTower(type: targetType, at: gridPos)
        
        // AudioManager.shared.playSound(.towerPlace)
        updateUI()
    }
    
    private func updatePlacementPreview(at location: CGPoint) {
        guard let towerType = selectedTowerType else { return }
        
        let gridPos = gameManager.placementValidator.snapToGrid(worldPosition: location)
        let result = gameManager.canPlaceTower(at: gridPos, type: towerType)
        
        // Calculate buff multiplier at this position
        let buffMultiplier = getBuffRangeMultiplierAt(position: gridPos.toWorldPosition())
        
        placementPreviewNode.updatePosition(
            gridPosition: gridPos,
            isValid: result.isValid,
            invalidReason: result.reason,
            buffRangeMultiplier: buffMultiplier
        )
    }
    
    /// Get the range multiplier from nearby buff towers at a given position
    func getBuffRangeMultiplierAt(position: CGPoint) -> CGFloat {
        var bestMultiplier: CGFloat = 1.0
        
        for tower in towers {
            guard let buffTower = tower as? BuffTower else { continue }
            
            let distance = position.distance(to: buffTower.position)
            if distance <= buffTower.range {
                // Calculate effective buff multiplier based on buff tower's upgrade level
                // Range buff is roughly equivalent to damage buff: 15% + 10% per level
                let buffPercent = 0.15 + CGFloat(buffTower.upgradeLevel) * 0.10
                let multiplier = 1.0 + buffPercent
                bestMultiplier = max(bestMultiplier, multiplier)
            }
        }
        
        return bestMultiplier
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
        case .mine:
            tower = MineTower(gridPosition: gridPosition)
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
        
        // Handle mine tower cleanup
        if let mineTower = tower as? MineTower {
            mineTower.removeAllMines()
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
        // (bosses bypass this check)
        guard enemies.count < 150 || type == .boss else { return }
        
        let enemy: Enemy
        
        switch type {
        case .infantry:
            enemy = InfantryEnemy(level: max(1, level))
        case .cavalry:
            enemy = CavalryEnemy(level: max(1, level))
        case .flying:
            enemy = FlyingEnemy(level: max(1, level))
        case .boss:
            // Level >= 1000 means it encodes HP in thousands
            if level >= 1000 {
                let encodedHP = CGFloat(level - 1000) * 1000
                enemy = BossEnemy(level: 1, customHP: max(5000, encodedHP))
            } else {
                enemy = BossEnemy(level: max(1, level))
            }
        }
        
        enemy.delegate = self
        
        // Spawn position - top-left corner (spawn zone: top 4 rows, first 2 columns)
        let spawnZoneMinY = GameConstants.playFieldOrigin.y + CGFloat(GameConstants.gridHeight - GameConstants.spawnZoneHeight) * GameConstants.cellSize
        let spawnZoneMaxY = GameConstants.playFieldOrigin.y + GameConstants.playFieldSize.height - GameConstants.cellSize / 2
        let spawnY: CGFloat
        if type == .boss {
            spawnY = (spawnZoneMinY + spawnZoneMaxY) / 2  // Boss spawns in center of spawn zone
        } else {
            spawnY = CGFloat.random(in: spawnZoneMinY...spawnZoneMaxY)
        }
        
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
        
        // Reset powers
        BlockManager.shared.reset()
        LavaManager.shared.reset()
        
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
    
    func hudDidTapBlock() {
        // Block button was tapped - HUD handles the placement mode toggle
        // The actual placement happens in touchesBegan when tapping the grid
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
    
    func hudDidTapRestart() {
        restartGame()
    }
    
    func hudDidTapLava(at position: CGPoint) {
        // Activate lava at the specified position
        if LavaManager.shared.canActivate(currentTime: gameTime) {
            LavaManager.shared.activate(currentTime: gameTime, position: position)
            spawnLavaEffect(at: position)
        }
    }
    
    /// Place a temporary block obstacle that blocks enemies for 7 seconds
    /// Enemies will walk to the block and wait until it expires
    private func placeBlockObstacle(at location: CGPoint) {
        guard BlockManager.shared.canActivate(currentTime: gameTime) else { return }
        
        let gridPos = gameManager.placementValidator.snapToGrid(worldPosition: location)
        
        // Can't place in spawn or exit zones
        if gridPos.isInSpawnZone() || gridPos.isInExitZone() { return }
        
        // Can't place where a tower already is
        if gameManager.pathfindingGrid.isBlocked(gridPos) { return }
        
        // Activate the block power
        BlockManager.shared.activate(currentTime: gameTime, gridPosition: gridPos)
        
        // Block the cell in pathfinding but DON'T recalculate flow field yet
        // This way enemies will continue on their current path until they hit the block
        gameManager.pathfindingGrid.blockCell(gridPos)
        
        // Create visual obstacle
        let worldPos = gridPos.toWorldPosition()
        let blockNode = SKShapeNode(rectOf: CGSize(width: GameConstants.cellSize - 4, height: GameConstants.cellSize - 4), cornerRadius: 6)
        blockNode.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.7, alpha: 0.8)
        blockNode.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0)
        blockNode.lineWidth = 3
        blockNode.position = worldPos
        blockNode.zPosition = GameConstants.ZPosition.tower.rawValue
        blockNode.name = "blockObstacle"
        addChild(blockNode)
        
        // Add icon
        let icon = SKLabelNode(fontNamed: "Helvetica-Bold")
        icon.fontSize = 24
        icon.text = "🧱"
        icon.verticalAlignmentMode = .center
        icon.horizontalAlignmentMode = .center
        blockNode.addChild(icon)
        
        // Pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        blockNode.run(SKAction.repeatForever(pulse), withKey: "blockPulse")
        
        // Set up callback to remove block when it expires
        BlockManager.shared.onBlockExpired = { [weak self] expiredPos in
            guard let self = self else { return }
            
            // Unblock the cell and recalculate paths so enemies can continue
            self.gameManager.pathfindingGrid.unblockCell(expiredPos)
            self.notifyPathfindingChanged()
            
            // Remove visual
            if let obstacle = self.childNode(withName: "blockObstacle") {
                let fadeOut = SKAction.sequence([
                    SKAction.group([
                        SKAction.fadeOut(withDuration: 0.3),
                        SKAction.scale(to: 0.5, duration: 0.3)
                    ]),
                    SKAction.removeFromParent()
                ])
                obstacle.run(fadeOut)
            }
        }
    }
    
    func hudDidTapSave() {
        saveGame()
    }
    
    func hudDidTapLoad() {
        loadGame()
    }
    
    /// Current save format version for compatibility checking
    private static let saveFormatVersion = 1
    
    private func saveGame() {
        // Create save data with version for future compatibility
        var saveData: [String: Any] = [:]
        saveData["saveVersion"] = GameScene.saveFormatVersion
        saveData["saveDate"] = Date().timeIntervalSince1970
        
        // Save game state
        saveData["wave"] = gameManager.waveManager.currentWave
        saveData["money"] = gameManager.economyManager.money
        saveData["lives"] = gameManager.lives
        saveData["gameTime"] = gameTime
        saveData["totalEnemiesKilled"] = gameManager.totalEnemiesKilled
        
        // Save tower positions and types
        var towerData: [[String: Any]] = []
        for tower in towers {
            var td: [String: Any] = [:]
            td["type"] = tower.towerType.rawValue
            td["gridX"] = tower.gridPosition.x
            td["gridY"] = tower.gridPosition.y
            td["upgradeLevel"] = tower.upgradeLevel
            td["totalInvested"] = tower.totalInvested
            towerData.append(td)
        }
        saveData["towers"] = towerData
        
        // Encode and save
        do {
            let data = try JSONSerialization.data(withJSONObject: saveData, options: .prettyPrinted)
            UserDefaults.standard.set(data, forKey: "GameSave")
            UserDefaults.standard.synchronize()
        } catch {
            // Silently fail - user will see no visual feedback but game continues
        }
    }
    
    private func loadGame() {
        guard let data = UserDefaults.standard.data(forKey: "GameSave") else {
            return
        }
        
        do {
            guard let saveData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            
            // Check save version compatibility (for future migrations)
            let saveVersion = saveData["saveVersion"] as? Int ?? 1
            guard saveVersion <= GameScene.saveFormatVersion else {
                // Save is from a newer version - can't load
                return
            }
            
            // Clear current game state
            clearGameState()
            
            // Reset pathfinding grid before loading towers
            for x in 0..<GameConstants.gridWidth {
                for y in 0..<GameConstants.gridHeight {
                    gameManager.pathfindingGrid.unblockCell(GridPosition(x: x, y: y))
                }
            }
            
            // Load game state with validation
            if let wave = saveData["wave"] as? Int, wave >= 0 {
                gameManager.waveManager.setWave(wave)
            }
            if let money = saveData["money"] as? Int, money >= 0 {
                gameManager.economyManager.setMoney(money)
            }
            if let lives = saveData["lives"] as? Int, lives >= 0 {
                gameManager.setLives(lives)
            }
            if let savedGameTime = saveData["gameTime"] as? Double, savedGameTime >= 0 {
                gameTime = savedGameTime
            }
            
            // Load towers with validation
            if let towerDataArray = saveData["towers"] as? [[String: Any]] {
                for td in towerDataArray {
                    guard let typeRaw = td["type"] as? String,
                          let type = TowerType(rawValue: typeRaw),
                          let gridX = td["gridX"] as? Int,
                          let gridY = td["gridY"] as? Int else { continue }
                    
                    // Validate grid position is within bounds
                    guard gridX >= 0 && gridX < GameConstants.gridWidth &&
                          gridY >= 0 && gridY < GameConstants.gridHeight else { continue }
                    
                    let gridPos = GridPosition(x: gridX, y: gridY)
                    
                    // Skip if position is in spawn or exit zone
                    guard !gridPos.isInSpawnZone() && !gridPos.isInExitZone() else { continue }
                    
                    // Block the grid cell
                    gameManager.pathfindingGrid.blockCell(gridPos)
                    
                    // Create tower
                    let tower = createTowerOfType(type, at: gridPos)
                    tower.delegate = self
                    tower.position = gridPos.toWorldPosition()
                    
                    // Apply upgrades (with validation)
                    if let upgradeLevel = td["upgradeLevel"] as? Int {
                        let validLevel = max(0, min(upgradeLevel, tower.maxUpgradeLevel))
                        for _ in 0..<validLevel {
                            _ = tower.upgrade()
                        }
                    }
                    if let totalInvested = td["totalInvested"] as? Int, totalInvested >= 0 {
                        tower.totalInvested = totalInvested
                    }
                    
                    towers.append(tower)
                    towerLayer.addChild(tower)
                }
            }
            
            // Recalculate pathfinding
            notifyPathfindingChanged()
            
            // Update UI
            updateUI()
            
        } catch {
            // Load failed - silently continue with current game state
        }
    }
    
    /// Clear all game state for loading or restart
    private func clearGameState() {
        for enemy in enemies {
            enemy.removeFromParent()
        }
        enemies.removeAll()
        
        for tower in towers {
            if let mineTower = tower as? MineTower {
                mineTower.removeAllMines()
            }
            tower.removeFromParent()
        }
        towers.removeAll()
        
        // Reset managers
        BlockManager.shared.reset()
        LavaManager.shared.reset()
        
        // Clear effects
        effectsLayer.removeAllChildren()
        
        // Remove any active block obstacle
        childNode(withName: "blockObstacle")?.removeFromParent()
    }
    
    /// Create a tower of the specified type at the given position
    private func createTowerOfType(_ type: TowerType, at gridPosition: GridPosition) -> Tower {
        switch type {
        case .wall: return WallTower(gridPosition: gridPosition)
        case .machineGun: return MachineGunTower(gridPosition: gridPosition)
        case .cannon: return CannonTower(gridPosition: gridPosition)
        case .slow: return SlowTower(gridPosition: gridPosition)
        case .buff: return BuffTower(gridPosition: gridPosition)
        case .mine: return MineTower(gridPosition: gridPosition)
        case .splash: return SplashTower(gridPosition: gridPosition)
        case .laser: return LaserTower(gridPosition: gridPosition)
        case .antiAir: return AntiAirTower(gridPosition: gridPosition)
        }
    }
    
    private func spawnLavaEffect(at position: CGPoint) {
        let lavaRadius: CGFloat = 80
        
        // Create lava visual
        let lavaNode = SKShapeNode(circleOfRadius: lavaRadius)
        lavaNode.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.6)
        lavaNode.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.8)
        lavaNode.lineWidth = 3
        lavaNode.position = position
        lavaNode.zPosition = GameConstants.ZPosition.effects.rawValue
        lavaNode.name = "lavaEffect"
        effectsLayer.addChild(lavaNode)
        
        // Bubbling animation
        let bubble = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.3),
            SKAction.scale(to: 0.95, duration: 0.3)
        ])
        lavaNode.run(SKAction.repeatForever(bubble))
        
        // Remove after duration
        lavaNode.run(SKAction.sequence([
            SKAction.wait(forDuration: LavaManager.shared.lavaDuration),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
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

    func towerInfoDidChangePriority(_ tower: Tower, priority: TargetPriority) {
        tower.targetPriority = priority
        towerInfoNode.updateContent()
    }

    func towerInfoDidRequestMineDetonation(_ tower: MineTower) {
        tower.detonateAllMines()
    }

    func towerInfoDidRequestMineClear(_ tower: MineTower) {
        tower.clearAllMines()
        towerInfoNode.updateContent()
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
        let convertibleTypes: [TowerType] = [.machineGun, .cannon, .slow, .buff, .mine, .splash, .laser, .antiAir]
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
