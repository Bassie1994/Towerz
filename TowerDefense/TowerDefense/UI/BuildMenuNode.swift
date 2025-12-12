import SpriteKit

/// Delegate for build menu interactions
protocol BuildMenuNodeDelegate: AnyObject {
    func buildMenuDidSelectTower(_ type: TowerType)
    func buildMenuDidDeselect()
    func canAfford(_ cost: Int) -> Bool
}

/// Tower selection menu
final class BuildMenuNode: SKNode {
    
    // MARK: - Properties
    
    weak var delegate: BuildMenuNodeDelegate?
    
    private var towerButtons: [TowerType: TowerButton] = [:]
    private var selectedTower: TowerType?
    
    private let menuBackground: SKShapeNode
    private let menuWidth: CGFloat = 100
    private let menuHeight: CGFloat = 650
    
    // MARK: - Initialization
    
    override init() {
        // Background panel
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
        // Position menu on right side
        menuBackground.position = CGPoint(x: 1284, y: 375)
        addChild(menuBackground)
        
        // Title
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.fontSize = 14
        title.fontColor = .white
        title.text = "BUILD"
        title.position = CGPoint(x: 0, y: menuHeight / 2 - 20)
        menuBackground.addChild(title)
        
        // Create buttons for each tower type (8 towers now)
        let buttonSpacing: CGFloat = 76  // Reduced spacing for 8 buttons
        var yOffset: CGFloat = menuHeight / 2 - 60
        
        for towerType in TowerType.allCases {
            let button = TowerButton(type: towerType)
            button.position = CGPoint(x: 0, y: yOffset)
            button.name = "towerButton_\(towerType.rawValue)"
            menuBackground.addChild(button)
            towerButtons[towerType] = button
            
            yOffset -= buttonSpacing
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
        if let previous = selectedTower {
            towerButtons[previous]?.setSelected(false)
        }
        
        selectedTower = type
        
        // Select new
        if let type = type {
            towerButtons[type]?.setSelected(true)
        }
    }
    
    // MARK: - Touch Handling
    
    func handleTouch(at location: CGPoint) -> Bool {
        let menuLocation = convert(location, to: menuBackground)
        
        for (type, button) in towerButtons {
            if button.contains(menuLocation) {
                if delegate?.canAfford(type.baseCost) == true {
                    if selectedTower == type {
                        // Deselect
                        setSelectedTower(nil)
                        delegate?.buildMenuDidDeselect()
                    } else {
                        // Select
                        setSelectedTower(type)
                        delegate?.buildMenuDidSelectTower(type)
                    }
                    button.animatePress()
                }
                return true
            }
        }
        
        return false
    }
    
    func isInMenuArea(_ location: CGPoint) -> Bool {
        return location.x > 1234
    }
}

// MARK: - Tower Button

class TowerButton: SKNode {
    
    let towerType: TowerType
    
    private let background: SKShapeNode
    private let iconNode: SKShapeNode
    private let nameLabel: SKLabelNode
    private let costLabel: SKLabelNode
    
    private var isSelected = false
    private var isAffordable = true
    
    init(type: TowerType) {
        self.towerType = type
        
        // Background - smaller for 8 buttons
        background = SKShapeNode(rectOf: CGSize(width: 80, height: 68), cornerRadius: 6)
        background.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        background.strokeColor = type.color
        background.lineWidth = 2
        
        // Tower icon - smaller
        iconNode = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 4)
        iconNode.fillColor = type.color
        iconNode.strokeColor = .white
        iconNode.lineWidth = 1
        iconNode.position = CGPoint(x: 0, y: 10)
        
        // Tower name
        nameLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nameLabel.fontSize = 10
        nameLabel.fontColor = .white
        nameLabel.text = type.displayName
        nameLabel.position = CGPoint(x: 0, y: -12)
        
        // Cost
        costLabel = SKLabelNode(fontNamed: "Helvetica")
        costLabel.fontSize = 10
        costLabel.fontColor = .yellow
        costLabel.text = "$\(type.baseCost)"
        costLabel.position = CGPoint(x: 0, y: -24)
        
        super.init()
        
        addChild(background)
        addChild(iconNode)
        addChild(nameLabel)
        addChild(costLabel)
        
        // Add tower-specific icon
        addTowerIcon()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addTowerIcon() {
        let symbol = SKLabelNode(fontNamed: "Helvetica-Bold")
        symbol.fontSize = 14
        symbol.fontColor = .white
        symbol.horizontalAlignmentMode = .center
        symbol.verticalAlignmentMode = .center
        
        switch towerType {
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
        
        iconNode.addChild(symbol)
    }
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
        
        if selected {
            background.fillColor = towerType.color.withAlphaComponent(0.3)
            background.lineWidth = 3
        } else {
            background.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
            background.lineWidth = 2
        }
    }
    
    func setAffordable(_ affordable: Bool) {
        isAffordable = affordable
        
        alpha = affordable ? 1.0 : 0.5
        costLabel.fontColor = affordable ? .yellow : .gray
    }
    
    func animatePress() {
        let press = SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.05)
        ])
        run(press)
    }
    
    override func contains(_ point: CGPoint) -> Bool {
        return background.contains(point)
    }
}
