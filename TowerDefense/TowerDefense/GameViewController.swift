import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let view = self.view as? SKView ?? {
            let skView = SKView(frame: self.view.bounds)
            skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view = skView
            return skView
        }() as SKView? else { return }
        
        // Use a fixed scene size that fits the game design
        // Playfield is 24*48=1152 wide + 100 left margin = 1252 minimum
        // Playfield is 11*48=528 tall + 90 bottom margin = 618 minimum + HUD space
        let sceneSize = CGSize(width: 1334, height: 750)  // Standard iPad-ish landscape
        let scene = GameScene(size: sceneSize)
        scene.scaleMode = .aspectFit  // Maintain aspect ratio, letterbox if needed
        
        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        
        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        #endif
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update safe area insets when layout changes
        if let skView = self.view as? SKView,
           let scene = skView.scene as? GameScene {
            scene.safeAreaInsets = skView.safeAreaInsets
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .all
    }
}
