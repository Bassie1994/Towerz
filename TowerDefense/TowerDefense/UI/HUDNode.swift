import SpriteKit

/// Delegate for HUD interactions
protocol HUDNodeDelegate: AnyObject {
    func hudDidTapPause()
    func hudDidTapStartWave()
    func hudDidTapFastForward()
    func hudDidDropInTrash()
}

/// Heads-Up Display showing game state
final class HUDNode: SKNode {
    
    // MARK: - Properties
    
    weak var delegate: HUDNodeDelegate?
    
    private let livesLabel: SKLabelNode
    private let livesIcon: SKShapeNode
    private let moneyLabel: SKLabelNode
    private let moneyIcon: SKShapeNode
    private let waveLabel: SKLabelNode
    private let pauseButton: SKShapeNode
    private let startWaveButton: SKShapeNode
    private let startWaveLabel: SKLabelNode
    private let speedButton: SKShapeNode
    private let speedLabel: SKLabelNode
    
    private let hudBackground: SKShapeNode
    private let trashZone: SKShapeNode
    private let trashLabel: SKLabelNode
    
    private var speedMultiplier: CGFloat = 1.0  // 1x, 2x, or 4x
    private(set) var isTrashHighlighted = false
    
    // MARK: - Initialization
    
    override init() {
        // Background bar
        let hudWidth: CGFloat = 1334
        let hudHeight: CGFloat = 50
        hudBackground = SKShapeNode(rectOf: CGSize(width: hudWidth, height: hudHeight))
        hudBackground.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.9)
        hudBackground.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        hudBackground.lineWidth = 2
        
        // Lives display
        livesIcon = SKShapeNode(circleOfRadius: 10)
        livesIcon.fillColor = .healthBarRed
        livesIcon.strokeColor = .white
        livesIcon.lineWidth = 1
        
        livesLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        livesLabel.fontSize = 18
        livesLabel.fontColor = .white
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .center
        
        // Money display
        moneyIcon = SKShapeNode(circleOfRadius: 10)
        moneyIcon.fillColor = .yellow
        moneyIcon.strokeColor = .orange
        moneyIcon.lineWidth = 1
        
        moneyLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        moneyLabel.fontSize = 18
        moneyLabel.fontColor = .yellow
        moneyLabel.horizontalAlignmentMode = .left
        moneyLabel.verticalAlignmentMode = .center
        
        // Wave display
        waveLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        waveLabel.fontSize = 16
        waveLabel.fontColor = .white
        waveLabel.horizontalAlignmentMode = .center
        waveLabel.verticalAlignmentMode = .center
        
        // Pause button
        pauseButton = SKShapeNode(rectOf: CGSize(width: 40, height: 30), cornerRadius: 5)
        pauseButton.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        pauseButton.strokeColor = .white
        pauseButton.lineWidth = 1
        pauseButton.name = "pauseButton"
        
        // Start wave button
        startWaveButton = SKShapeNode(rectOf: CGSize(width: 120, height: 35), cornerRadius: 5)
        startWaveButton.fillColor = SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        startWaveButton.strokeColor = .white
        startWaveButton.lineWidth = 2
        startWaveButton.name = "startWaveButton"
        
        startWaveLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        startWaveLabel.fontSize = 14
        startWaveLabel.fontColor = .white
        startWaveLabel.horizontalAlignmentMode = .center
        startWaveLabel.verticalAlignmentMode = .center
        startWaveLabel.text = "Start Wave"
        
        // Speed button
        speedButton = SKShapeNode(rectOf: CGSize(width: 50, height: 30), cornerRadius: 5)
        speedButton.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        speedButton.strokeColor = .white
        speedButton.lineWidth = 1
        speedButton.name = "speedButton"
        
        speedLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        speedLabel.fontSize = 12
        speedLabel.fontColor = .white
        speedLabel.horizontalAlignmentMode = .center
        speedLabel.verticalAlignmentMode = .center
        speedLabel.text = "1x"
        
