import Foundation
import SpriteKit

class PlayerBullet: SKSpriteNode {
    
    // self destruct timer
    var timer = Timer()
    override init(texture: SKTexture?, color: SKColor, size: CGSize) {
        
        super.init(texture: texture, color: color, size: size)
        
        // self destruct after 2 seconds
        timer = .scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(deleteBullet), userInfo: nil, repeats: false)
        timer.fire()
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func deleteBullet() {
        self.removeFromParent()
    }
}
