import SpriteKit

/// Delegate for tower info interactions
protocol TowerInfoNodeDelegate: AnyObject {
    func towerInfoDidTapUpgrade(_ tower: Tower)
    func towerInfoDidTapSell(_ tower: Tower)
    func towerInfoDidTapConvert(_ tower: Tower)
    func towerInfoDidChangePriority(_ tower: Tower, priority: TargetPriority)
    func towerInfoDidRequestMineDetonation(_ tower: MineTower)
    func towerInfoDidRequestMineClear(_ tower: MineTower)
    func towerInfoDidClose()
}

/// Panel showing selected tower information
final class TowerInfoNode: SKNode {
    
    // MARK: - Properties
    
    weak var delegate: TowerInfoNodeDelegate?
    
    private(set) var selectedTower: Tower?
    
    private let panelBackground: SKShapeNode
    private let titleLabel: SKLabelNode
    private let statsContainer: SKNode
    private let upgradeButton: SKShapeNode
    private let upgradeLabel: SKLabelNode
    private let sellButton: SKShapeNode
    private let sellLabel: SKLabelNode
    private let closeButton: SKShapeNode
    private let targetingLabel: SKLabelNode
    private var targetingButtons: [TargetPriority: SKShapeNode] = [:]
    private let mineActionContainer: SKNode
    private let detonateButton: SKShapeNode
    private let clearButton: SKShapeNode

    private let panelWidth: CGFloat = 220
    private let panelHeight: CGFloat = 330
    
    // MARK: - Initialization
    