        // Trash zone (top-right corner)
        trashZone = SKShapeNode(rectOf: CGSize(width: 80, height: 80), cornerRadius: 10)
        trashZone.fillColor = SKColor(red: 0.4, green: 0.2, blue: 0.2, alpha: 0.8)
        trashZone.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
        trashZone.lineWidth = 3
        trashZone.name = "trashZone"
        
        trashLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        trashLabel.fontSize = 30
        trashLabel.fontColor = .white
        trashLabel.text = "🗑"
        trashLabel.verticalAlignmentMode = .center
        trashLabel.horizontalAlignmentMode = .center
        
        super.init()
        
        setupHUD()
        zPosition = GameConstants.ZPosition.hud.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupHUD() {
        // Position background at top
        hudBackground.position = CGPoint(x: 667, y: 725)
        addChild(hudBackground)
        
        // Lives (left side)
        livesIcon.position = CGPoint(x: 50, y: 725)
        addChild(livesIcon)
        
        livesLabel.position = CGPoint(x: 70, y: 725)
        addChild(livesLabel)
        
        // Money (next to lives)
        moneyIcon.position = CGPoint(x: 160, y: 725)
        addChild(moneyIcon)
        
        // Add coin symbol
        let coinSymbol = SKLabelNode(fontNamed: "Helvetica-Bold")
        coinSymbol.fontSize = 12
        coinSymbol.fontColor = .orange
        coinSymbol.text = "$"
        coinSymbol.horizontalAlignmentMode = .center
        coinSymbol.verticalAlignmentMode = .center
        moneyIcon.addChild(coinSymbol)
        
        moneyLabel.position = CGPoint(x: 180, y: 725)
        addChild(moneyLabel)
        
        // Wave info (center) - larger and more visible
        waveLabel.position = CGPoint(x: 500, y: 725)
        waveLabel.fontSize = 18
        addChild(waveLabel)
        
        // Start wave button - BIGGER and more prominent
        startWaveButton.position = CGPoint(x: 700, y: 725)
        startWaveButton.addChild(startWaveLabel)
        addChild(startWaveButton)
        
        // Speed button
        speedButton.position = CGPoint(x: 850, y: 725)
        speedButton.addChild(speedLabel)
        addChild(speedButton)
        
        // Pause button 
        pauseButton.position = CGPoint(x: 950, y: 725)
        
        // Pause icon (two vertical bars)
        let bar1 = SKShapeNode(rectOf: CGSize(width: 4, height: 15))
        bar1.fillColor = .white
        bar1.strokeColor = .clear
        bar1.position = CGPoint(x: -5, y: 0)
        pauseButton.addChild(bar1)
        
        let bar2 = SKShapeNode(rectOf: CGSize(width: 4, height: 15))
        bar2.fillColor = .white
        bar2.strokeColor = .clear
        bar2.position = CGPoint(x: 5, y: 0)
        pauseButton.addChild(bar2)
        
        addChild(pauseButton)
        
        // Heart icon in lives
        livesIcon.removeAllChildren()
        let heart = SKLabelNode(fontNamed: "Helvetica")
        heart.fontSize = 14
        heart.fontColor = .white
        heart.text = "♥"
        heart.horizontalAlignmentMode = .center
        heart.verticalAlignmentMode = .center
        livesIcon.addChild(heart)
        
        // Control panel (bottom-left)
        setupControlPanel()
        
        // Trash zone (bottom-right corner, visible and accessible)
        trashZone.position = CGPoint(x: 1260, y: 80)
        trashZone.zPosition = 100  // Above other elements
        trashZone.addChild(trashLabel)
        addChild(trashZone)
        
        // Add "SELL" text below trash
        let sellLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        sellLabel.fontSize = 12
        sellLabel.fontColor = SKColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
        sellLabel.text = "SELL"
        sellLabel.position = CGPoint(x: 1260, y: 25)
        addChild(sellLabel)
        
        // Add border/frame around trash zone for visibility
        let trashFrame = SKShapeNode(rectOf: CGSize(width: 90, height: 90), cornerRadius: 12)
        trashFrame.fillColor = .clear
        trashFrame.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.8)
        trashFrame.lineWidth = 2
        trashFrame.position = CGPoint(x: 1260, y: 80)
        trashFrame.zPosition = 99
        addChild(trashFrame)
        
