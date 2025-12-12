import SpriteKit

/// Shows tower placement preview with validation feedback
final class PlacementPreviewNode: SKNode {
    
    // MARK: - Properties
    
    private var currentTowerType: TowerType?
    private var currentGridPosition: GridPosition?
    private var isValid: Bool = false
    
    private let previewNode: SKShapeNode
    private let rangeIndicator: SKShapeNode
    private let invalidLabel: SKLabelNode
    private let gridHighlight: SKShapeNode
    
    // MARK: - Initialization
    
    override init() {
        // Preview tower shape
        let size = GameConstants.cellSize - 4
        previewNode = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 4)
        previewNode.strokeColor = .white
        previewNode.lineWidth = 2
        previewNode.alpha = 0.7
        
        // Range indicator
        rangeIndicator = SKShapeNode()
        rangeIndicator.fillColor = SKColor.white.withAlphaComponent(0.1)
        rangeIndicator.strokeColor = SKColor.white.withAlphaComponent(0.3)
        rangeIndicator.lineWidth = 2
        
        // Invalid placement label
        invalidLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        invalidLabel.fontSize = 12
        invalidLabel.fontColor = .white
        invalidLabel.horizontalAlignmentMode = .center
        invalidLabel.verticalAlignmentMode = .top
        invalidLabel.position = CGPoint(x: 0, y: -size / 2 - 10)
        
        // Grid cell highlight
        gridHighlight = SKShapeNode(rectOf: CGSize(width: GameConstants.cellSize, height: GameConstants.cellSize))
        gridHighlight.fillColor = .clear
        gridHighlight.lineWidth = 2
        gridHighlight.zPosition = GameConstants.ZPosition.grid.rawValue + 1
        
        super.init()
        
        addChild(rangeIndicator)
        addChild(gridHighlight)
        addChild(previewNode)
        addChild(invalidLabel)
        
        isHidden = true
        zPosition = GameConstants.ZPosition.rangeIndicator.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Preview Management
    
    func startPreview(towerType: TowerType) {
        currentTowerType = towerType
        
        // Update appearance for tower type
        previewNode.fillColor = towerType.color.withAlphaComponent(0.5)
        
        // Update range indicator
        let range = getTowerRange(for: towerType)
        let rangePath = CGPath(ellipseIn: CGRect(x: -range, y: -range, width: range * 2, height: range * 2), transform: nil)
        rangeIndicator.path = rangePath
        
        isHidden = false
    }
    
    func updatePosition(gridPosition: GridPosition, isValid: Bool, invalidReason: String?) {
        currentGridPosition = gridPosition
        self.isValid = isValid
        
        // Update position
        position = gridPosition.toWorldPosition()
        
        // Update validity visual
        if isValid {
            previewNode.fillColor = currentTowerType?.color.withAlphaComponent(0.5) ?? .validPlacement
            previewNode.strokeColor = .white
            gridHighlight.strokeColor = .validPlacement
            rangeIndicator.strokeColor = SKColor.white.withAlphaComponent(0.3)
            rangeIndicator.fillColor = SKColor.white.withAlphaComponent(0.1)
            invalidLabel.isHidden = true
        } else {
            previewNode.fillColor = .invalidPlacement
            previewNode.strokeColor = .healthBarRed
            gridHighlight.strokeColor = .invalidPlacement
            rangeIndicator.strokeColor = SKColor.red.withAlphaComponent(0.3)
            rangeIndicator.fillColor = SKColor.red.withAlphaComponent(0.1)
            
            if let reason = invalidReason {
                invalidLabel.text = reason
                invalidLabel.isHidden = false
                
                // Add background to label
                let bgWidth = invalidLabel.frame.width + 10
                let bg = SKShapeNode(rectOf: CGSize(width: bgWidth, height: 18), cornerRadius: 3)
                bg.fillColor = SKColor.black.withAlphaComponent(0.7)
                bg.strokeColor = .clear
                bg.position = CGPoint(x: 0, y: invalidLabel.position.y - 6)
                bg.zPosition = -1
                bg.name = "labelBg"
                
                // Remove old background
                childNode(withName: "labelBg")?.removeFromParent()
                addChild(bg)
            } else {
                invalidLabel.isHidden = true
                childNode(withName: "labelBg")?.removeFromParent()
            }
        }
        
        // Pulse animation
        previewNode.removeAction(forKey: "pulse")
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.3),
            SKAction.scale(to: 0.95, duration: 0.3)
        ])
        previewNode.run(SKAction.repeatForever(pulse), withKey: "pulse")
    }
    
    func endPreview() {
        currentTowerType = nil
        currentGridPosition = nil
        isHidden = true
        childNode(withName: "labelBg")?.removeFromParent()
    }
    
    // MARK: - Helpers
    
    func getCurrentPlacement() -> (type: TowerType, position: GridPosition)? {
        guard let type = currentTowerType, let position = currentGridPosition, isValid else {
            return nil
        }
        return (type, position)
    }
    
    private func getTowerRange(for type: TowerType) -> CGFloat {
        switch type {
        case .wall: return WallTower.stats.range
        case .machineGun: return MachineGunTower.stats.range
        case .cannon: return CannonTower.stats.range
        case .slow: return SlowTower.stats.range
        case .buff: return BuffTower.stats.range
        case .shotgun: return ShotgunTower.stats.range
        case .splash: return SplashTower.stats.range
        case .laser: return LaserTower.stats.range
        case .antiAir: return AntiAirTower.stats.range
        }
    }
    
    // MARK: - Animation
    
    func animatePlacementSuccess() {
        let flash = SKShapeNode(rectOf: CGSize(width: GameConstants.cellSize, height: GameConstants.cellSize))
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0.8
        flash.zPosition = 100
        parent?.addChild(flash)
        flash.position = position
        
        let animation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        flash.run(animation)
    }
    
    func animatePlacementFailed() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 5, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        ])
        previewNode.run(shake)
        
        // Flash red
        let flashRed = SKAction.sequence([
            SKAction.run { self.previewNode.fillColor = .red },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { self.previewNode.fillColor = .invalidPlacement }
        ])
        previewNode.run(flashRed)
    }
}
