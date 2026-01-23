import SpriteKit
import UIKit

/// Delegate for build menu interactions
protocol BuildMenuNodeDelegate: AnyObject {
    func buildMenuDidSelectTower(_ type: TowerType)
    func buildMenuDidDeselect()
    func canAfford(_ cost: Int) -> Bool
}

/// Tower selection menu - HORIZONTAL bar along the bottom of the screen
final class BuildMenuNode: SKNode {
    
    // MARK: - Properties
    
    weak var delegate: BuildMenuNodeDelegate?
    
    private var towerButtons: [TowerType: TowerButton] = [:]
    private var selectedTower: TowerType?

    private let menuBackground: SKShapeNode
    private let menuWidth: CGFloat
    private let menuHeight: CGFloat = 80
    private var layoutSize: CGSize = .zero
    
    private let moneyLabel: SKLabelNode
    private let moneyIcon: SKLabelNode
    
    // MARK: - Initialization
    
    init(sceneSize: CGSize, safeAreaInsets: UIEdgeInsets = .zero) {
        layoutSize = sceneSize
        // Calculate menu width based on scene size
        menuWidth = min(sceneSize.width - 40, 1200)
        
        // Background panel - horizontal bar at bottom of screen
        menuBackground = SKShapeNode(rectOf: CGSize(width: menuWidth, height: menuHeight), cornerRadius: 8)
        menuBackground.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 0.95)
        menuBackground.strokeColor = SKColor(red: 0.45, green: 0.45, blue: 0.6, alpha: 1.0)
        menuBackground.lineWidth = 3
        
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
        // Position menu along the bottom edge
        let bottomPadding: CGFloat = 15
        menuBackground.position = CGPoint(x: layoutSize.width / 2, y: menuHeight / 2 + bottomPadding)
        addChild(menuBackground)
        
        // Title on left
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.fontSize = 12
        title.fontColor = .gray
        title.text = "TOWERS:"
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -menuWidth/2 + 15, y: 0)
        menuBackground.addChild(title)

        // Create buttons for each tower type with proper spacing
        let towerTypes = TowerType.allCases
        let towerCount = CGFloat(towerTypes.count)
        let buttonWidth: CGFloat = 110  // Bigger buttons for clearer text
        let buttonHeight: CGFloat = 60
        let availableWidth = menuWidth - 90  // Leave margin for title
        let totalButtonWidth = buttonWidth * towerCount
        let spacing = max(5, (availableWidth - totalButtonWidth) / max(1, towerCount - 1))
        
        // Start position (centered in available area)
        let startX = -availableWidth / 2 + buttonWidth / 2 + 25

        for (index, towerType) in towerTypes.enumerated() {
            let button = TowerButton(type: towerType, buttonWidth: buttonWidth, buttonHeight: buttonHeight)
            let xPos = startX + CGFloat(index) * (buttonWidth + spacing)
            button.position = CGPoint(x: xPos, y: 0)
            button.name = "towerButton_\(towerType.rawValue)"
            menuBackground.addChild(button)
            towerButtons[towerType] = button
        }
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
        // Check if point is in the bottom build bar area
        let localPos = convert(location, to: menuBackground)
        let menuFrame = CGRect(x: -menuWidth/2, y: -menuHeight/2, width: menuWidth, height: menuHeight)
        return menuFrame.contains(localPos)
    }
}

// MARK: - Tower Button

private class TowerButton: SKNode {
    
    let towerType: TowerType
    private let background: SKShapeNode
    private let iconLabel: SKLabelNode
    private let nameLabel: SKLabelNode
    private let costLabel: SKLabelNode
    private let buttonWidth: CGFloat
    private let buttonHeight: CGFloat
    
    private var isAffordable = true
    private var isButtonSelected = false
    
    init(type: TowerType, buttonWidth: CGFloat = 110, buttonHeight: CGFloat = 60) {
        self.towerType = type
        self.buttonWidth = buttonWidth
        self.buttonHeight = buttonHeight
        
        // Button size
        background = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 8)
        background.fillColor = type.color.withAlphaComponent(0.3)
        background.strokeColor = type.color
        background.lineWidth = 2
        
        // Icon/symbol - centered at left side of button
        iconLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        iconLabel.fontSize = 22
        iconLabel.fontColor = .white
        iconLabel.verticalAlignmentMode = .center
        iconLabel.horizontalAlignmentMode = .center
        iconLabel.position = CGPoint(x: -buttonWidth/2 + 22, y: 0)
        
        // Tower name - to the right of icon, larger font
        nameLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nameLabel.fontSize = 14
        nameLabel.fontColor = .white
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -buttonWidth/2 + 40, y: 10)
        
        // Cost - below name, larger font
        costLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        costLabel.fontSize = 12
        costLabel.fontColor = .yellow
        costLabel.verticalAlignmentMode = .center
        costLabel.horizontalAlignmentMode = .left
        costLabel.position = CGPoint(x: -buttonWidth/2 + 40, y: -10)
        
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
        case .mine:
            symbol.text = "💣"
        case .splash:
            symbol.text = "◎"
        case .laser:
            symbol.text = "🎯"
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
        let buttonFrame = CGRect(x: -buttonWidth/2, y: -buttonHeight/2, width: buttonWidth, height: buttonHeight)
        return buttonFrame.contains(localPoint)
    }
}
