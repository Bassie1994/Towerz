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
        
        let sceneSize = view.bounds.size
        let scene = GameScene(size: sceneSize)
        scene.safeAreaInsets = view.safeAreaInsets
        scene.scaleMode = .resizeFill
        
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
