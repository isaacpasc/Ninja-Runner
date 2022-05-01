import Foundation
import SpriteKit

class Turret: SKSpriteNode {
    
    private var isTop = true
    private var fired = false
    private var timer = Timer()
    private var chargeTimer = Timer()
    private let shootingMissleSound = SKAction.playSoundFileNamed("shootingMissleSound.wav", waitForCompletion: true)
    
    override init(texture: SKTexture?, color: SKColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        timer = .scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(fireBullet), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func chargeBullet() {
        isTop = .random()
        let shotCharge = SKEmitterNode(fileNamed: "TurretCharge.sks")
        if (isTop) {
            shotCharge?.position = CGPoint(x: (self.position.x - 250) , y: (self.position.y + 285 + 50))
        } else {
            shotCharge?.position = CGPoint(x: (self.position.x - 250) , y: (self.position.y + 285))
        }
        addChild(shotCharge!)
    }
    
    @objc func fireBullet() {
        
        // for some reason first shot is bugged so wait for second shot
        if (fired && !self.isPaused) {
            
            // play shooting sound
            if (UserDefaults.standard.bool(forKey: "volume")) {
                run(shootingMissleSound)
            }
            
            // create bullet:
            let bulletTexture:SKTexture
            if (self.color == .blue) {
                bulletTexture = SKTexture(imageNamed: "kunaiB")
            } else {
                bulletTexture = SKTexture(imageNamed: "kunaiR")
            }
            let bullet:PlayerBullet = PlayerBullet(texture: bulletTexture, size: CGSize(width: 16, height: 80))
            bullet.zRotation = CGFloat(GLKMathDegreesToRadians(270))
            if isTop {
                bullet.position = CGPoint(x: self.position.x - 250, y: self.position.y + 285 + 50)
            } else {
                bullet.position = CGPoint(x: self.position.x - 250, y: self.position.y + 285)
            }
            bullet.zPosition = 91
            let body:SKPhysicsBody = SKPhysicsBody(circleOfRadius: bulletTexture.size().width / 3.0, center:CGPoint(x: 0, y: 0))
            body.isDynamic = true
            body.affectedByGravity = false
            body.allowsRotation = false
            body.restitution = 0.0
            body.friction = 1
            body.collisionBitMask = 0
            body.contactTestBitMask = BodyType.player.rawValue | BodyType.ground.rawValue | BodyType.enemy.rawValue | BodyType.playerTop.rawValue | BodyType.groundTop.rawValue
            body.categoryBitMask = BodyType.bullet.rawValue
            bullet.physicsBody = body
            bullet.name = "bullet"
            bullet.physicsBody?.velocity.dx = -350
            
            // set up shot fired particle effect
            let shotBlast = SKEmitterNode(fileNamed: "TurretShot.sks")
            shotBlast?.position = CGPoint(x: bullet.position.x + 20 , y: bullet.position.y)
            addChild(shotBlast!)
            addChild(bullet)
            chargeTimer = .scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(chargeBullet), userInfo: nil, repeats: false)
            
        } else {
            // this is first shot, trigger next shot
            fired = true
        }
    }
}
