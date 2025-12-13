import SpriteKit

/// Delegate for build menu interactions
protocol BuildMenuNodeDelegate: AnyObject {
    func buildMenuDidSelectTower(_ type: TowerType)
    func buildMenuDidDeselect()
    func canAfford(_ cost: Int) -> Bool
}

/// Tower selection menu - HORIZONTAL at top of screen
final class BuildMenuNode: SKNode {
    
    // MARK: - Properties
    
    weak var delegate: BuildMenuNodeDelegate?
    
    private var towerButtons: [TowerType: TowerButton] = [:]
    private var selectedTower: TowerType?
    
    private let menuBackground: SKShapeNode
    private let menuWidth: CGFloat = 900
    private let menuHeight: CGFloat = 70
    
    // MARK: - Initialization
    
    override init() {
        // Background panel - horizontal bar at top
        menuBackground = SKShapeNode(rectOf: CGSize(width: menuWidth, height: menuHeight), cornerRadius: 8)
        menuBackground.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.95)
        menuBackground.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        menuBackground.lineWidth = 2
        
        super.init()
        
        setupMenu()
        zPosition = GameConstants.ZPosition.ui.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMenu() {
        // Position menu at top center
        menuBackground.position = CGPoint(x: 550, y: 720)
        addChild(menuBackground)
        
        // Title on left side
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.fontSize = 12
        title.fontColor = .gray
        title.text = "BUILD:"
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -menuWidth/2 + 10, y: -5)
        menuBackground.addChild(title)
        
        // Create buttons for each tower type horizontally
        let buttonSpacing: CGFloat = 90
        var xOffset: CGFloat = -menuWidth/2 + 80
        
        for towerType in TowerType.allCases {
            let button = TowerButton(type: towerType)
            button.position = CGPoint(x: xOffset, y: 0)
            button.name = "towerButton_\(towerType.rawValue)"
            menuBackground.addChild(button)
            towerButtons[towerType] = button
            
            xOffset += buttonSpacing
        }
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
        
        // Check each tower button
        for (type, button) in towerButtons {
            if button.contains(menuLocation) {
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
        
        return false
    }
    
    func isInMenuArea(_ location: CGPoint) -> Bool {
        // Check if point is in the top menu bar area
        return location.y > 680
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
        
        // Smaller button for horizontal layout
        background = SKShapeNode(rectOf: CGSize(width: 80, height: 55), cornerRadius: 6)
        background.fillColor = type.color.withAlphaComponent(0.3)
        background.strokeColor = type.color
        background.lineWidth = 2
        
        // Icon/symbol
        iconLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        iconLabel.fontSize = 18
        iconLabel.fontColor = .white
        iconLabel.verticalAlignmentMode = .center
        iconLabel.horizontalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 0, y: 10)
        
        // Tower name
        nameLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nameLabel.fontSize = 10
        nameLabel.fontColor = .white
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: -8)
        
        // Cost
        costLabel = SKLabelNode(fontNamed: "Helvetica")
        costLabel.fontSize = 9
        costLabel.fontColor = .yellow
        costLabel.verticalAlignmentMode = .center
        costLabel.horizontalAlignmentMode = .center
        costLabel.position = CGPoint(x: 0, y: -20)
        
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
            symbol.text = "—"
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
            costLabel.fontColor = .yellow
        } else {
            background.fillColor = towerType.color.withAlphaComponent(0.3)
            background.strokeColor = towerType.color
            background.lineWidth = 2
            iconLabel.alpha = 1.0
            nameLabel.alpha = 1.0
            costLabel.fontColor = .yellow
        }
    }
    
    override func contains(_ p: CGPoint) -> Bool {
        return background.contains(p)
    }
}
