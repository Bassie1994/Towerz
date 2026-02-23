import SpriteKit

/// Delegate for tower info interactions
protocol TowerInfoNodeDelegate: AnyObject {
    func towerInfoDidTapUpgrade(_ tower: Tower, applyToAllOfType: Bool)
    func towerInfoDidTapSell(_ tower: Tower, applyToAllOfType: Bool)
    func towerInfoDidTapConvert(_ tower: Tower)
    func towerInfoDidChangePriority(_ tower: Tower, priority: TargetPriority, applyToAllOfType: Bool)
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
    private let targetDropdownButton: SKShapeNode
    private let targetDropdownLabel: SKLabelNode
    private let targetOptionsContainer: SKNode
    private var targetOptionButtons: [TargetPriority: SKShapeNode] = [:]
    private var isTargetDropdownOpen: Bool = false

    private let selectAllButton: SKShapeNode
    private let selectAllLabel: SKLabelNode
    private var applyToAllOfType: Bool = false

    private let mineActionContainer: SKNode
    private let detonateButton: SKShapeNode
    private let clearButton: SKShapeNode

    private let panelWidth: CGFloat = 245
    private let panelHeight: CGFloat = 370

    // MARK: - Initialization

    override init() {
        panelBackground = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 10)
        panelBackground.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 0.95)
        panelBackground.strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0)
        panelBackground.lineWidth = 2

        titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: panelHeight / 2 - 30)

        statsContainer = SKNode()
        statsContainer.position = CGPoint(x: -panelWidth / 2 + 20, y: panelHeight / 2 - 60)

        upgradeButton = SKShapeNode(rectOf: CGSize(width: 90, height: 35), cornerRadius: 5)
        upgradeButton.fillColor = SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
        upgradeButton.strokeColor = .white
        upgradeButton.lineWidth = 1
        upgradeButton.position = CGPoint(x: -52, y: -panelHeight / 2 + 45)
        upgradeButton.name = "upgradeButton"

        upgradeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        upgradeLabel.fontSize = 12
        upgradeLabel.fontColor = .white
        upgradeLabel.text = "Upgrade"
        upgradeLabel.verticalAlignmentMode = .center

        sellButton = SKShapeNode(rectOf: CGSize(width: 90, height: 35), cornerRadius: 5)
        sellButton.fillColor = SKColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 1.0)
        sellButton.strokeColor = .white
        sellButton.lineWidth = 1
        sellButton.position = CGPoint(x: 52, y: -panelHeight / 2 + 45)
        sellButton.name = "sellButton"

        sellLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        sellLabel.fontSize = 12
        sellLabel.fontColor = .white
        sellLabel.text = "Sell"
        sellLabel.verticalAlignmentMode = .center

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

        targetDropdownButton = SKShapeNode(rectOf: CGSize(width: 145, height: 30), cornerRadius: 6)
        targetDropdownButton.fillColor = SKColor(white: 0.2, alpha: 1.0)
        targetDropdownButton.strokeColor = .white
        targetDropdownButton.lineWidth = 1
        targetDropdownButton.name = "targetDropdownButton"

        targetDropdownLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        targetDropdownLabel.fontSize = 12
        targetDropdownLabel.fontColor = .white
        targetDropdownLabel.verticalAlignmentMode = .center
        targetDropdownLabel.horizontalAlignmentMode = .center

        targetOptionsContainer = SKNode()
        targetOptionsContainer.name = "targetOptionsContainer"

        selectAllButton = SKShapeNode(rectOf: CGSize(width: 180, height: 28), cornerRadius: 6)
        selectAllButton.fillColor = SKColor(white: 0.25, alpha: 1.0)
        selectAllButton.strokeColor = .white
        selectAllButton.lineWidth = 1
        selectAllButton.name = "selectAllButton"

        selectAllLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        selectAllLabel.fontSize = 11
        selectAllLabel.fontColor = .white
        selectAllLabel.verticalAlignmentMode = .center
        selectAllLabel.horizontalAlignmentMode = .center

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

        targetingLabel.position = CGPoint(x: -panelWidth / 2 + 20, y: -35)
        panelBackground.addChild(targetingLabel)

        targetDropdownButton.position = CGPoint(x: 18, y: -58)
        targetDropdownButton.addChild(targetDropdownLabel)
        panelBackground.addChild(targetDropdownButton)

        targetOptionsContainer.position = CGPoint(x: 18, y: -76)
        panelBackground.addChild(targetOptionsContainer)
        setupTargetOptions()

        selectAllButton.position = CGPoint(x: 0, y: -panelHeight / 2 + 83)
        selectAllButton.addChild(selectAllLabel)
        panelBackground.addChild(selectAllButton)

        upgradeButton.addChild(upgradeLabel)
        panelBackground.addChild(upgradeButton)

        sellButton.addChild(sellLabel)
        panelBackground.addChild(sellButton)

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

    private func setupTargetOptions() {
        targetOptionsContainer.removeAllChildren()
        targetOptionButtons.removeAll()

        for (index, priority) in TargetPriority.allCases.enumerated() {
            let button = SKShapeNode(rectOf: CGSize(width: 145, height: 26), cornerRadius: 5)
            button.fillColor = SKColor(white: 0.17, alpha: 1.0)
            button.strokeColor = SKColor(white: 0.65, alpha: 1.0)
            button.lineWidth = 1
            button.position = CGPoint(x: 0, y: -CGFloat(index) * 28 - 12)
            button.name = "targetOption_\(priority.rawValue)"

            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.fontSize = 11
            label.fontColor = .white
            label.text = priority.displayName
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            button.addChild(label)

            targetOptionButtons[priority] = button
            targetOptionsContainer.addChild(button)
        }
        targetOptionsContainer.isHidden = true
    }

    private func setupMineActionButtons() {
        mineActionContainer.position = CGPoint(x: 0, y: -panelHeight / 2 + 123)

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
        if selectedTower?.id != tower.id {
            applyToAllOfType = false
            isTargetDropdownOpen = false
        }

        selectedTower = tower
        updateContent()

        var panelX = tower.position.x + 115
        var panelY = tower.position.y

        panelX = max(panelWidth / 2 + 10, min(1200 - panelWidth / 2, panelX))
        panelY = max(panelHeight / 2 + 80, min(550 - panelHeight / 2, panelY))

        position = CGPoint(x: panelX, y: panelY)
        setScale(1.0)
        alpha = 1.0
        isHidden = false
    }

    func hide() {
        selectedTower?.setSelected(false)
        selectedTower = nil
        isTargetDropdownOpen = false
        applyToAllOfType = false
        isHidden = true
        delegate?.towerInfoDidClose()
    }

    func updateContent() {
        guard let tower = selectedTower else { return }

        titleLabel.text = tower.towerType.displayName
        titleLabel.fontColor = tower.towerType.color

        statsContainer.removeAllChildren()
        let stats = tower.getStats()
        let statOrder = [
            "Type", "Damage", "Range", "Fire Rate", "DPS", "Slow", "Duration", "Damage Buff", "ROF Buff", "Range Buff",
            "Buffing", "Buffed", "Pellets", "Spread", "Splash Radius", "vs Flying", "Special", "Hint", "Best vs",
            "Note", "Position Bonus", "Level", "Sell Value"
        ]

        var yOffset: CGFloat = 0
        let lineHeight: CGFloat = 21
        for key in statOrder {
            guard let value = stats[key] else { continue }
            let label = SKLabelNode(fontNamed: "Helvetica")
            label.fontSize = 12.5
            label.fontColor = .lightGray
            label.text = "\(key): \(value)"
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: 0, y: yOffset)
            statsContainer.addChild(label)
            yOffset -= lineHeight
        }

        updateTargetingUI(for: tower)
        updateMineActions(for: tower)
        updateSelectAllButton()

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

        sellLabel.text = "Sell $\(tower.sellValue)"
    }

    private func supportsTargeting(_ tower: Tower) -> Bool {
        return !(tower is BuffTower) && !(tower is MineTower) && tower.towerType != .wall
    }

    private func updateTargetingUI(for tower: Tower) {
        let enabled = supportsTargeting(tower)
        targetingLabel.isHidden = !enabled
        targetDropdownButton.isHidden = !enabled
        if !enabled {
            isTargetDropdownOpen = false
        }

        targetOptionsContainer.isHidden = !enabled || !isTargetDropdownOpen
        let arrow = isTargetDropdownOpen ? "▲" : "▼"
        targetDropdownLabel.text = "\(tower.targetPriority.displayName) \(arrow)"

        for (priority, button) in targetOptionButtons {
            let selected = priority == tower.targetPriority
            button.fillColor = selected ? SKColor(red: 0.3, green: 0.55, blue: 0.85, alpha: 1.0) : SKColor(white: 0.17, alpha: 1.0)
            button.strokeColor = selected ? .white : SKColor(white: 0.65, alpha: 1.0)
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
        clearButton.alpha = isEmpty ? 0.7 : 1.0
    }

    private func updateSelectAllButton() {
        selectAllLabel.text = applyToAllOfType ? "Type Batch: ON" : "Type Batch: OFF"
        selectAllButton.fillColor = applyToAllOfType
            ? SKColor(red: 0.25, green: 0.55, blue: 0.25, alpha: 1.0)
            : SKColor(white: 0.25, alpha: 1.0)
    }

    // MARK: - Touch Handling

    func handleTouch(at location: CGPoint) -> Bool {
        guard !isHidden, let tower = selectedTower else { return false }

        let localPoint = CGPoint(x: location.x - position.x, y: location.y - position.y)
        let touchPadding: CGFloat = 14

        let distToClose = sqrt(pow(localPoint.x - closeButton.position.x, 2) + pow(localPoint.y - closeButton.position.y, 2))
        if distToClose <= 26 {
            animateButton(closeButton)
            hide()
            return true
        }

        // Target dropdown interactions
        if supportsTargeting(tower) {
            if targetDropdownButton.contains(localPoint) {
                isTargetDropdownOpen.toggle()
                animateButton(targetDropdownButton)
                updateContent()
                return true
            }

            if isTargetDropdownOpen {
                let pointInOptions = targetOptionsContainer.convert(localPoint, from: self)
                for (priority, button) in targetOptionButtons {
                    if button.contains(pointInOptions) {
                        delegate?.towerInfoDidChangePriority(tower, priority: priority, applyToAllOfType: applyToAllOfType)
                        isTargetDropdownOpen = false
                        animateButton(button)
                        updateContent()
                        return true
                    }
                }
            }
        }

        if selectAllButton.contains(localPoint) {
            applyToAllOfType.toggle()
            animateButton(selectAllButton)
            updateContent()
            return true
        }

        if let mineTower = tower as? MineTower, !mineActionContainer.isHidden {
            let pointInContainer = mineActionContainer.convert(localPoint, from: self)
            if detonateButton.contains(pointInContainer), mineTower.getActiveMineCount() > 0 {
                delegate?.towerInfoDidRequestMineDetonation(mineTower)
                animateButton(detonateButton)
                return true
            }
            if clearButton.contains(pointInContainer) {
                delegate?.towerInfoDidRequestMineClear(mineTower)
                animateButton(clearButton)
                updateContent()
                return true
            }
        }

        let upgradeBounds = CGRect(
            x: upgradeButton.position.x - 45 - touchPadding,
            y: upgradeButton.position.y - 17.5 - touchPadding,
            width: 90 + touchPadding * 2,
            height: 35 + touchPadding * 2
        )
        if upgradeBounds.contains(localPoint) {
            if tower.towerType == .wall {
                delegate?.towerInfoDidTapConvert(tower)
                animateButton(upgradeButton)
            } else if tower.canUpgrade() {
                delegate?.towerInfoDidTapUpgrade(tower, applyToAllOfType: applyToAllOfType)
                animateButton(upgradeButton)
                updateContent()
            }
            return true
        }

        let sellBounds = CGRect(
            x: sellButton.position.x - 45 - touchPadding,
            y: sellButton.position.y - 17.5 - touchPadding,
            width: 90 + touchPadding * 2,
            height: 35 + touchPadding * 2
        )
        if sellBounds.contains(localPoint) {
            delegate?.towerInfoDidTapSell(tower, applyToAllOfType: applyToAllOfType)
            animateButton(sellButton)
            hide()
            return true
        }

        let panelBounds = CGRect(
            x: -panelWidth / 2 - touchPadding,
            y: -panelHeight / 2 - touchPadding,
            width: panelWidth + touchPadding * 2,
            height: panelHeight + touchPadding * 2
        )
        if panelBounds.contains(localPoint) {
            if isTargetDropdownOpen {
                isTargetDropdownOpen = false
                updateContent()
            }
            return true
        }

        return false
    }

    private func animateButton(_ button: SKShapeNode) {
        let originalColor = button.fillColor
        let press = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.9, duration: 0.05),
                SKAction.run { button.fillColor = .white }
            ]),
            SKAction.wait(forDuration: 0.08),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.1),
                SKAction.run { button.fillColor = originalColor }
            ])
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
