import Foundation
import SpriteKit

class Box: SKSpriteNode {
    
    override init(texture: SKTexture?,color: SKColor , size: CGSize) {
        
        super.init(texture: texture, color: color, size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