    override init() {
        // Panel background
        panelBackground = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 10)
        panelBackground.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 0.95)
        panelBackground.strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0)
        panelBackground.lineWidth = 2
        
        // Title
        titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: panelHeight / 2 - 30)
        
        // Stats container
        statsContainer = SKNode()
        statsContainer.position = CGPoint(x: -panelWidth / 2 + 20, y: panelHeight / 2 - 60)
        
        // Upgrade button
        upgradeButton = SKShapeNode(rectOf: CGSize(width: 80, height: 35), cornerRadius: 5)
        upgradeButton.fillColor = SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
        upgradeButton.strokeColor = .white
        upgradeButton.lineWidth = 1
        upgradeButton.position = CGPoint(x: -45, y: -panelHeight / 2 + 50)
        upgradeButton.name = "upgradeButton"
        
        upgradeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        upgradeLabel.fontSize = 12
        upgradeLabel.fontColor = .white
        upgradeLabel.text = "Upgrade"
        upgradeLabel.verticalAlignmentMode = .center
        
        // Sell button
        sellButton = SKShapeNode(rectOf: CGSize(width: 80, height: 35), cornerRadius: 5)
        sellButton.fillColor = SKColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 1.0)
        sellButton.strokeColor = .white
        sellButton.lineWidth = 1
        sellButton.position = CGPoint(x: 45, y: -panelHeight / 2 + 50)
        sellButton.name = "sellButton"
        
        sellLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        sellLabel.fontSize = 12
        sellLabel.fontColor = .white
        sellLabel.text = "Sell"
        sellLabel.verticalAlignmentMode = .center
        
        // Close button
        closeButton = SKShapeNode(circleOfRadius: 12)
        closeButton.fillColor = SKColor(red: 0.4, green: 0.2, blue: 0.2, alpha: 1.0)
        closeButton.strokeColor = .white
        closeButton.lineWidth = 1
        closeButton.position = CGPoint(x: panelWidth / 2 - 20, y: panelHeight / 2 - 20)
        closeButton.name = "closeButton"

        targetingLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        targetingLabel.fontSize = 13
        targetingLabel.fontColor = .white
        targetingLabel.horizontalAlignmentMode = .left
        targetingLabel.text = "Targeting:"

        mineActionContainer = SKNode()

        detonateButton = SKShapeNode(rectOf: CGSize(width: 90, height: 32), cornerRadius: 6)
        detonateButton.fillColor = SKColor(red: 0.65, green: 0.35, blue: 0.15, alpha: 1.0)
        detonateButton.strokeColor = .white
        detonateButton.lineWidth = 1
        detonateButton.name = "detonateButton"

        clearButton = SKShapeNode(rectOf: CGSize(width: 90, height: 32), cornerRadius: 6)
        clearButton.fillColor = SKColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
        clearButton.strokeColor = .white
        clearButton.lineWidth = 1
        clearButton.name = "clearButton"
        
        super.init()
        
        setupPanel()
        isHidden = true
        zPosition = GameConstants.ZPosition.ui.rawValue + 10
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPanel() {
        addChild(panelBackground)
        panelBackground.addChild(titleLabel)
        panelBackground.addChild(statsContainer)

        targetingLabel.position = CGPoint(x: -panelWidth / 2 + 20, y: -30)
        panelBackground.addChild(targetingLabel)
        setupTargetingButtons()

        upgradeButton.addChild(upgradeLabel)
        panelBackground.addChild(upgradeButton)
        
        sellButton.addChild(sellLabel)
        panelBackground.addChild(sellButton)
        
        // Close button X
        let xLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        xLabel.fontSize = 14
        xLabel.fontColor = .white
        xLabel.text = "✕"
        xLabel.verticalAlignmentMode = .center
        xLabel.horizontalAlignmentMode = .center
        closeButton.addChild(xLabel)
        panelBackground.addChild(closeButton)

        setupMineActionButtons()
    }

    private func setupTargetingButtons() {
        let startX = -panelWidth / 2 + 20
        let startY: CGFloat = -55
        let buttonSize = CGSize(width: 45, height: 26)
        let spacing: CGFloat = 5

        for (index, priority) in TargetPriority.allCases.enumerated() {
            let button = SKShapeNode(rectOf: buttonSize, cornerRadius: 5)
            button.fillColor = SKColor(white: 0.18, alpha: 1.0)
            button.strokeColor = .white
            button.lineWidth = 1
            button.position = CGPoint(
                x: startX + CGFloat(index) * (buttonSize.width + spacing) + buttonSize.width / 2,
                y: startY
            )
            button.name = "priority_\(priority.rawValue)"

            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.fontSize = 11
            label.fontColor = .white
            label.text = priority.displayName.prefix(1).uppercased()
            label.verticalAlignmentMode = .center
            button.addChild(label)

            targetingButtons[priority] = button
            panelBackground.addChild(button)
        }
    }

    private func setupMineActionButtons() {
        mineActionContainer.position = CGPoint(x: 0, y: -panelHeight / 2 + 90)

        let detonateLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        detonateLabel.fontSize = 12
        detonateLabel.fontColor = .white
        detonateLabel.text = "Detonate"
        detonateLabel.verticalAlignmentMode = .center
        detonateButton.addChild(detonateLabel)

        let clearLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        clearLabel.fontSize = 12
        clearLabel.fontColor = .white
        clearLabel.text = "Clear"
        clearLabel.verticalAlignmentMode = .center
        clearButton.addChild(clearLabel)

        detonateButton.position = CGPoint(x: -55, y: 0)
        clearButton.position = CGPoint(x: 55, y: 0)

        mineActionContainer.addChild(detonateButton)
        mineActionContainer.addChild(clearButton)
        panelBackground.addChild(mineActionContainer)
        mineActionContainer.isHidden = true
    }
    
    // MARK: - Show/Hide
    
    func show(for tower: Tower) {
        selectedTower = tower
        updateContent()
        
        // Position near tower but ensure on screen
        var panelX = tower.position.x + 100
        var panelY = tower.position.y
        
        // Keep on screen (accounting for reduced grid size)
        panelX = max(panelWidth / 2 + 10, min(1200 - panelWidth / 2, panelX))
        panelY = max(panelHeight / 2 + 80, min(550 - panelHeight / 2, panelY))
        
        position = CGPoint(x: panelX, y: panelY)
        setScale(1.0)  // Ensure scale is 1.0 for correct touch detection
        alpha = 1.0
        isHidden = false
        
        print("TowerInfoNode shown at: \(position), panelSize: \(panelWidth)x\(panelHeight)")
    }
    
    func hide() {
        selectedTower?.setSelected(false)
        selectedTower = nil
        isHidden = true  // Hide immediately for correct touch handling
        
        delegate?.towerInfoDidClose()
    }
    
    func updateContent() {
        guard let tower = selectedTower else { return }
        
        // Update title
        titleLabel.text = tower.towerType.displayName
        titleLabel.fontColor = tower.towerType.color
        
        // Update stats
        statsContainer.removeAllChildren()
        
        let stats = tower.getStats()
        var yOffset: CGFloat = 0
        let lineHeight: CGFloat = 22
        
        let statOrder = ["Type", "Damage", "Range", "Fire Rate", "DPS", "Slow", "Duration", "Damage Buff", "ROF Buff", "Range Buff", "Buffing", "Buffed", "Pellets", "Spread", "Splash Radius", "vs Flying", "Special", "Hint", "Best vs", "Note", "Level", "Sell Value"]
        
        for key in statOrder {
            if let value = stats[key] {
                let label = SKLabelNode(fontNamed: "Helvetica")
                label.fontSize = 13
                label.fontColor = .lightGray
                label.text = "\(key): \(value)"
                label.horizontalAlignmentMode = .left
                label.position = CGPoint(x: 0, y: yOffset)
                statsContainer.addChild(label)
                yOffset -= lineHeight
            }
        }

        updateTargetingUI(for: tower)
        updateMineActions(for: tower)
        
        // Update upgrade button - show "Convert" for wall towers
        if tower.towerType == .wall {
            upgradeLabel.text = "Convert"
            upgradeButton.alpha = 1.0
            upgradeButton.fillColor = SKColor(red: 0.4, green: 0.3, blue: 0.6, alpha: 1.0)
        } else if let upgradeCost = tower.getUpgradeCost() {
            upgradeLabel.text = "⬆ $\(upgradeCost)"
            upgradeButton.alpha = 1.0
            upgradeButton.fillColor = SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
        } else {
            upgradeLabel.text = "MAX"
            upgradeButton.alpha = 0.5
            upgradeButton.fillColor = .gray
        }
        
        // Update sell button
        sellLabel.text = "Sell $\(tower.sellValue)"
    }

    private func updateTargetingUI(for tower: Tower) {
        let supportsTargeting = !(tower is BuffTower) && !(tower is MineTower) && tower.towerType != .wall
        targetingLabel.isHidden = !supportsTargeting

        for (priority, button) in targetingButtons {
            button.isHidden = !supportsTargeting
            let isSelected = tower.targetPriority == priority
            button.fillColor = isSelected ? SKColor(red: 0.3, green: 0.55, blue: 0.85, alpha: 1.0) : SKColor(white: 0.18, alpha: 1.0)
            button.strokeColor = isSelected ? .white : SKColor(white: 0.6, alpha: 1.0)
        }
    }

    private func updateMineActions(for tower: Tower) {
        guard let mineTower = tower as? MineTower else {
            mineActionContainer.isHidden = true
            return
        }

        mineActionContainer.isHidden = false
        let isEmpty = mineTower.getActiveMineCount() == 0
        detonateButton.alpha = isEmpty ? 0.4 : 1.0
        detonateButton.isUserInteractionEnabled = !isEmpty
        clearButton.alpha = isEmpty ? 0.7 : 1.0
    }
    
    // MARK: - Touch Handling
    
    func handleTouch(at location: CGPoint) -> Bool {
        guard !isHidden, let tower = selectedTower else { 
            print("TowerInfo handleTouch: hidden or no tower")
            return false 
        }
        
        // Convert scene location to local coordinates
        let localPoint = CGPoint(x: location.x - position.x, y: location.y - position.y)
        
        print("TowerInfo handleTouch - scene: \(location), local: \(localPoint), pos: \(position)")
        
        // Flash the panel to show touch was received (visual debug)
        let flash = SKAction.sequence([
            SKAction.colorize(with: .yellow, colorBlendFactor: 0.3, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        panelBackground.run(flash)
        
        // Button dimensions (must match init)
        let upgradeSize = CGSize(width: 80, height: 35)
        let sellSize = CGSize(width: 80, height: 35)
        let closeRadius: CGFloat = 12
        
        // Button positions (must match init) - with panelHeight = 280, panelWidth = 200
        let upgradePos = CGPoint(x: -45, y: -panelHeight / 2 + 50)  // (-45, -90)
        let sellPos = CGPoint(x: 45, y: -panelHeight / 2 + 50)      // (45, -90)
        let closePos = CGPoint(x: panelWidth / 2 - 20, y: panelHeight / 2 - 20)  // (80, 120)
        
        // Add touch padding
        let padding: CGFloat = 15
        
        // Check close button (circular, use distance check)
        let distToClose = sqrt(pow(localPoint.x - closePos.x, 2) + pow(localPoint.y - closePos.y, 2))
        if distToClose <= closeRadius + padding {
            print("Close button tapped! dist: \(distToClose)")
            animateButton(closeButton)
            hide()
            return true
        }

        // Targeting priority buttons
        for (priority, button) in targetingButtons {
            guard !button.isHidden else { continue }
            if button.contains(localPoint) {
                delegate?.towerInfoDidChangePriority(tower, priority: priority)
                animateButton(button)
                updateContent()
                return true
            }
        }

        // Mine management buttons
        if let mineTower = tower as? MineTower, !mineActionContainer.isHidden {
            let pointInContainer = mineActionContainer.convert(localPoint, from: self)
            let pointForButtons = pointInContainer
            if detonateButton.contains(pointForButtons) && mineTower.getActiveMineCount() > 0 {
                delegate?.towerInfoDidRequestMineDetonation(mineTower)
                animateButton(detonateButton)
                return true
            }
            if clearButton.contains(pointForButtons) {
                delegate?.towerInfoDidRequestMineClear(mineTower)
                animateButton(clearButton)
                updateContent()
                return true
            }
        }
        
        // Check upgrade button (rectangular)
        let upgradeBounds = CGRect(
            x: upgradePos.x - upgradeSize.width / 2 - padding,
            y: upgradePos.y - upgradeSize.height / 2 - padding,
            width: upgradeSize.width + padding * 2,
            height: upgradeSize.height + padding * 2
        )
        if upgradeBounds.contains(localPoint) {
            print("Upgrade button tapped! localPoint: \(localPoint), bounds: \(upgradeBounds)")
            if tower.towerType == .wall {
                delegate?.towerInfoDidTapConvert(tower)
                animateButton(upgradeButton)
                return true
            } else if tower.canUpgrade() {
                delegate?.towerInfoDidTapUpgrade(tower)
                animateButton(upgradeButton)
                updateContent()
                return true
            }
            return true
        }
        
        // Check sell button (rectangular)
        let sellBounds = CGRect(
            x: sellPos.x - sellSize.width / 2 - padding,
            y: sellPos.y - sellSize.height / 2 - padding,
            width: sellSize.width + padding * 2,
            height: sellSize.height + padding * 2
        )
        if sellBounds.contains(localPoint) {
            print("Sell button tapped! localPoint: \(localPoint), bounds: \(sellBounds)")
            delegate?.towerInfoDidTapSell(tower)
            animateButton(sellButton)
            hide()
            return true
        }
        
        // Check if touch is within panel (consume it)
        let panelBounds = CGRect(
            x: -panelWidth / 2 - padding,
            y: -panelHeight / 2 - padding,
            width: panelWidth + padding * 2,
            height: panelHeight + padding * 2
        )
        if panelBounds.contains(localPoint) {
            print("Panel touched but no button hit - local: \(localPoint)")
            print("upgradeBounds: \(upgradeBounds), sellBounds: \(sellBounds)")
            return true
        }
        
        return false
    }
    
    private func animateButton(_ button: SKShapeNode) {
        // More visible animation feedback
        let originalColor = button.fillColor
        let press = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.85, duration: 0.05),
                SKAction.run { button.fillColor = .white }
            ]),
            SKAction.wait(forDuration: 0.1),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.1),
                SKAction.run { button.fillColor = originalColor }
            ])
        ])
        button.run(press)
    }
    
    func containsTouchPoint(_ location: CGPoint) -> Bool {
        guard !isHidden else { 
            print("TowerInfo containsTouchPoint: hidden, returning false")
            return false 
        }
        let localPoint = CGPoint(x: location.x - position.x, y: location.y - position.y)
        let panelBounds = CGRect(
            x: -panelWidth / 2,
            y: -panelHeight / 2,
            width: panelWidth,
            height: panelHeight
        )
        let contains = panelBounds.contains(localPoint)
        print("TowerInfo containsTouchPoint: scene=\(location), pos=\(position), local=\(localPoint), bounds=\(panelBounds), contains=\(contains)")
        return contains
    }
}
