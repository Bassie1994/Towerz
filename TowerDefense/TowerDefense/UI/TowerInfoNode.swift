import SpriteKit

/// Delegate for tower info interactions
protocol TowerInfoNodeDelegate: AnyObject {
    func towerInfoDidTapUpgrade(_ tower: Tower)
    func towerInfoDidTapSell(_ tower: Tower)
    func towerInfoDidTapConvert(_ tower: Tower)
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
    
    private let panelWidth: CGFloat = 200
    private let panelHeight: CGFloat = 280
    
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
        
        let statOrder = ["Type", "Damage", "Range", "Fire Rate", "DPS", "Slow", "Duration", "Damage Buff", "ROF Buff", "Buffing", "Pellets", "Spread", "Splash Radius", "vs Flying", "Special", "Hint", "Best vs", "Note", "Level", "Sell Value"]
        
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
    
    // MARK: - Touch Handling
    
    func handleTouch(at location: CGPoint) -> Bool {
        guard !isHidden, let tower = selectedTower else { 
            return false 
        }
        
        // Convert scene location to local coordinates
        let localPoint = CGPoint(x: location.x - position.x, y: location.y - position.y)
        
        print("TowerInfo touch - scene: \(location), local: \(localPoint), pos: \(position)")
        
        // Check close button (top-right of panel)
        let closeButtonBounds = CGRect(
            x: panelWidth / 2 - 35,
            y: panelHeight / 2 - 35,
            width: 30,
            height: 30
        )
        if closeButtonBounds.contains(localPoint) {
            print("Close button tapped!")
            animateButton(closeButton)
            hide()
            return true
        }
        
        // Check upgrade button (bottom-left)
        let upgradeBounds = CGRect(
            x: -90,
            y: -panelHeight / 2 + 30,
            width: 90,
            height: 40
        )
        if upgradeBounds.contains(localPoint) {
            print("Upgrade button tapped!")
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
        
        // Check sell button (bottom-right)
        let sellBounds = CGRect(
            x: 0,
            y: -panelHeight / 2 + 30,
            width: 90,
            height: 40
        )
        if sellBounds.contains(localPoint) {
            print("Sell button tapped!")
            delegate?.towerInfoDidTapSell(tower)
            animateButton(sellButton)
            hide()
            return true
        }
        
        // Check if touch is within panel (consume it)
        let panelBounds = CGRect(
            x: -panelWidth / 2,
            y: -panelHeight / 2,
            width: panelWidth,
            height: panelHeight
        )
        if panelBounds.contains(localPoint) {
            print("Panel touched but no button hit")
            return true
        }
        
        return false
    }
    
    private func animateButton(_ button: SKShapeNode) {
        let press = SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.05)
        ])
        button.run(press)
    }
    
    func containsTouchPoint(_ location: CGPoint) -> Bool {
        guard !isHidden else { return false }
        let localPoint = CGPoint(x: location.x - position.x, y: location.y - position.y)
        let panelBounds = CGRect(
            x: -panelWidth / 2,
            y: -panelHeight / 2,
            width: panelWidth,
            height: panelHeight
        )
        return panelBounds.contains(localPoint)
    }
}
