import SpriteKit

/// Delegate for build menu interactions
protocol BuildMenuNodeDelegate: AnyObject {
    func buildMenuDidSelectTower(_ type: TowerType)
    func buildMenuDidDeselect()
    func canAfford(_ cost: Int) -> Bool
}

/// Tower selection menu - HORIZONTAL at top of screen, below HUD
final class BuildMenuNode: SKNode {
    
    // MARK: - Properties
    
    weak var delegate: BuildMenuNodeDelegate?
    
    private var towerButtons: [TowerType: TowerButton] = [:]
    private var selectedTower: TowerType?
    
    private let menuBackground: SKShapeNode
    private let menuWidth: CGFloat = 1200
    private let menuHeight: CGFloat = 65
    
    private let moneyLabel: SKLabelNode
    private let moneyIcon: SKLabelNode
    
    // MARK: - Initialization
    
    override init() {
        // Background panel - horizontal bar below HUD
        menuBackground = SKShapeNode(rectOf: CGSize(width: menuWidth, height: menuHeight), cornerRadius: 5)
        menuBackground.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 0.95)
        menuBackground.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        menuBackground.lineWidth = 2
        
        // Money display
        moneyIcon = SKLabelNode(fontNamed: "Helvetica-Bold")
        moneyIcon.fontSize = 18
        moneyIcon.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        moneyIcon.text = "💰"
        moneyIcon.verticalAlignmentMode = .center
        moneyIcon.horizontalAlignmentMode = .right
        
        moneyLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        moneyLabel.fontSize = 16
        moneyLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        moneyLabel.text = "$500"
        moneyLabel.verticalAlignmentMode = .center
        moneyLabel.horizontalAlignmentMode = .left
        
        super.init()
        
        setupMenu()
        zPosition = GameConstants.ZPosition.ui.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMenu() {
        // Position menu below HUD (at y=650, leaving room for HUD at 710)
        menuBackground.position = CGPoint(x: 667, y: 650)
        addChild(menuBackground)
        
        // Title on left
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.fontSize = 11
        title.fontColor = .gray
        title.text = "TOWERS:"
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -menuWidth/2 + 15, y: -3)
        menuBackground.addChild(title)
        
        // Create buttons for each tower type horizontally
        let buttonSpacing: CGFloat = 115
        var xOffset: CGFloat = -menuWidth/2 + 120
        
        for towerType in TowerType.allCases {
            let button = TowerButton(type: towerType)
            button.position = CGPoint(x: xOffset, y: 0)
            button.name = "towerButton_\(towerType.rawValue)"
            menuBackground.addChild(button)
            towerButtons[towerType] = button
            
            xOffset += buttonSpacing
        }
        
        // Money display on right side of menu bar
        moneyIcon.position = CGPoint(x: menuWidth/2 - 80, y: 0)
        menuBackground.addChild(moneyIcon)
        
        moneyLabel.position = CGPoint(x: menuWidth/2 - 55, y: 0)
        menuBackground.addChild(moneyLabel)
    }
    
    func updateMoney(_ amount: Int) {
        moneyLabel.text = "$\(amount)"
    }
    
    // MARK: - Updates
    
    func updateAffordability(money: Int) {
        for (type, button) in towerButtons {
            let canAfford = money >= type.baseCost
            button.setAffordable(canAfford)
        }
    }
    
    func setSelectedTower(_ type: TowerType?) {
        // Deselect previous
        if let prev = selectedTower, let button = towerButtons[prev] {
            button.setSelected(false)
        }
        
        selectedTower = type
        
        // Select new
        if let current = type, let button = towerButtons[current] {
            button.setSelected(true)
        }
    }
    
    // MARK: - Touch Handling
    
    func handleTouch(at location: CGPoint) -> Bool {
        // Convert to menu coordinates
        let menuLocation = convert(location, to: menuBackground)
        
        // Check if in menu background area first
        let menuFrame = CGRect(x: -menuWidth/2, y: -menuHeight/2, width: menuWidth, height: menuHeight)
        guard menuFrame.contains(menuLocation) else { return false }
        
        // Check each tower button
        for (type, button) in towerButtons {
            if button.containsTouchPoint(menuLocation) {
                if selectedTower == type {
                    // Deselect if tapping same button
                    setSelectedTower(nil)
                    delegate?.buildMenuDidDeselect()
                } else if delegate?.canAfford(type.baseCost) ?? false {
                    setSelectedTower(type)
                    delegate?.buildMenuDidSelectTower(type)
                }
                return true
            }
        }
        
        return true  // Consumed touch in menu area
    }
    
    func isInMenuArea(_ location: CGPoint) -> Bool {
        // Check if point is in the top menu bar area
        return location.y > 630
    }
}

