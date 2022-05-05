import Foundation
import SpriteKit
import CoreMedia

class LevelUnit:SKNode {
    
    // initialize level var's
    private var imageName:String = ""
    private var backgroundSprite:SKSpriteNode = SKSpriteNode()
    var levelUnitWidth:CGFloat = 0
    var levelUnitHeight:CGFloat = 0
    private var theType:LevelType = LevelType.ground
    private var numberOfObjectsInLevel:UInt32 = 0
    private var offscreenCounter:Int = 0
    private var maxObjectsInLevelUnit:UInt32 = 2
    var isFirstUnit:Bool = false
    private var isTop = false
    private var score = 0.0
    
    // required:
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init (isTop: Bool, score: Double) {
        self.isTop = isTop
        self.score = score
        super.init()
    }
    
    func setUpLevel(){
        
        // choose random level
        let diceRoll = arc4random_uniform(5)
        
        if (diceRoll == 0) {
            imageName = "Background1"
        } else if (diceRoll == 1) {
            imageName = "Background2"
        } else if (diceRoll == 2) {
            imageName = "Background3"
        } else if (diceRoll == 3) {
            imageName = "Background4"
        } else if (diceRoll == 4) {
            
            // first unit cannot be water type
            if (isFirstUnit == false) {
                let randomWaterBackground = Bool.random()
                
                // choose 1 of 2 water backgrounds
                if (randomWaterBackground) {
                    imageName = "WaterBackground1"
                } else {
                    imageName = "WaterBackground2"
                }
                theType = LevelType.water
            } else {
                imageName = "Background4"
            }
        }
        
        // set up level
        let theSize:CGSize = CGSize(width: levelUnitWidth, height: levelUnitHeight)
        let tex:SKTexture = SKTexture(imageNamed: imageName)
        backgroundSprite = SKSpriteNode(texture: tex, color: SKColor.clear, size: theSize)
        
        //add sprite to level
        self.addChild(backgroundSprite)
        self.name = "levelUnit"
        self.position = CGPoint(x: backgroundSprite.size.width / 2, y: 0)
        
        // level physics:
        let newSize:CGSize = CGSize(width: backgroundSprite.size.width, height: 10)
        backgroundSprite.physicsBody = SKPhysicsBody(rectangleOf: newSize, center:CGPoint(x: 0, y: self.position.y - 340))
        backgroundSprite.physicsBody!.isDynamic = false
        backgroundSprite.physicsBody!.restitution = 0
        
        
        // create ceiling if top unit
        if (isTop) {
            let ceilingSprite = SKNode()
            ceilingSprite.physicsBody = SKPhysicsBody(rectangleOf: newSize, center:CGPoint(x: 0, y: self.position.y - 340 + (levelUnitHeight / 2) - 50))
            ceilingSprite.physicsBody!.isDynamic = false
            ceilingSprite.physicsBody!.restitution = 0
            //add sprite to level
            self.addChild(ceilingSprite)
            self.position = CGPoint(x: backgroundSprite.size.width / 2, y: 0)
        }
        
        // if level is water type:
        if (theType == LevelType.water) {
            if (isTop) {
                backgroundSprite.physicsBody!.categoryBitMask = BodyType.waterTop.rawValue
                backgroundSprite.physicsBody!.contactTestBitMask = BodyType.waterTop.rawValue
            } else {
                backgroundSprite.physicsBody!.categoryBitMask = BodyType.water.rawValue
                backgroundSprite.physicsBody!.contactTestBitMask = BodyType.water.rawValue
            }
            if (isTop) {
                self.zPosition = 98
            } else {
                self.zPosition = 99
            }
            
            // build 4 random platforms
            for platforms in 1...4 {
                let platform:Box = Box(imageNamed: "Platform")
                let newSize:CGSize = CGSize(width: platform.size.width, height: 5)
                
                platform.physicsBody = SKPhysicsBody(rectangleOf: newSize, center:CGPoint(x: 0, y: 50))
                platform.physicsBody!.categoryBitMask = BodyType.platformObject.rawValue
                
                platform.physicsBody!.friction = 1
                platform.physicsBody!.isDynamic = false
                platform.physicsBody!.affectedByGravity = false
                platform.physicsBody!.restitution = 0.0
                platform.physicsBody!.allowsRotation = false
                platform.zPosition = 100
                
                var ypos:Int
                
                if (platforms == 1) {
                    
                    // first platform must be reachable by jump
                    ypos = -350
                } else {
                    ypos = Int.random(in: -350..<(-200))
                }
                platform.position = CGPoint(x: CGFloat(platforms * 450) + CGFloat.random(in: 0..<50) - CGFloat(levelUnitWidth / 2) - CGFloat(200), y: CGFloat(ypos))
                addChild(platform)
            }
            
        } else if (theType == LevelType.ground){
            if (isTop) {
                backgroundSprite.physicsBody!.categoryBitMask = BodyType.groundTop.rawValue
                backgroundSprite.physicsBody!.contactTestBitMask = BodyType.groundTop.rawValue
            } else {
                backgroundSprite.physicsBody!.categoryBitMask = BodyType.ground.rawValue
                backgroundSprite.physicsBody!.contactTestBitMask = BodyType.ground.rawValue
            }
        }
        
        // no obstacles on first level
        if ( isFirstUnit == false && theType == LevelType.ground) {
            
            createObstacle()
        }
    }
    