        // Initial values
        updateLives(GameConstants.startingLives)
        updateMoney(GameConstants.startingMoney)
        updateWave(0, total: 10, active: false)
    }
    
    private func setupControlPanel() {
        // Floating control panel in bottom-left corner - with visible border
        let panelWidth: CGFloat = 180
        let panelHeight: CGFloat = 50
        
        let controlPanel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 8)
        controlPanel.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.95)
        controlPanel.strokeColor = SKColor(red: 0.4, green: 0.7, blue: 0.4, alpha: 1.0)
        controlPanel.lineWidth = 3
        controlPanel.position = CGPoint(x: 110, y: 80)  // Higher up, more visible
        controlPanel.name = "controlPanel"
        controlPanel.zPosition = 100  // Above other elements
        addChild(controlPanel)
        
        // Add "CONTROLS" label above panel
        let headerLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        headerLabel.fontSize = 9
        headerLabel.fontColor = .gray
        headerLabel.text = "CONTROLS"
        headerLabel.position = CGPoint(x: 0, y: 32)
        controlPanel.addChild(headerLabel)
        
        // Start button
        let startBtn = SKShapeNode(rectOf: CGSize(width: 50, height: 35), cornerRadius: 5)
        startBtn.fillColor = SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        startBtn.strokeColor = .white
        startBtn.lineWidth = 1
        startBtn.position = CGPoint(x: -55, y: 0)
        startBtn.name = "ctrlStartBtn"
        controlPanel.addChild(startBtn)
        
        let startLbl = SKLabelNode(fontNamed: "Helvetica-Bold")
        startLbl.fontSize = 10
        startLbl.fontColor = .white
        startLbl.text = "▶ START"
        startLbl.verticalAlignmentMode = .center
        startBtn.addChild(startLbl)
        
        // Pause button
        let pauseBtn = SKShapeNode(rectOf: CGSize(width: 40, height: 35), cornerRadius: 5)
        pauseBtn.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.2, alpha: 1.0)
        pauseBtn.strokeColor = .white
        pauseBtn.lineWidth = 1
        pauseBtn.position = CGPoint(x: 5, y: 0)
        pauseBtn.name = "ctrlPauseBtn"
        controlPanel.addChild(pauseBtn)
        
        let pauseLbl = SKLabelNode(fontNamed: "Helvetica-Bold")
        pauseLbl.fontSize = 14
        pauseLbl.fontColor = .white
        pauseLbl.text = "⏸"
        pauseLbl.verticalAlignmentMode = .center
        pauseBtn.addChild(pauseLbl)
        
        // Speed button
        let speedBtn = SKShapeNode(rectOf: CGSize(width: 40, height: 35), cornerRadius: 5)
        speedBtn.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0)
        speedBtn.strokeColor = .white
        speedBtn.lineWidth = 1
        speedBtn.position = CGPoint(x: 55, y: 0)
        speedBtn.name = "ctrlSpeedBtn"
        controlPanel.addChild(speedBtn)
        
        let speedLbl = SKLabelNode(fontNamed: "Helvetica-Bold")
        speedLbl.fontSize = 12
        speedLbl.fontColor = .white
        speedLbl.text = "1x"
        speedLbl.verticalAlignmentMode = .center
        speedLbl.name = "ctrlSpeedLbl"
        speedBtn.addChild(speedLbl)
    }
    
    // MARK: - Updates
    
    func updateLives(_ lives: Int) {
        livesLabel.text = "\(lives)"
        
        // Flash red when low
        if lives <= 5 {
            livesLabel.fontColor = .healthBarRed
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.3),
                SKAction.fadeAlpha(to: 1.0, duration: 0.3)
            ])
            livesIcon.run(SKAction.repeatForever(flash), withKey: "lowHealth")
        } else {
            livesLabel.fontColor = .white
            livesIcon.removeAction(forKey: "lowHealth")
            livesIcon.alpha = 1.0
        }
    }
    
    func updateMoney(_ money: Int) {
        moneyLabel.text = "\(money)"
        
        // Animate when money changes
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        moneyLabel.run(pop)
    }
    
    func updateWave(_ current: Int, total: Int, active: Bool) {
        if active {
            waveLabel.text = "Wave \(current)/\(total)"
            startWaveButton.isHidden = true
        } else if current >= total {
            waveLabel.text = "Victory!"
            startWaveButton.isHidden = true
        } else {
            waveLabel.text = "Wave \(current)/\(total)"
            startWaveButton.isHidden = false
            startWaveLabel.text = current == 0 ? "Start Wave 1" : "Next Wave"
        }
    }
    
    func setStartWaveEnabled(_ enabled: Bool) {
        startWaveButton.alpha = enabled ? 1.0 : 0.5
        startWaveButton.isUserInteractionEnabled = enabled
    }
    
    // MARK: - Touch Handling
    
    func handleTouch(at location: CGPoint) -> Bool {
        // Check control panel buttons (bottom-left)
        if let controlPanel = childNode(withName: "controlPanel") {
            let localPos = convert(location, to: controlPanel)
            
            // Start button in control panel
            if let startBtn = controlPanel.childNode(withName: "ctrlStartBtn") as? SKShapeNode {
                if startBtn.contains(localPos) {
                    delegate?.hudDidTapStartWave()
                    animateButtonPress(startBtn)
                    return true
                }
            }
            
            // Pause button in control panel
            if let pauseBtn = controlPanel.childNode(withName: "ctrlPauseBtn") as? SKShapeNode {
                if pauseBtn.contains(localPos) {
                    delegate?.hudDidTapPause()
                    animateButtonPress(pauseBtn)
                    return true
                }
            }
            
            // Speed button in control panel
            if let speedBtn = controlPanel.childNode(withName: "ctrlSpeedBtn") as? SKShapeNode {
                if speedBtn.contains(localPos) {
                    toggleFastForward()
                    delegate?.hudDidTapFastForward()
                    animateButtonPress(speedBtn)
                    return true
                }
            }
        }
        
        // Check trash zone
        if isInTrashZone(location) {
            delegate?.hudDidDropInTrash()
            return true
        }
        
        return false
    }
    
    private func toggleFastForward() {
        // Cycle through 1x → 2x → 4x → 1x
        if speedMultiplier == 1.0 {
            speedMultiplier = 2.0
        } else if speedMultiplier == 2.0 {
            speedMultiplier = 4.0
        } else {
            speedMultiplier = 1.0
        }
        
        // Update label
        speedLabel.text = "\(Int(speedMultiplier))x"
        
        // Update button color based on speed
        let buttonColor: SKColor
        switch speedMultiplier {
        case 2.0:
            buttonColor = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case 4.0:
            buttonColor = SKColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)
        default:
            buttonColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        }
        speedButton.fillColor = buttonColor
        
        // Sync control panel speed button
        if let controlPanel = childNode(withName: "controlPanel"),
           let speedBtn = controlPanel.childNode(withName: "ctrlSpeedBtn") as? SKShapeNode,
           let lbl = speedBtn.childNode(withName: "ctrlSpeedLbl") as? SKLabelNode {
            speedBtn.fillColor = buttonColor
            lbl.text = "\(Int(speedMultiplier))x"
        }
    }
    
    private func animateButtonPress(_ button: SKShapeNode) {
        let press = SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.05)
        ])
        button.run(press)
    }
    
    func getSpeedMultiplier() -> CGFloat {
        return speedMultiplier
    }
    
    // MARK: - Game Over / Victory
    
    func showGameOver() {
        let overlay = SKShapeNode(rectOf: CGSize(width: 400, height: 200), cornerRadius: 10)
        overlay.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.95)
        overlay.strokeColor = .healthBarRed
        overlay.lineWidth = 3
        overlay.position = CGPoint(x: 667, y: 375)
        overlay.zPosition = GameConstants.ZPosition.menu.rawValue
        overlay.name = "gameOverOverlay"
        
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.fontSize = 36
        title.fontColor = .healthBarRed
        title.text = "GAME OVER"
        title.position = CGPoint(x: 0, y: 40)
        overlay.addChild(title)
        
        let subtitle = SKLabelNode(fontNamed: "Helvetica")
        subtitle.fontSize = 18
        subtitle.fontColor = .white
        subtitle.text = "The enemies broke through!"
        subtitle.position = CGPoint(x: 0, y: 0)
        overlay.addChild(subtitle)
        
        let restartLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        restartLabel.fontSize = 16
        restartLabel.fontColor = .gray
        restartLabel.text = "Tap to restart"
        restartLabel.position = CGPoint(x: 0, y: -50)
        overlay.addChild(restartLabel)
        
        addChild(overlay)
        
        // Animate in
        overlay.setScale(0.1)
        overlay.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
    
    func showVictory() {
        let overlay = SKShapeNode(rectOf: CGSize(width: 400, height: 200), cornerRadius: 10)
        overlay.fillColor = SKColor(red: 0.1, green: 0.15, blue: 0.1, alpha: 0.95)
        overlay.strokeColor = .healthBarGreen
        overlay.lineWidth = 3
        overlay.position = CGPoint(x: 667, y: 375)
        overlay.zPosition = GameConstants.ZPosition.menu.rawValue
        overlay.name = "victoryOverlay"
        
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.fontSize = 36
        title.fontColor = .healthBarGreen
        title.text = "VICTORY!"
        title.position = CGPoint(x: 0, y: 40)
        overlay.addChild(title)
        
        let subtitle = SKLabelNode(fontNamed: "Helvetica")
        subtitle.fontSize = 18
        subtitle.fontColor = .white
        subtitle.text = "All waves defeated!"
        subtitle.position = CGPoint(x: 0, y: 0)
        overlay.addChild(subtitle)
        
        let restartLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        restartLabel.fontSize = 16
        restartLabel.fontColor = .gray
        restartLabel.text = "Tap to play again"
        restartLabel.position = CGPoint(x: 0, y: -50)
        overlay.addChild(restartLabel)
        
        addChild(overlay)
        
        // Animate in
        overlay.setScale(0.1)
        overlay.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
    
    // MARK: - Trash Zone
    
    func isInTrashZone(_ location: CGPoint) -> Bool {
        let trashFrame = CGRect(
            x: trashZone.position.x - 50,
            y: trashZone.position.y - 50,
            width: 100,
            height: 100
        )
        return trashFrame.contains(location)
    }
    
    func highlightTrashZone(_ highlight: Bool) {
        isTrashHighlighted = highlight
        
        if highlight {
            trashZone.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.95)
            trashZone.strokeColor = .white
            trashZone.lineWidth = 4
            trashLabel.fontColor = .white
        } else {
            trashZone.fillColor = SKColor(red: 0.4, green: 0.2, blue: 0.2, alpha: 0.8)
            trashZone.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
            trashZone.lineWidth = 3
            trashLabel.fontColor = .white
        }
    }
    
    func getTrashZonePosition() -> CGPoint {
        return trashZone.position
    }
}