// MARK: - Tower Button

private class TowerButton: SKNode {
    
    let towerType: TowerType
    private let background: SKShapeNode
    private let iconLabel: SKLabelNode
    private let nameLabel: SKLabelNode
    private let costLabel: SKLabelNode
    
    private var isAffordable = true
    private var isButtonSelected = false
    
    init(type: TowerType) {
        self.towerType = type
        
        // Button size
        background = SKShapeNode(rectOf: CGSize(width: 100, height: 50), cornerRadius: 6)
        background.fillColor = type.color.withAlphaComponent(0.3)
        background.strokeColor = type.color
        background.lineWidth = 2
        
        // Icon/symbol
        iconLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        iconLabel.fontSize = 20
        iconLabel.fontColor = .white
        iconLabel.verticalAlignmentMode = .center
        iconLabel.horizontalAlignmentMode = .center
        iconLabel.position = CGPoint(x: -30, y: 0)
        
        // Tower name
        nameLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nameLabel.fontSize = 11
        nameLabel.fontColor = .white
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -10, y: 8)
        
        // Cost
        costLabel = SKLabelNode(fontNamed: "Helvetica")
        costLabel.fontSize = 10
        costLabel.fontColor = .yellow
        costLabel.verticalAlignmentMode = .center
        costLabel.horizontalAlignmentMode = .left
        costLabel.position = CGPoint(x: -10, y: -8)
        
        super.init()
        
        addChild(background)
        addChild(iconLabel)
        addChild(nameLabel)
        addChild(costLabel)
        
        setupIcon()
        nameLabel.text = type.displayName
        costLabel.text = "$\(type.baseCost)"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupIcon() {
        let symbol = iconLabel
        
        switch towerType {
        case .wall:
            symbol.text = "▢"
        case .machineGun:
            symbol.text = "⟫"
        case .cannon:
            symbol.text = "●"
        case .slow:
            symbol.text = "❄"
        case .buff:
            symbol.text = "★"
        case .shotgun:
            symbol.text = "⋮"
        case .splash:
            symbol.text = "◎"
        case .laser:
            symbol.text = "═"
        case .antiAir:
            symbol.text = "↑"
        }
    }
    
    func setAffordable(_ affordable: Bool) {
        isAffordable = affordable
        updateAppearance()
    }
    
    func setSelected(_ selected: Bool) {
        isButtonSelected = selected
        updateAppearance()
    }
    
    private func updateAppearance() {
        if !isAffordable {
            background.fillColor = SKColor.darkGray.withAlphaComponent(0.3)
            background.strokeColor = .darkGray
            iconLabel.alpha = 0.5
            nameLabel.alpha = 0.5
            costLabel.fontColor = .red
        } else if isButtonSelected {
            background.fillColor = towerType.color.withAlphaComponent(0.7)
            background.strokeColor = .white
            background.lineWidth = 3
            iconLabel.alpha = 1.0
            nameLabel.alpha = 1.0
            costLabel.fontColor = .green
        } else {
            background.fillColor = towerType.color.withAlphaComponent(0.3)
            background.strokeColor = towerType.color
            background.lineWidth = 2
            iconLabel.alpha = 1.0
            nameLabel.alpha = 1.0
            costLabel.fontColor = .yellow
        }
    }
    
    func containsTouchPoint(_ p: CGPoint) -> Bool {
        let localPoint = convert(p, from: parent!)
        let buttonFrame = CGRect(x: -50, y: -25, width: 100, height: 50)
        return buttonFrame.contains(localPoint)
    }
}
