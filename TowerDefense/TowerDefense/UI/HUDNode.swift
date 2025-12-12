import SpriteKit

/// Delegate for HUD interactions
protocol HUDNodeDelegate: AnyObject {
    func hudDidTapPause()
    func hudDidTapStartWave()
    func hudDidTapFastForward()
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
    
    private var isFastForward = false
    
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
        
        // Wave info (center)
        waveLabel.position = CGPoint(x: 667, y: 725)
        addChild(waveLabel)
        
        // Start wave button
        startWaveButton.position = CGPoint(x: 1050, y: 725)
        startWaveButton.addChild(startWaveLabel)
        addChild(startWaveButton)
        
        // Speed button
        speedButton.position = CGPoint(x: 1180, y: 725)
        speedButton.addChild(speedLabel)
        addChild(speedButton)
        
        // Pause button (right side)
        pauseButton.position = CGPoint(x: 1280, y: 725)
        
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
        
        // Initial values
        updateLives(GameConstants.startingLives)
        updateMoney(GameConstants.startingMoney)
        updateWave(0, total: 10, active: false)
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
        // Check pause button
        if pauseButton.contains(convert(location, to: hudBackground.parent!)) ||
           pauseButton.frame.contains(CGPoint(x: location.x - pauseButton.position.x + 667, y: location.y)) {
            let globalPos = CGPoint(x: location.x, y: location.y)
            if pauseButton.contains(globalPos) || location.distance(to: pauseButton.position) < 30 {
                delegate?.hudDidTapPause()
                animateButtonPress(pauseButton)
                return true
            }
        }
        
        // Check start wave button
        if !startWaveButton.isHidden {
            if location.distance(to: startWaveButton.position) < 70 {
                delegate?.hudDidTapStartWave()
                animateButtonPress(startWaveButton)
                return true
            }
        }
        
        // Check speed button
        if location.distance(to: speedButton.position) < 35 {
            toggleFastForward()
            delegate?.hudDidTapFastForward()
            return true
        }
        
        return false
    }
    
    private func toggleFastForward() {
        isFastForward = !isFastForward
        speedLabel.text = isFastForward ? "2x" : "1x"
        speedButton.fillColor = isFastForward ?
            SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0) :
            SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        animateButtonPress(speedButton)
    }
    
    private func animateButtonPress(_ button: SKShapeNode) {
        let press = SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.05)
        ])
        button.run(press)
    }
    
    func isFastForwardEnabled() -> Bool {
        return isFastForward
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
}
