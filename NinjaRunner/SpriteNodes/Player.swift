import Foundation
import SpriteKit

class Player: SKSpriteNode {
   
    // initialize actions
    private var jumpAction:SKAction?
    private var runAction:SKAction?

    // initialize other var's
    var isGrounded:Bool = false
    var isRunning:Bool = true
    private var minSpeed:CGFloat = 9
    private var maxSpeed:CGFloat = 13
    
    // required:
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // initialize player object
    init (imageNamed:String, isTop:Bool) {
        
        // set player sprite
        let imageTexture = SKTexture(imageNamed: imageNamed)
        super.init(texture: imageTexture, color:SKColor.clear, size: imageTexture.size() )
        
        // set player physics
        let body:SKPhysicsBody = SKPhysicsBody(circleOfRadius: imageTexture.size().width / 2.25, center:CGPoint(x: 0, y: 0))
        body.isDynamic = true
        body.affectedByGravity = true
        body.allowsRotation = false
        body.restitution = 0.0
        if (isTop) {
            body.categoryBitMask = BodyType.playerTop.rawValue
        } else {
            body.categoryBitMask = BodyType.player.rawValue
        }
        body.contactTestBitMask = BodyType.enemy.rawValue | BodyType.platformObject.rawValue | BodyType.groundTop.rawValue  | BodyType.waterTop.rawValue | BodyType.bullet.rawValue | BodyType.ground.rawValue  | BodyType.water.rawValue
        body.collisionBitMask = BodyType.platformObject.rawValue | BodyType.groundTop.rawValue | BodyType.ground.rawValue | BodyType.water.rawValue | BodyType.waterTop.rawValue
        body.friction = 0.9 //0 is like glass, 1 is like sandpaper to walk on
        self.physicsBody = body
        
        // set up actions
        setUpRun()
        setUpJump()
        startRun()
    }
    
    func update(score: Double) {
        
        // move player each frame (cut speed in half if running 120fps)
        let is120 = UIScreen.main.maximumFramesPerSecond == 120
        let xIncrease: CGFloat = (is120 ? score * 0.004 : score * 0.008)
        let minSpeedCalc = (is120 ? minSpeed/2 : minSpeed)
        let maxSpeedCalc = (is120 ? maxSpeed/2 : maxSpeed)
        if (xIncrease + minSpeedCalc) > maxSpeedCalc {
            self.position = CGPoint(x: self.position.x + maxSpeedCalc, y: self.position.y)
        } else {
            self.position = CGPoint(x: self.position.x + minSpeedCalc + xIncrease, y: self.position.y)
        }
    }
    
    func setUpRun() {
        
        // set up player animation for run
        let atlas = SKTextureAtlas (named: "Ninja")
        var array = [String]()
        for i in 1 ... 10 {
            let nameString = String(format: "run%i", i)
            array.append(nameString)
        }
        
        // create another array this time with SKTexture as the type (textures being the .png images)
        var atlasTextures:[SKTexture] = []
        for i in 0 ..< array.count{
            
            let texture:SKTexture = atlas.textureNamed( array[i] )
            atlasTextures.insert(texture, at:i)
            
        }
        let atlasAnimation = SKAction.animate(with: atlasTextures, timePerFrame: 2.0/60, resize: true , restore:false )
        runAction =  SKAction.repeatForever(atlasAnimation)
    }
    
    
    func setUpJump() {
        
        // set up jump animation
        let atlas = SKTextureAtlas (named: "Ninja")
        var array = [String]()
        for i in 1 ... 10 {
            let nameString = String(format: "jump%i", i)
            array.append(nameString)
        }

        // create another array this time with SKTexture as the type (textures being the .png images)
        var atlasTextures:[SKTexture] = []
        for i in 0 ..< array.count {
            let texture:SKTexture = atlas.textureNamed( array[i] )
            atlasTextures.insert(texture, at:i)
        }

        let atlasAnimation = SKAction.animate(with: atlasTextures, timePerFrame: 1.0/20, resize: true , restore:false )
        jumpAction =  SKAction.repeatForever(atlasAnimation)
    }
    
    func startRun(){
        
        // start run animation
        isRunning = true
        self.removeAction(forKey: "jumpKey")
        self.run(runAction! , withKey:"runKey")
    }
    
    func startJump(){
        
        // start jump animation
        self.removeAction(forKey: "runKey")
        self.run(jumpAction!, withKey:"jumpKey" )
        isRunning = false
    }
    
    func jump() {
        
        // set up jump
        isGrounded = false
        startJump()
    }
    
    func moveUp() {
        self.position.y += 5
    }
}
