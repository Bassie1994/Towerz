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
        
        let scene = GameScene(size: CGSize(width: 1334, height: 750))
        scene.scaleMode = .aspectFill
        
        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        
        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        #endif
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