    func createObstacle() {
        if (theType == LevelType.ground) {
            
            // choose random level type
            let diceRoll = arc4random_uniform(2)
            
            if ( diceRoll == 0) { // turret level
                
                // set up turret object
                let turret:Turret = Turret(texture: SKTexture(imageNamed: "turret"), color: .blue , size: CGSize(width: 160, height: 130))
                turret.zPosition = 200
                turret.position = CGPoint(x: 1100 - (levelUnitWidth / 2), y: -280)
                turret.name = "turret"
                addChild(turret)
                
            } else if ( diceRoll == 1) { // boxes level
                
                var boxAmount:UInt32 = 0
                
                // fewer stacks when player is running too fast to jump in time
                var maxStacks = 3
                if (score > 200) {
                    maxStacks = 2
                } else if (score > 400) {
                    maxStacks = 1
                }
                
                // create x stacks
                for stack in 1...maxStacks {
                    
                    // set max box height
                    var maxBoxHeight:UInt32 = 4
                    if (boxAmount >= 3) { // if prev height was 3-4, change to 2
                        maxBoxHeight = 2
                    }
                    
                    // choose random type of stack
                    boxAmount = arc4random_uniform(maxBoxHeight)
                    
                    // height is always 1
                    boxAmount += 1
                    
                    var xpos = 400 * Float(stack)
                    if (maxStacks == 3) {
                        xpos += Float.random(in: 0..<50)
                    } else if (maxStacks == 2) {
                        xpos += Float.random(in: 400..<450)
                    } else if (maxStacks == 1) {
                        xpos += Float.random(in: 600..<650)
                    }
                    var boxStartingLevel = arc4random_uniform(2)
                    if boxStartingLevel == 1 {
                        boxStartingLevel += 2
                        boxAmount += 2
                    }
                    if boxStartingLevel == 0 {
                        boxStartingLevel += 1
                    }
                    
                    for boxes in boxStartingLevel...boxAmount {
                        var texture:SKTexture
                        if (isTop) {
                            texture = SKTexture(imageNamed: "boxR")
                        } else {
                            texture = SKTexture(imageNamed: "boxB")
                        }
                        let box:Box = Box(texture: texture, size: CGSize(width: 45, height: 45))
                        box.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 20), center: CGPoint (x: 0, y: 0))
                        box.physicsBody!.categoryBitMask = BodyType.enemy.rawValue
                        box.physicsBody!.contactTestBitMask = BodyType.enemy.rawValue | BodyType.ground.rawValue | BodyType.player.rawValue | BodyType.bullet.rawValue | BodyType.playerTop.rawValue | BodyType.groundTop.rawValue
                        box.physicsBody!.friction = 1
                        box.physicsBody!.isDynamic = false
                        box.physicsBody!.affectedByGravity = false
                        box.physicsBody!.restitution = 0.0
                        box.physicsBody!.allowsRotation = false
                        
                        box.zPosition = 2
                        box.position = CGPoint( x: CGFloat(xpos) - (levelUnitWidth / 2),  y: CGFloat(45 * boxes) - 350)
                        if (isTop) {
                            box.name = "red"
                        } else {
                            box.name = "blue"
                        }
                        addChild(box)
                    }
                }
            }
        }
    }
}
