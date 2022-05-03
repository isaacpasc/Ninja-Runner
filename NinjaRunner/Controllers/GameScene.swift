// created on 4.20.22

import SpriteKit
import Foundation
import AVFAudio
import GameKit

// collision types:
enum BodyType:UInt32 {
    
    case player = 1 // player
    case playerTop = 2 // top player
    case platformObject = 4 // platform
    case enemy = 8 // enemy
    case ground = 16 // floor
    case groundTop = 32 // floor top
    case water = 64 // water
    case waterTop = 128 // water top
    case bullet = 256 // bullet
}

// type of generated section
enum LevelType:UInt32 {
    
    case ground, water
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var gameModel: TournModel!
    
    // achievements
    private var achievements:[GKAchievement] = []
    
    // audio controller
    private var footstepSoundPlayer:AVAudioPlayer?
    private var backgroundSoundPlayer:AVAudioPlayer?
    private var soundPlayed1 = true
    private var soundPlayed2 = true
    private var soundPlayed3 = true
    private let confettiSound = SKAction.playSoundFileNamed("Confetti.wav", waitForCompletion: true)
    private let poofSound = SKAction.playSoundFileNamed("Poof.wav", waitForCompletion: true)
    private let stabSound = SKAction.playSoundFileNamed("Stab.wav", waitForCompletion: true)
    private let oofSound = SKAction.playSoundFileNamed("Oof.wav", waitForCompletion: true)
    private let breakSound = SKAction.playSoundFileNamed("Break.wav", waitForCompletion: true)
    private let burnSound = SKAction.playSoundFileNamed("Burn.wav", waitForCompletion: true)
    private let gettingFasterSound = SKAction.playSoundFileNamed("gettingFasterSound.wav", waitForCompletion: true)
    private let jumpSound1 = SKAction.playSoundFileNamed("jumpSound1.wav", waitForCompletion: true)
    private let jumpSound2 = SKAction.playSoundFileNamed("jumpSound2.wav", waitForCompletion: true)
    private let jumpSound3 = SKAction.playSoundFileNamed("jumpSound3.wav", waitForCompletion: true)
    private let click = SKAction.playSoundFileNamed("Click.wav", waitForCompletion: true)
    
    // level generation var's
    private var levelUnitCounter:CGFloat = 0
    private var levelUnitCounterTop:CGFloat = 0
    private var levelUnitWidth:CGFloat = 0
    private var levelUnitHeight:CGFloat = 0
    private var initialUnits:Int = 2
    
    // screen dimensions
    private var screenWidth:CGFloat = 0
    private var screenHeight:CGFloat = 0
    
    // world node to move level towards player
    private let worldNode:SKNode = SKNode()
    
    // background node
    private let backgroundNode:SKNode = SKNode()
    
    // player's character
    private let thePlayer:Player = Player(imageNamed: "run1", isTop: false)
    private let thePlayerTop:Player = Player(imageNamed: "run1", isTop: true)
    
    // looping gackground images
    private let loopingBG:SKSpriteNode = SKSpriteNode(imageNamed: "looping_BG1")
    private let loopingBG2:SKSpriteNode = SKSpriteNode(imageNamed: "looping_BG1")
    
    // indicates touching+holding
    private var playerJump = false
    private var playerTopJump = false
    private var playerTopJumpTimer = Timer()
    private var playerJumpTimer = Timer()
    
    // track when player is bottom or top..single player only
    private var isOnTop = false
    
    // score var's/labels
    private var scoreLabel = SKLabelNode(fontNamed: "Party Confetti")
    private var highscoreLabel = SKLabelNode(fontNamed: "Party Confetti")
    private var scoreData = 0.0
    private var savedData = UserDefaults.standard
    
    // online stuff
    private var scoreLabels: [SKLabelNode] = []
    private var displayDeathNodes: [SKLabelNode] = []
    private var displayWinNodes: [SKLabelNode] = []
    private var shape = SKShapeNode()
    private var totalDead = 0
    private var myIndex = 0
    private var didReset = false
    private var me = playerNode(place: 0, isDead: false, score: 0, name: GKLocalPlayer.local.displayName, wins: 0, wantsToPlayAgain: false)
    
    // set up pause button label
    private let pauseButton = SKSpriteNode()
    private let pauseMenu = SKSpriteNode()
    private let resumeButton = SKSpriteNode()
    private let restartButton = SKSpriteNode()
    private let quitButton = SKSpriteNode()
    private let playButton = SKSpriteNode()
    private let exitButton = SKSpriteNode()
    
    // is player dead?
    private var isDead:Bool = false
    
    // where player starts
    private let startingPosition:CGPoint = CGPoint(x: -50, y: -200)
    private let startingPositionTop:CGPoint = CGPoint(x: -50, y: 250)
    
    private let footSteps = SKEmitterNode(fileNamed: "FootSteps.sks")
    private let footStepsTop = SKEmitterNode(fileNamed: "FootSteps.sks")
    
    // set confetti view
    private var confettiView: SAConfettiView?
    
    private var achievementsLoaded = false
    private var teleportNum = 0
    
    @objc func resumingGame(_ sender: Notification) {
        
        if !isDead { // pause menu
            
            
            
        } else if isDead { // game over menu
            
            // clear menu items
            self.enumerateChildNodes(withName: "playButton") {
                node, stop  in
                node.removeFromParent()
            }
            self.enumerateChildNodes(withName: "exitButton") {
                node, stop  in
                node.removeFromParent()
            }
            
            // reset
            restart()
        }
    }
    
    @objc func exitingGame(_ sender: Notification) {
        if Mode.type == 2 {
            
            if (UserDefaults.standard.bool(forKey: "volume")) {
                // stop footstep sounds
                if let footstepSoundPlayer = footstepSoundPlayer, footstepSoundPlayer.isPlaying {
                    footstepSoundPlayer.pause()
                }
                
                // stop background sounds
                if let backgroundSoundPlayer = backgroundSoundPlayer, backgroundSoundPlayer.isPlaying {
                    backgroundSoundPlayer.pause()
                }
            }
            // stop confetti
            if let confettiView = confettiView {
                if confettiView.isActive() {
                    confettiView.stopConfetti()
                }
            }
            
            if let view = self.view {
                // Load the SKScene from 'MenuScene.sks'
                if let scene = SKScene(fileNamed: "MenuScene") {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .fill
                    
                    // Present the scene
                    let transition:SKTransition = SKTransition.fade(withDuration: 1)
                    view.presentScene(scene, transition: transition)
                }
                
                view.ignoresSiblingOrder = true
                view.preferredFramesPerSecond = 120
            }
        }
        
        if !isDead && worldNode.isPaused { // in pause menu
            
            // clear menu items
            self.enumerateChildNodes(withName: "resumeButton") {
                node, stop  in
                node.removeFromParent()
            }
            self.enumerateChildNodes(withName: "restartButton") {
                node, stop  in
                node.removeFromParent()
            }
            self.enumerateChildNodes(withName: "quitButton") {
                node, stop  in
                node.removeFromParent()
            }
            self.enumerateChildNodes(withName: "PausedMenu") {
                node, stop  in
                node.removeFromParent()
            }
            
            // start player movement
            thePlayer.physicsBody!.isDynamic = true
            thePlayerTop.physicsBody!.isDynamic = true
        } else if isDead && worldNode.isPaused { // game over menu
            
            // clear menu items
            self.enumerateChildNodes(withName: "playButton") {
                node, stop  in
                node.removeFromParent()
            }
            self.enumerateChildNodes(withName: "exitButton") {
                node, stop  in
                node.removeFromParent()
            }
            
            // reset
            restart()
        }
    }
    
    override func didMove(to view: SKView) {
        
        
        // online - create list of all players
        if (Mode.type == 2) {
            guard let match = Mode.matchData else { return }
            match.delegate = self
            gameModel = TournModel(players: [], gameIsInSession: true, prevWinner: "")
            savePlayers()
        }
        
        // achievemets
        if (Auth.isAuth) {
            Task {
                do {
                    try achievements = await loadAchievement()
                    achievementsLoaded = true
                } catch {
                    print("error loading achievements")
                }
            }
        }
        
        // allow multitouch
        view.isMultipleTouchEnabled = true
        UIView.appearance().isMultipleTouchEnabled = true
        
        confettiView = SAConfettiView(frame: self.view!.bounds)
        if let confettiView = confettiView {
            self.view?.addSubview(confettiView)
        }
        
        // create exit/open notif
        NotificationCenter.default.addObserver(self, selector: #selector(exitingGame(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumingGame(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if (UserDefaults.standard.bool(forKey: "volume")) {
            // set up footstep audio
            if let path = Bundle.main.path(forResource: "footstepsSound", ofType: "wav") {
                do {
                    footstepSoundPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    footstepSoundPlayer?.numberOfLoops = -1
                    footstepSoundPlayer?.enableRate = true
                    footstepSoundPlayer?.rate = 2.0 // playback speed
                } catch {
                    print("error loading footstep sounds")
                }
            }
            
            // start background sounds
            playBackgroundSound()
            
        }
        
        // set default highscore of 0 if none is saved
        savedData.register(defaults: ["highscore": 0])
        savedData.register(defaults: ["highscoreSplitScreen": 0])
        
        // set background/screen
        self.backgroundColor = SKColor.black
        screenWidth = self.view!.bounds.width * 2
        screenHeight = self.view!.bounds.height * 2
        levelUnitWidth = screenWidth
        levelUnitHeight = screenHeight
        
        // physics gravity
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx:0, dy:-25)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(worldNode)
        addChild(backgroundNode)
        
        // player is placed in worldNode
        worldNode.addChild(thePlayer)
        thePlayer.position = startingPosition
        thePlayer.zPosition = 101
        if Mode.type == 1 { // split screen
            worldNode.addChild(thePlayerTop)
        }
        thePlayerTop.position = startingPositionTop
        thePlayerTop.zPosition = 102
        
        // set up score label
        scoreLabel.text = "Score: \(Int(scoreData))"
        scoreLabel.zPosition = 1000
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        if Mode.type == 2 {
            scoreLabel.position = CGPoint(x: -740.0 + 40, y: 375.0)
            scoreLabel.fontSize = 50
        } else {
            scoreLabel.position = CGPoint(x: -740.0 + 40, y: 335.0)
            scoreLabel.fontSize = 40
        }
        addChild(scoreLabel)
        
        // set up highscore label
        if Mode.type == 0 {
            highscoreLabel.text = "Highscore: " + String(savedData.integer(forKey: "highscore"))
        } else if Mode.type == 1 {
            highscoreLabel.text = "Highscore: " + String(savedData.integer(forKey: "highscoreSplitScreen"))
        }
        highscoreLabel.fontSize = 40
        highscoreLabel.zPosition = 1000
        highscoreLabel.horizontalAlignmentMode = .left
        highscoreLabel.verticalAlignmentMode = .top
        highscoreLabel.position = CGPoint(x: -740.0 + 40, y: 375.0)
        addChild(highscoreLabel)
        
        if Mode.type != 2 {
        
            // create pause menu
            let pauseMenuTexture = SKTexture(imageNamed: "PausedMenu")
            pauseMenu.texture = pauseMenuTexture
            pauseMenu.zPosition = 1001
            pauseMenu.size = CGSize(width: 1400 * 0.7, height: 1080 * 0.7)
            pauseMenu.position = CGPoint(x: 0, y: 0)
            pauseMenu.name = "PausedMenu"
            let yOffset = -20.0
        
            // create resume button
            let resumeButtonTexture = SKTexture(imageNamed: "ResumeButton")
            resumeButton.texture = resumeButtonTexture
            resumeButton.zPosition = 1002
            resumeButton.size = CGSize(width: 500 * 0.7, height: 200 * 0.7)
            resumeButton.position = CGPoint(x: 0, y: (150 * 0.7) * 1.5 + yOffset)
            resumeButton.name = "resumeButton"
            
            // create restart button
            let restartButtonTexture = SKTexture(imageNamed: "RestartButton")
            restartButton.texture = restartButtonTexture
            restartButton.zPosition = 1003
            restartButton.size = CGSize(width: 500 * 0.7, height: 200 * 0.7)
            restartButton.position = CGPoint(x: 0, y: 0 + yOffset)
            restartButton.name = "restartButton"
            
            // create quit button
            let quitButtonTexture = SKTexture(imageNamed: "ExitButton")
            quitButton.texture = quitButtonTexture
            quitButton.zPosition = 1004
            quitButton.size = CGSize(width: 500 * 0.7, height: 200 * 0.7)
            quitButton.position = CGPoint(x: 0, y: -(150 * 0.7) * 1.5 + yOffset)
            quitButton.name = "quitButton"
        }
        
        // set up pause button label
        let pauseTexture = SKTexture(image: UIImage(systemName: "pause.fill")!)
        let exitOnlineTexture = SKTexture(image: UIImage(systemName: "house.fill")!)
        if Mode.type == 2 {
            pauseButton.texture = exitOnlineTexture
            pauseButton.size = CGSize(width: 30 + 20, height: 40 + 20)
        } else {
            pauseButton.texture = pauseTexture
            pauseButton.size = CGSize(width: 30 + 20, height: 50 + 20)
        }
        pauseButton.zPosition = 1000
        pauseButton.position = CGPoint(x: 660, y: 340)
        pauseButton.name = "pauseButton"
        addChild(pauseButton)
        
        // create leaderboard background
        shape.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 500, height: 512), cornerRadius: 64).cgPath
        shape.position = CGPoint(x: frame.midX - 800, y: frame.midY - 280)
        shape.fillColor = UIColor.darkGray
        shape.strokeColor = UIColor.white
        shape.zPosition = 900
        shape.lineWidth = 6
        
        // create play button
        let playButtonTexture = SKTexture(imageNamed: "PlayButton")
        playButton.texture = playButtonTexture
        playButton.zPosition = 1006
        playButton.size = CGSize(width: 500 * 0.7, height: 200 * 0.7)
        playButton.position = CGPoint(x: -(150 * 0.7) * 1.5, y: 0)
        playButton.name = "playButton"
        
        // create exit button
        let exitButtonTexture = SKTexture(imageNamed: "ExitButton")
        exitButton.texture = exitButtonTexture
        exitButton.zPosition = 1005
        exitButton.size = CGSize(width: 500 * 0.7, height: 200 * 0.7)
        exitButton.position = CGPoint(x: (150 * 0.7) * 1.5, y: 0)
        exitButton.name = "exitButton"
        
        // generate 2 levels in front of player
        addLevelUnits()
        
        // add looping backgrounds
        backgroundNode.addChild(loopingBG)
        backgroundNode.addChild(loopingBG2)
        
        // set backgrounds in background
        loopingBG.zPosition = -200
        loopingBG2.zPosition = -200
        
        // begin looping backgrounds
        startLoopingBackground()
        
        worldNode.addChild(footSteps!)
        worldNode.addChild(footStepsTop!)
        
    }
    
    func startLoopingBackground() {
        
        resetLoopingBackground()
        
        // action sequence to move backgrounds
        let move:SKAction = SKAction.moveBy(x: -loopingBG2.size.width, y: 0, duration: 20)
        let moveBack:SKAction = SKAction.moveBy(x: loopingBG2.size.width, y: 0, duration: 0)
        let seq:SKAction = SKAction.sequence([move, moveBack])
        let `repeat`:SKAction = SKAction.repeatForever(seq)
        loopingBG.run(`repeat`)
        loopingBG2.run(`repeat`)
    }
    
    @objc func endJumpTop() {
        playerTopJump = false
    }
    @objc func endJump() {
        playerJump = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>,with event: UIEvent?) {
        /* Called when a touch begins */
        for touch in (touches) {
            let location = touch.location(in: self)
            if(location.x < 0){ // touch left
                playerJump = false
                playerJumpTimer.invalidate()
            } else { // touch right
                playerTopJump = false
                playerTopJumpTimer.invalidate()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,with event: UIEvent?){
        for touch in touches {
            let location = touch.location(in: self)
            let nodeTouched = atPoint(location)
            if worldNode.isPaused { // intacting w menu
                if nodeTouched.name == "resumeButton" {
                    pausePlayBullets(willPause: false)
                    worldNode.isPaused = false
                    backgroundNode.isPaused = false
                    
                    // start player movement
                    thePlayer.physicsBody!.isDynamic = true
                    thePlayerTop.physicsBody!.isDynamic = true
                    
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    // start footstep sounds
                    if let footstepSoundPlayer = footstepSoundPlayer, !footstepSoundPlayer.isPlaying {
                        footstepSoundPlayer.play()
                    }
                    
                    // start background sounds
                    if let backgroundSoundPlayer = backgroundSoundPlayer, !backgroundSoundPlayer.isPlaying {
                        backgroundSoundPlayer.play()
                    }
                    
                    // clear menu items
                    restartButton.removeFromParent()
                    resumeButton.removeFromParent()
                    quitButton.removeFromParent()
                    pauseMenu.removeFromParent()
                    
                } else if nodeTouched.name == "restartButton" || nodeTouched.name == "playButton" {
                    
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    // restart
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    if Mode.type != 2 {
                        
                        
                        if (UserDefaults.standard.bool(forKey: "volume")) {
                            // start footstep sounds
                            if let footstepSoundPlayer = footstepSoundPlayer, !footstepSoundPlayer.isPlaying {
                                footstepSoundPlayer.play()
                            }
                            
                            // start background sounds
                            if let backgroundSoundPlayer = backgroundSoundPlayer, !backgroundSoundPlayer.isPlaying {
                                backgroundSoundPlayer.play()
                            }
                        }
                        worldNode.isPaused = false
                        backgroundNode.isPaused = false
                        // clear menu items
                        restartButton.removeFromParent()
                        resumeButton.removeFromParent()
                        quitButton.removeFromParent()
                        pauseMenu.removeFromParent()
                        exitButton.removeFromParent()
                        playButton.removeFromParent()
                        restart()
                    } else {
                        
                        playButton.removeFromParent()
                        gameModel.players[myIndex].wantsToPlayAgain = true
                        me.wantsToPlayAgain = true
                        sendData()
                    }
                    
                } else if nodeTouched.name == "quitButton" || nodeTouched.name == "exitButton" {
                    
                    
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    
                    // stop confetti
                    if let confettiView = confettiView {
                        if confettiView.isActive() {
                            confettiView.stopConfetti()
                        }
                    }
                    
                    if let view = self.view {
                        // Load the SKScene from 'MenuScene.sks'
                        if let scene = SKScene(fileNamed: "MenuScene") {
                            // Set the scale mode to scale to fit the window
                            scene.scaleMode = .fill
                            
                            // Present the scene
                            let transition:SKTransition = SKTransition.fade(withDuration: 1)
                            view.presentScene(scene, transition: transition)
                        }
                        
                        view.ignoresSiblingOrder = true
                        view.preferredFramesPerSecond = 120
                    }
                }
                
            } else if nodeTouched.name == "pauseButton" { // pause button pressed, or exit online match
                if Mode.type == 2 {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        // stop footstep sounds
                        if let footstepSoundPlayer = footstepSoundPlayer, footstepSoundPlayer.isPlaying {
                            footstepSoundPlayer.pause()
                        }
                        
                        // stop background sounds
                        if let backgroundSoundPlayer = backgroundSoundPlayer, backgroundSoundPlayer.isPlaying {
                            backgroundSoundPlayer.pause()
                        }
                    }
                    if let view = self.view {
                        // Load the SKScene from 'MenuScene.sks'
                        if let scene = SKScene(fileNamed: "MenuScene") {
                            // Set the scale mode to scale to fit the window
                            scene.scaleMode = .fill
                            
                            // Present the scene
                            let transition:SKTransition = SKTransition.fade(withDuration: 1)
                            view.presentScene(scene, transition: transition)
                        }
                        
                        view.ignoresSiblingOrder = true
                        view.preferredFramesPerSecond = 120
                    }
                } else {
                    pausePlayBullets(willPause: true)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    worldNode.isPaused = true
                    backgroundNode.isPaused = true
                    
                    // stop player movement
                    thePlayer.physicsBody!.isDynamic = false
                    thePlayerTop.physicsBody!.isDynamic = false
                    
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        // stop footstep sounds
                        if let footstepSoundPlayer = footstepSoundPlayer, footstepSoundPlayer.isPlaying {
                            footstepSoundPlayer.pause()
                        }
                        
                        // stop background sounds
                        if let backgroundSoundPlayer = backgroundSoundPlayer, backgroundSoundPlayer.isPlaying {
                            backgroundSoundPlayer.pause()
                        }
                    }
                    
                    // add menu items
                    addChild(pauseMenu)
                    addChild(resumeButton)
                    addChild(restartButton)
                    addChild(quitButton)
                }
                
            } else if(location.x < 0){ // touch left
                if (!isDead) {
                    
                    if Mode.type == 1 || Mode.type == 0 || Mode.type == 2 { // split screen, or single player, or online
                        // player must be touching platform or floor
                        if thePlayer.isGrounded {
                            
                            // player jumps
                            thePlayer.jump()
                            thePlayer.moveUp()
                            
                            if (UserDefaults.standard.bool(forKey: "volume")) {
                                // play random jump sound effect
                                let jumpSound = arc4random_uniform(2)
                                if (jumpSound == 0) {
                                    run(jumpSound1)
                                } else if (jumpSound == 1) {
                                    run(jumpSound2)
                                } else if (jumpSound == 2) {
                                    run(jumpSound3)
                                }
                            }
                            playerJump = true
                            playerJumpTimer = .scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(endJump), userInfo: nil, repeats: false)
                        }
                    }
                }
            } else { // touch right
                
                if (!isDead) {
                    
                    if Mode.type == 0 || Mode.type == 2 { // single player, or online
                        guard let body = thePlayer.physicsBody else { return }
                        emitter(body, emitter: "Glow.sks")
                        if (UserDefaults.standard.bool(forKey: "volume")) {
                            run(poofSound)
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        if thePlayer.position.y > 0 {
                            isOnTop = false
                            thePlayer.position.y -= (levelUnitHeight / 2) - 50
                        } else {
                            isOnTop = true
                            thePlayer.position.y += (levelUnitHeight / 2) - 50
                        }
                        emitter(body, emitter: "Glow.sks")
                        teleportNum += 1
                    } else if Mode.type == 1 { // splitscreen
                        // player must be touching platform or floor
                        if thePlayerTop.isGrounded {
                            
                            // player jumps
                            thePlayerTop.jump()
                            thePlayerTop.moveUp()
                            
                            if (UserDefaults.standard.bool(forKey: "volume")) {
                                // play random jump sound effect
                                let jumpSound = arc4random_uniform(2)
                                if (jumpSound == 0) {
                                    run(jumpSound1)
                                } else if (jumpSound == 1) {
                                    run(jumpSound2)
                                } else if (jumpSound == 2) {
                                    run(jumpSound3)
                                }
                            }
                            playerTopJump = true
                            playerTopJumpTimer = .scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(endJumpTop), userInfo: nil, repeats: false)
                        }
                    }
                }
            }
        }
    }
    
    // restart level after death
    func resetLevel() {
        
        // remove levelunit children from world node
        worldNode.enumerateChildNodes(withName: "levelUnit" ) {
            node, stop in
            node.removeFromParent()
        }
        
        // reset levelunit counter
        levelUnitCounter = 0
        levelUnitCounterTop = 0
        
        if (UserDefaults.standard.bool(forKey: "volume")) {
            // reset sounds
            soundPlayed1 = true
            soundPlayed2 = true
            soundPlayed3 = true
        }
        
        // generate new levels
        addLevelUnits()
    }
    
    // how many levelunits should be generated
    func addLevelUnits() {
        
        for _ in 0 ..< initialUnits {
            
            createLevelUnit()
            createLevelUnitTop()
        }
    }
    
    
    
    // generate a top level
    func createLevelUnitTop() {
        
        // set loaction based on which unit is created
        let yLocation:CGFloat = (levelUnitHeight / 2) - 50
        let xLocation:CGFloat = levelUnitCounter * levelUnitWidth
        
        // create level object
        let levelUnit:LevelUnit = LevelUnit(isTop: true, score: scoreData)
        
        // add level to world node
        worldNode.addChild(levelUnit)
        levelUnit.zPosition = -2
        levelUnit.levelUnitWidth = levelUnitWidth
        levelUnit.levelUnitHeight = levelUnitHeight
        
        // check if unit is first
        if (levelUnitCounter < 2) {
            
            levelUnit.isFirstUnit = true
        }
        
        // set up level
        levelUnit.setUpLevel()
        levelUnit.position = CGPoint( x: xLocation , y: yLocation)
        
        // increase counter for next level
        levelUnitCounter += 1
    }
    
    // generate a level
    func createLevelUnit() {
        
        if (UserDefaults.standard.bool(forKey: "volume")) {
            // play getting faster sound
            if (scoreData >= 100 && soundPlayed1) {
                run(gettingFasterSound)
                footstepSoundPlayer?.rate = 3.0 // increase footstep sound speed
                soundPlayed1 = false
            }
            if (scoreData >= 500 && soundPlayed2) {
                run(gettingFasterSound)
                footstepSoundPlayer?.rate = 4.0 // increase footstep sound speed
                soundPlayed2 = false
            }
            if (scoreData >= 1000 && soundPlayed3) {
                run(gettingFasterSound)
                footstepSoundPlayer?.rate = 5.0 // increase footstep sound speed
                soundPlayed3 = false
            }
        }
        
        // set loaction based on which unit is created
        let yLocation:CGFloat = 0
        let xLocation:CGFloat = levelUnitCounterTop * levelUnitWidth
        
        // create level object
        let levelUnit:LevelUnit = LevelUnit(isTop: false, score: scoreData)
        
        // add level to world node
        worldNode.addChild(levelUnit)
        levelUnit.zPosition = -1
        levelUnit.levelUnitWidth = levelUnitWidth
        levelUnit.levelUnitHeight = levelUnitHeight
        
        // check if unit is first
        if (levelUnitCounterTop < 2) {
            
            levelUnit.isFirstUnit = true
        }
        
        // set up level
        levelUnit.setUpLevel()
        levelUnit.position = CGPoint( x: xLocation , y: yLocation)
        
        // increase counter for next level
        levelUnitCounterTop += 1
    }
    
    // remove what player cant see
    func clearNodes() {
        
        // check all levels in world node
        worldNode.enumerateChildNodes(withName: "levelUnit") {
            node, stop in
            
            let nodeLocation:CGPoint = self.convert(node.position, from: self.worldNode)
            
            // if node is off screen
            if ( nodeLocation.x < -(self.screenWidth / 2) - self.levelUnitWidth ) {
                
                // remove node off screen
                node.removeFromParent()
            }
        }
    }
    
    // stop moving bullets when game is paused
    func pausePlayBullets(willPause: Bool) {
        
        // check all levels in world node
        worldNode.enumerateChildNodes(withName: "levelUnit") {
            node, stop in
            
            // check all turrets in level
            node.enumerateChildNodes(withName: "turret") {
                node, stop in
                
                // check all bullets in turret
                node.enumerateChildNodes(withName: "bullet") {
                    node, stop in
                    
                    if (willPause) {
                        node.physicsBody?.isDynamic = false
                    } else {
                        node.physicsBody?.isDynamic = true
                        node.physicsBody?.velocity.dx = -350
                    }
                }
            }
        }
        
    }
    
    private func allWantToRestart() -> Bool {
        for i in gameModel.players.indices {
            if !gameModel.players[i].wantsToPlayAgain {
                return false
            }
        }
        return true
    }
    
    private func isLastAlive() -> Bool {
        for i in gameModel.players.indices {
            if !gameModel.players[i].isDead && i != myIndex {
                return false
            }
        }
        return true
    }
    
    // called before each frame is rendered
    override func update(_ currentTime: TimeInterval) {
        
        // online stuff
        if Mode.type == 2 {
            
            if gameModel.players.count > 1 {
                for i in gameModel.players.indices {
                    if gameModel.gameIsInSession && !gameModel.players[i].isDead && !gameModel.players[i].wantsToPlayAgain {
                        displayDeathNodes[i].fontColor = .white
                    } else if gameModel.players[i].isDead && !gameModel.players[i].wantsToPlayAgain {
                        displayDeathNodes[i].fontColor = .red
                    } else if gameModel.players[i].isDead && gameModel.players[i].wantsToPlayAgain && !gameModel.gameIsInSession {
                        displayDeathNodes[i].fontColor = .green
                    }
                }
            }
            // I am the last player alive
            if !isDead && isLastAlive() {
                gameModel.players[myIndex].wins = gameModel.players[myIndex].wins + 1
                me.wins = gameModel.players[myIndex].wins
                gameModel.prevWinner = gameModel.players[myIndex].name
                gameModel.gameIsInSession = false
                // start up confetti
                if let confettiView = confettiView {
                    confettiView.startConfetti()
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(confettiSound)
                    }
                }
                presentGameOverScreen(playSound: confettiSound)
            }
            
            if allWantToRestart() {
                resetOnlineWorld()
            }
        }
        
        
        // check if player is alive and game is not paused
        if (!isDead && !worldNode.isPaused) {
            
            let nextTier:CGFloat = (levelUnitCounter * levelUnitWidth) - (CGFloat(initialUnits) * levelUnitWidth)
            
            // check if player is far enough to generate new levels
            if (thePlayer.position.x > nextTier) {
                
                // generate levels
                createLevelUnit()
                createLevelUnitTop()
            }
            
            // clear nodes off screen
            clearNodes()
            
            // jump when touch + hold
            if (playerJump) {
                thePlayer.physicsBody?.velocity.dy = 1000
            }
            if (playerTopJump) {
                thePlayerTop.physicsBody?.velocity.dy = 1000
            }
            
            // in case of falling off map bug
            if (thePlayerTop.position.y < -10000 || thePlayer.position.y < -10000 || thePlayerTop.position.y > 10000 || thePlayer.position.y > 10000) {
                run(oofSound)
                restart()
            }
            
            // increase score each frame (max 60)
            if UIScreen.main.maximumFramesPerSecond == 120 {
                scoreData += 0.004 + (scoreData * 0.00025)
            } else {
                scoreData += 0.008 + (scoreData * 0.0005)
            }
            scoreLabel.text = "Score: \(Int(scoreData))"
            
            // update living player
            thePlayer.update(score: scoreData)
            thePlayerTop.update(score: scoreData)
            
            // update footstep sound
            if (UserDefaults.standard.bool(forKey: "volume")) {
                if (Mode.type == 0) {
                    if (thePlayer.isGrounded) {
                        // start footstep audio
                        if let footstepSoundPlayer = footstepSoundPlayer, !footstepSoundPlayer.isPlaying {
                            footstepSoundPlayer.play()
                        }
                    } else {
                        // stop footstep audio
                        if let footstepSoundPlayer = footstepSoundPlayer, footstepSoundPlayer.isPlaying {
                            footstepSoundPlayer.pause()
                        }
                    }
                } else if (Mode.type == 1) {
                    if (thePlayer.isGrounded || thePlayerTop.isGrounded) {
                        // start footstep audio
                        if let footstepSoundPlayer = footstepSoundPlayer, !footstepSoundPlayer.isPlaying {
                            footstepSoundPlayer.play()
                        }
                    } else {
                        // stop footstep audio
                        if let footstepSoundPlayer = footstepSoundPlayer, footstepSoundPlayer.isPlaying {
                            footstepSoundPlayer.pause()
                        }
                    }
                }
            }
            
            if (Mode.type == 0 || Mode.type == 1) {
                // if player is touching ground
                if (thePlayer.isGrounded) {
                    
                    // move footstep particle to follow player
                    footSteps!.position = CGPoint(x: thePlayer.position.x - 20,y: thePlayer.position.y - 40)
                } else {
                    // move footstep particle off screen
                    footSteps!.position = CGPoint(x: -1000, y: -1000)
                }
            }
            if (Mode.type == 1) {
                // if top player is touching ground
                if (thePlayerTop.isGrounded) {
                    
                    // move footstep particle to follow player
                    footStepsTop!.position = CGPoint(x: thePlayerTop.position.x - 20,y: thePlayerTop.position.y - 40)
                } else {
                    // move footstep particle off screen
                    footStepsTop!.position = CGPoint(x: -1000, y: -1000)
                }
            }
        }
    }
    
    override func didSimulatePhysics() {
        
        self.centerOnNode(thePlayer)
    }
    
    // center cam on player
    func centerOnNode(_ node:SKNode) {
        
        let cameraPositionInScene:CGPoint = self.convert(node.position, from: worldNode)
        
        // -200 on x to let player see more of oncoming enemies
        worldNode.position = CGPoint(x: worldNode.position.x - cameraPositionInScene.x - 200, y:0 )
    }
    
    // collision handling:
    func didBegin(_ contact: SKPhysicsContact) {
        
        // enemy and player
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemy.rawValue ) {
            if contact.bodyB.node?.name == "red" {
                emitter(contact.bodyA, emitter: "RedBox.sks")
            } else {
                emitter(contact.bodyA, emitter: "BlueBox.sks")
            }
            contact.bodyB.node?.removeFromParent()
            presentGameOverScreen(playSound: breakSound)
            emitter(contact.bodyA, emitter: "Death.sks")
            contact.bodyA.node?.isHidden = true
            
        } else if (contact.bodyA.categoryBitMask == BodyType.enemy.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            if contact.bodyA.node?.name == "red" {
                emitter(contact.bodyB, emitter: "RedBox.sks")
            } else {
                emitter(contact.bodyB, emitter: "BlueBox.sks")
            }
            contact.bodyA.node?.removeFromParent()
            presentGameOverScreen(playSound: breakSound)
            emitter(contact.bodyB, emitter: "Death.sks")
            contact.bodyB.node?.isHidden = true
            
        }
        
        // enemy and top player
        if (contact.bodyA.categoryBitMask == BodyType.playerTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemy.rawValue ) {
            if contact.bodyB.node?.name == "red" {
                emitter(contact.bodyA, emitter: "RedBox.sks")
            } else {
                emitter(contact.bodyA, emitter: "BlueBox.sks")
            }
            contact.bodyB.node?.removeFromParent()
            presentGameOverScreen(playSound: breakSound)
            emitter(contact.bodyA, emitter: "Death.sks")
            contact.bodyA.node?.isHidden = true
            
        } else if (contact.bodyA.categoryBitMask == BodyType.enemy.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTop.rawValue ) {
            if contact.bodyA.node?.name == "red" {
                emitter(contact.bodyB, emitter: "RedBox.sks")
            } else {
                emitter(contact.bodyB, emitter: "BlueBox.sks")
            }
            contact.bodyA.node?.removeFromParent()
            presentGameOverScreen(playSound: breakSound)
            emitter(contact.bodyB, emitter: "Death.sks")
            contact.bodyB.node?.isHidden = true
            
        }
        
        // water and player
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.water.rawValue ) {
            presentGameOverScreen(playSound: burnSound)
            emitter(contact.bodyA, emitter: "Death.sks")
            contact.bodyA.node?.isHidden = true
        } else if (contact.bodyA.categoryBitMask == BodyType.water.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            presentGameOverScreen(playSound: burnSound)
            emitter(contact.bodyB, emitter: "Death.sks")
            contact.bodyB.node?.isHidden = true
        }
        
        // top water and top player
        if (contact.bodyA.categoryBitMask == BodyType.playerTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.waterTop.rawValue ) {
            presentGameOverScreen(playSound: burnSound)
            emitter(contact.bodyA, emitter: "Death.sks")
            contact.bodyA.node?.isHidden = true
        } else if (contact.bodyA.categoryBitMask == BodyType.waterTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTop.rawValue ) {
            presentGameOverScreen(playSound: burnSound)
            emitter(contact.bodyB, emitter: "Death.sks")
            contact.bodyB.node?.isHidden = true
        }
        
        if (isOnTop) {
            // top water and player
            if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.waterTop.rawValue ) {
                presentGameOverScreen(playSound: burnSound)
                emitter(contact.bodyA, emitter: "Death.sks")
                contact.bodyA.node?.isHidden = true
            } else if (contact.bodyA.categoryBitMask == BodyType.waterTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
                presentGameOverScreen(playSound: burnSound)
                emitter(contact.bodyB, emitter: "Death.sks")
                contact.bodyB.node?.isHidden = true
            }
        }
        
        // player and bullet
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.bullet.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            contact.bodyB.node?.removeFromParent()
            presentGameOverScreen(playSound: stabSound)
            emitter(contact.bodyA, emitter: "Death.sks")
            contact.bodyA.node?.isHidden = true
        } else if (contact.bodyA.categoryBitMask == BodyType.bullet.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            contact.bodyA.node?.removeFromParent()
            presentGameOverScreen(playSound: stabSound)
            emitter(contact.bodyB, emitter: "Death.sks")
            contact.bodyB.node?.isHidden = true
        }
        
        // top player and bullet
        if (contact.bodyA.categoryBitMask == BodyType.playerTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.bullet.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            contact.bodyB.node?.removeFromParent()
            presentGameOverScreen(playSound: stabSound)
            emitter(contact.bodyA, emitter: "Death.sks")
            contact.bodyA.node?.isHidden = true
        } else if (contact.bodyA.categoryBitMask == BodyType.bullet.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTop.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            contact.bodyA.node?.removeFromParent()
            presentGameOverScreen(playSound: stabSound)
            emitter(contact.bodyB, emitter: "Death.sks")
            contact.bodyB.node?.isHidden = true
        }
        
        // bullet and ground
        if (contact.bodyA.categoryBitMask == BodyType.bullet.rawValue  && contact.bodyB.categoryBitMask == BodyType.ground.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.ground.rawValue  && contact.bodyB.categoryBitMask == BodyType.bullet.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // bullet and top ground
        if (contact.bodyA.categoryBitMask == BodyType.bullet.rawValue  && contact.bodyB.categoryBitMask == BodyType.groundTop.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.groundTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.bullet.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // bullet and box
        if (contact.bodyA.categoryBitMask == BodyType.bullet.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemy.rawValue ) {
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.enemy.rawValue  && contact.bodyB.categoryBitMask == BodyType.bullet.rawValue ) {
            contact.bodyB.node?.removeFromParent()
        }
        
        // if the player hits the ground
        if (contact.bodyA.categoryBitMask == BodyType.ground.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            
            thePlayer.physicsBody?.isDynamic = true
            
            // if player animation isnt running
            if ( thePlayer.isRunning == false) {
                
                // start running
                thePlayer.startRun()
            }
            
            // player is grounded
            thePlayer.isGrounded = true
        } else if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.ground.rawValue ) {
            thePlayer.physicsBody?.isDynamic = true
            if ( thePlayer.isRunning == false) {
                thePlayer.startRun()
            }
            thePlayer.isGrounded = true
        }
        
        // check if on Platform Object
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.platformObject.rawValue ) {
            
            // on platform and grounded
            thePlayer.isGrounded = true
            
            // set players current platform
            thePlayer.physicsBody?.isDynamic = true
            
            // if player animation isnt running
            if ( thePlayer.isRunning == false) {
                
                // start running
                thePlayer.startRun()
            }
        } else if (contact.bodyA.categoryBitMask == BodyType.platformObject.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            thePlayer.isGrounded = true
            thePlayer.physicsBody?.isDynamic = true
            if ( thePlayer.isRunning == false) {
                thePlayer.startRun()
            }
        }
        
        // if the top player hits the top ground
        if (contact.bodyA.categoryBitMask == BodyType.groundTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTop.rawValue ) {
            
            thePlayerTop.physicsBody?.isDynamic = true
            
            // if player animation isnt running
            if ( thePlayerTop.isRunning == false) {
                
                // start running
                thePlayerTop.startRun()
            }
            
            // player is grounded
            thePlayerTop.isGrounded = true
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.groundTop.rawValue ) {
            thePlayerTop.physicsBody?.isDynamic = true
            if ( thePlayerTop.isRunning == false) {
                thePlayerTop.startRun()
            }
            thePlayerTop.isGrounded = true
        }
        
        // check if on Platform Object
        if (contact.bodyA.categoryBitMask == BodyType.playerTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.platformObject.rawValue ) {
            
            // on platform and grounded
            thePlayerTop.isGrounded = true
            
            // set players current platform
            thePlayerTop.physicsBody?.isDynamic = true
            
            // if player animation isnt running
            if ( thePlayerTop.isRunning == false) {
                
                // start running
                thePlayerTop.startRun()
            }
        } else if (contact.bodyA.categoryBitMask == BodyType.platformObject.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTop.rawValue ) {
            thePlayerTop.isGrounded = true
            thePlayerTop.physicsBody?.isDynamic = true
            if ( thePlayerTop.isRunning == false) {
                thePlayerTop.startRun()
            }
        }
        
        if (isOnTop) {
            // if the player hits the top ground
            if (contact.bodyA.categoryBitMask == BodyType.groundTop.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
                
                thePlayer.physicsBody?.isDynamic = true
                
                // if player animation isnt running
                if ( thePlayer.isRunning == false) {
                    
                    // start running
                    thePlayer.startRun()
                }
                
                // player is grounded
                thePlayer.isGrounded = true
            } else if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.groundTop.rawValue ) {
                thePlayer.physicsBody?.isDynamic = true
                if ( thePlayer.isRunning == false) {
                    thePlayer.startRun()
                }
                thePlayer.isGrounded = true
            }
            
            // check if on Platform Object
            if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.platformObject.rawValue ) {
                
                // on platform and grounded
                thePlayer.isGrounded = true
                
                // set players current platform
                thePlayer.physicsBody?.isDynamic = true
                
                // if player animation isnt running
                if ( thePlayer.isRunning == false) {
                    
                    // start running
                    thePlayer.startRun()
                }
            } else if (contact.bodyA.categoryBitMask == BodyType.platformObject.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
                thePlayer.isGrounded = true
                thePlayer.physicsBody?.isDynamic = true
                if ( thePlayer.isRunning == false) {
                    thePlayer.startRun()
                }
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        
    }
    
    func emitter(_ contact: SKPhysicsBody, emitter: String) {
        if let particles = SKEmitterNode(fileNamed: emitter), let node = contact.node {
            particles.position = CGPoint(x: self.convert(node.position, from: worldNode).x ,y: node.position.y)
            self.addChild(particles)
        }
    }
    
    func presentGameOverScreen(playSound: SKAction) {
        
        // player must be alive to die
        if ( isDead == false) {
            
            pausePlayBullets(willPause: true)
            
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            
            // player DEAD
            isDead = true
            
            if (UserDefaults.standard.bool(forKey: "volume")) {
                run(playSound)
            }
            
            // check if new score is greater than highscore
            if (Mode.type == 0 && Int(scoreData) > savedData.integer(forKey: "highscore")) || (Mode.type == 1 && Int(scoreData) > savedData.integer(forKey: "highscoreSplitScreen")) {
                
                // set new score as highscore
                if Mode.type == 0 {
                    savedData.set(scoreData, forKey: "highscore")
                    // update highscore label
                    highscoreLabel.text = "Highscore: " + String(savedData.integer(forKey: "highscore"))
                } else if Mode.type == 1 {
                    savedData.set(scoreData, forKey: "highscoreSplitScreen")
                    // update highscore label
                    highscoreLabel.text = "Highscore: " + String(savedData.integer(forKey: "highscoreSplitScreen"))
                }
                
                // start up confetti
                if let confettiView = confettiView {
                    confettiView.startConfetti()
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(confettiSound)
                    }
                }
                Task {
                    var id = ""
                    if Mode.type == 0 {
                        id = "HighScore"
                    } else if Mode.type == 1 {
                        id = "SplitScreenHighScore"
                    }
                    if (Auth.isAuth) {
                        do {
                            try await addScore(id: id, score: Int(scoreData))
                        } catch {
                            UserDefaults.standard.set(true, forKey: "scoreNeedsUpdate")
                            UserDefaults.standard.set(Int(scoreData), forKey: "updatedScore")
                            UserDefaults.standard.set(id, forKey: "updateID")
                        }
                    }
                }
            }
            
            // stop player movement
            thePlayer.physicsBody!.isDynamic = false
            thePlayerTop.physicsBody!.isDynamic = false
            
            worldNode.isPaused = true
            backgroundNode.isPaused = true
            
            if (UserDefaults.standard.bool(forKey: "volume")) {
                // stop footstep sounds
                if let footstepSoundPlayer = footstepSoundPlayer, footstepSoundPlayer.isPlaying {
                    footstepSoundPlayer.pause()
                }
                
                // stop background sounds
                if let backgroundSoundPlayer = backgroundSoundPlayer, backgroundSoundPlayer.isPlaying {
                    backgroundSoundPlayer.pause()
                }
            }
            addChild(playButton)
            addChild(exitButton)
            
            // handle achievements
            if (achievementsLoaded && Auth.isAuth) {
                Task {
                    do {
                        try await calculateAllAchievements(playSound: playSound)
                    } catch {
                        print("Error Updating Achievements")
                    }
                }
            }
            
            if Mode.type == 2 {
                gameModel.players[myIndex].score = Int(scoreData)
                me.score = Int(scoreData)
                var place = gameModel.players.count
                for player in gameModel.players {
                    if player.isDead {
                        place -= 1
                    }
                }
                if !gameModel.gameIsInSession {
                    place = 1
                }
                gameModel.players[myIndex].place = place
                me.place = place
                gameModel.players[myIndex].isDead = true
                me.isDead = true
                // create leaderboard
                createLeaderBoards()
                addChild(shape)
                shape.isHidden = false
                sendData()
            }
        }
    }
    
    private func calculateAllAchievements(playSound: SKAction) async throws {
        
        var totalAchieves = 0
        
        // kunai 100
        if playSound == stabSound {
            if let kunai100 = findAchievement(id: "kunai100") {
                if !(kunai100.first?.isCompleted ?? false) {
                    kunai100.first?.percentComplete += 1.0
                    if kunai100.first?.percentComplete == 100.0 {
                        totalAchieves += 1
                    }
                    try await updateAchievement(allAchievements: kunai100)
                }
            } else {
                let kunai100 = GKAchievement(identifier: "kunai100")
                kunai100.percentComplete = 1.0
                kunai100.showsCompletionBanner = true
                try await updateAchievement(allAchievements: [kunai100])
            }
            
        } else if playSound == burnSound { // acid 100
            if let acid100 = findAchievement(id: "acid100") {
                if !(acid100.first?.isCompleted ?? false) {
                    acid100.first?.percentComplete += 1.0
                    if acid100.first?.percentComplete == 100.0 {
                        totalAchieves += 1
                    }
                    try await updateAchievement(allAchievements: acid100)
                }
            } else {
                let acid100 = GKAchievement(identifier: "acid100")
                acid100.percentComplete = 1.0
                acid100.showsCompletionBanner = true
                try await updateAchievement(allAchievements: [acid100])
            }
            
        } else if playSound == breakSound { // box 100
            if let box100 = findAchievement(id: "box100") {
                if !(box100.first?.isCompleted ?? false) {
                    box100.first?.percentComplete += 1.0
                    if box100.first?.percentComplete == 100.0 {
                        totalAchieves += 1
                    }
                    try await updateAchievement(allAchievements: box100)
                }
            } else {
                let box100 = GKAchievement(identifier: "box100")
                box100.percentComplete = 1.0
                box100.showsCompletionBanner = true
                try await updateAchievement(allAchievements: [box100])
            }
        }
        
        // Teleport 100
        if teleportNum > 0 {
            if let Teleport100 = findAchievement(id: "Teleport100") {
                if !(Teleport100.first?.isCompleted ?? false) {
                    Teleport100.first?.percentComplete += 1.0
                    if (teleportNum > 99) {
                        totalAchieves += 1
                        Teleport100.first?.percentComplete = 100.0
                    } else {
                        Teleport100.first?.percentComplete = Double(teleportNum)
                    }
                    try await updateAchievement(allAchievements: Teleport100)
                }
            } else {
                let Teleport100 = GKAchievement(identifier: "Teleport100")
                if (teleportNum > 99) {
                    totalAchieves += 1
                    Teleport100.percentComplete = 100.0
                } else {
                    Teleport100.percentComplete = Double(teleportNum)
                }
                Teleport100.showsCompletionBanner = true
                try await updateAchievement(allAchievements: [Teleport100])
            }
            
            // Teleport 200
            if let Teleport200 = findAchievement(id: "Teleport200") {
                if !(Teleport200.first?.isCompleted ?? false) {
                    Teleport200.first?.percentComplete += 0.5
                    if (teleportNum > 199) {
                        totalAchieves += 1
                        Teleport200.first?.percentComplete = 100.0
                    } else {
                        Teleport200.first?.percentComplete = (Double(teleportNum) * 0.5)
                    }
                    try await updateAchievement(allAchievements: Teleport200)
                }
            } else {
                let Teleport200 = GKAchievement(identifier: "Teleport200")
                if (teleportNum > 199) {
                    totalAchieves += 1
                    Teleport200.percentComplete = 100.0
                } else {
                    Teleport200.percentComplete = (Double(teleportNum) * 0.5)
                }
                Teleport200.showsCompletionBanner = true
                try await updateAchievement(allAchievements: [Teleport200])
            }
        }
        teleportNum = 0
        
        // tag team
        if (Mode.type == 1) {
            if let tagteam = findAchievement(id: "tagteam") {
                if !(tagteam.first?.isCompleted ?? false) {
                    if Double(Int(scoreData)) > tagteam.first?.percentComplete ?? 0.0 {
                        if Double(Int(scoreData)) > 100.0 {
                            tagteam.first?.percentComplete = 100.0
                            totalAchieves += 1
                            try await updateAchievement(allAchievements: tagteam)
                        } else {
                            tagteam.first?.percentComplete = Double(Int(scoreData))
                            try await updateAchievement(allAchievements: tagteam)
                        }
                    }
                }
            } else {
                let tagteam = GKAchievement(identifier: "tagteam")
                if Double(Int(scoreData)) > 100.0 {
                    tagteam.percentComplete = 100.0
                    totalAchieves += 1
                } else {
                    tagteam.percentComplete = Double(Int(scoreData))
                }
                tagteam.showsCompletionBanner = true
                try await updateAchievement(allAchievements: [tagteam])
            }
            
        }
        
        // plus 100
        var increaseAmount:Double = (Double(Int(scoreData)))
        if let plus100 = findAchievement(id: "plus100") {
            if !(plus100.first?.isCompleted ?? false) {
                if increaseAmount > plus100.first?.percentComplete ?? 0.0 {
                    if increaseAmount > 100.0 {
                        plus100.first?.percentComplete = 100.0
                        totalAchieves += 1
                        try await updateAchievement(allAchievements: plus100)
                    } else {
                        plus100.first?.percentComplete = increaseAmount
                        try await updateAchievement(allAchievements: plus100)
                    }
                }
            }
        } else {
            let plus100 = GKAchievement(identifier: "plus100")
            if increaseAmount > 100.0 {
                plus100.percentComplete = 100.0
                totalAchieves += 1
            } else {
                plus100.percentComplete = increaseAmount
            }
            plus100.showsCompletionBanner = true
            try await updateAchievement(allAchievements: [plus100])
        }
        
        
        // plus 500
        increaseAmount = (Double(Int(scoreData)) * 0.2)
        if let plus500 = findAchievement(id: "plus500") {
            if increaseAmount > plus500.first?.percentComplete ?? 0.0 {
                if increaseAmount > 100.0 {
                    plus500.first?.percentComplete = 100.0
                    totalAchieves += 1
                    try await updateAchievement(allAchievements: plus500)
                } else {
                    plus500.first?.percentComplete = increaseAmount
                    try await updateAchievement(allAchievements: plus500)
                }
            }
        } else {
            let plus500 = GKAchievement(identifier: "plus500")
            if increaseAmount > 100.0 {
                plus500.percentComplete = 100.0
                totalAchieves += 1
            } else {
                plus500.percentComplete = increaseAmount
            }
            plus500.showsCompletionBanner = true
            try await updateAchievement(allAchievements: [plus500])
        }
        
        
        // plus 1000
        increaseAmount = (Double(Int(scoreData)) * 0.1)
        if let plus1000 = findAchievement(id: "plus1000") {
            if increaseAmount > plus1000.first?.percentComplete ?? 0.0 {
                if increaseAmount > 100.0 {
                    plus1000.first?.percentComplete = 100.0
                    totalAchieves += 1
                    try await updateAchievement(allAchievements: plus1000)
                } else {
                    plus1000.first?.percentComplete = increaseAmount
                    try await updateAchievement(allAchievements: plus1000)
                }
            }
        } else {
            let plus1000 = GKAchievement(identifier: "plus1000")
            if increaseAmount > 100.0 {
                plus1000.percentComplete = 100.0
                totalAchieves += 1
            } else {
                plus1000.percentComplete = increaseAmount
            }
            plus1000.showsCompletionBanner = true
            try await updateAchievement(allAchievements: [plus1000])
        }
        
        // all
        if (totalAchieves > 0) {
            increaseAmount = (Double(totalAchieves) * 11.11)
            if let all = findAchievement(id: "all") {
                if !(all.first?.isCompleted ?? false) {
                    if (all.first?.percentComplete ?? 0) + increaseAmount > 90 {
                        all.first?.percentComplete = 100.0
                        totalAchieves += 1
                    } else {
                        all.first?.percentComplete += 11.11
                    }
                }
                try await updateAchievement(allAchievements: all)
            } else {
                let all = GKAchievement(identifier: "all")
                all.showsCompletionBanner = true
                all.percentComplete += increaseAmount
                try await updateAchievement(allAchievements: [all])
            }
        }
        
        try await achievements = loadAchievement()
        
        if totalAchieves > 0 && Mode.type != 2 {
            // start up confetti
            if let confettiView = confettiView {
                if !confettiView.isActive() {
                    confettiView.startConfetti()
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        await run(confettiSound)
                    }
                }
            }
        }
    }
    
    private func findAchievement(id: String) -> [GKAchievement]? {
        for achievement in achievements {
            if achievement.identifier == id {
                return [achievement]
            }
        }
        return nil
    }
    
    func restart() {
        
        scoreData = 0
        
        // stop confetti
        if let confettiView = confettiView {
            if confettiView.isActive() {
                confettiView.stopConfetti()
            }
        }
        
        // stop looping background
        loopingBG.removeAllActions()
        loopingBG2.removeAllActions()
        
        thePlayer.physicsBody!.isDynamic = false
        thePlayerTop.physicsBody!.isDynamic = false
        
        if (UserDefaults.standard.bool(forKey: "volume")) {
            // stop footstep sounds
            if let footstepSoundPlayer = footstepSoundPlayer, footstepSoundPlayer.isPlaying {
                footstepSoundPlayer.pause()
            }
            
            // stop background sounds
            if let backgroundSoundPlayer = backgroundSoundPlayer, backgroundSoundPlayer.isPlaying {
                backgroundSoundPlayer.pause()
            }
        }
        
        resetEverything()
    }
    
    private func loadAchievement() async throws -> [GKAchievement] {
        return try await GKAchievement.loadAchievements()
    }
    
    func revivePlayer() {
        
        // action sequence to fade out worldNode and reset the level with new units
        let fadeOut:SKAction = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let block:SKAction = SKAction.run(resetLevel)
        let fadeIn:SKAction = SKAction.fadeAlpha(to: 1, duration: 0.2)
        let seq:SKAction = SKAction.sequence([fadeOut, block, fadeIn])
        worldNode.run(seq)
        
        // action sequence to fade in player and revive
        let fadeIn2:SKAction = SKAction.fadeAlpha(to: 1, duration: 0.2)
        let block2:SKAction = SKAction.run(noLongerDead)
        let seq2:SKAction = SKAction.sequence([ fadeIn2, block2])
        thePlayer.run(seq2)
        thePlayerTop.run(fadeIn2)
    }
    
    func noLongerDead() {
        
        // player alive again
        isDead = false
        
        // player can start running
        thePlayer.startRun()
        thePlayerTop.startRun()
        
        // begin the looping backgrounds
        startLoopingBackground()
        
        thePlayer.physicsBody!.isDynamic = true
        thePlayerTop.physicsBody!.isDynamic = true
        thePlayer.isHidden = false
        thePlayerTop.isHidden = false
    }
    
    func chooseRandomBG() -> String {
        let diceRoll = arc4random_uniform(3)
        
        if (diceRoll == 0) {
            return "looping_BG1"
        } else if (diceRoll == 1) {
            return "looping_BG2"
        } else if (diceRoll == 2) {
            return "looping_BG3"
        } else {
            return "looping_BG4"
        }
    }
    func resetLoopingBackground() {
        let randomBackground = chooseRandomBG()
        let loopingBGTexture = SKTexture(imageNamed: randomBackground)
        loopingBG.texture = loopingBGTexture
        loopingBG2.texture = loopingBGTexture
        loopingBG.position = CGPoint(x: 0, y: 0)
        loopingBG2.position = CGPoint(x: loopingBG2.size.width - 3, y: 0)
        
        if (UserDefaults.standard.bool(forKey: "volume")) {
            // play background sounds
            playBackgroundSound()
            
            // set footstep sound speed
            footstepSoundPlayer?.rate = 2.0
        }
    }
    
    func resetEverything() {
        // reset score and score label
        scoreData = 0
        scoreLabel.text = "Score: \(Int(scoreData))"
        
        // action sequence to reset player
        let fadeOut:SKAction = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let wait:SKAction = SKAction.wait(forDuration: 0.2)
        let move:SKAction = SKAction.move(to: startingPosition, duration: 0.0)
        let move2:SKAction = SKAction.move(to: startingPositionTop, duration: 0.0)
        let block:SKAction = SKAction.run(revivePlayer)
        let seq:SKAction = SKAction.sequence([fadeOut, move, wait, block])
        let seq2:SKAction = SKAction.sequence([fadeOut, move2])
        thePlayer.run(seq)
        thePlayerTop.run(seq2)
        
        // action sequence to reset looping backgrounds
        let fadeOutBG:SKAction = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let blockBG:SKAction = SKAction.run(resetLoopingBackground)
        let fadeInBG:SKAction = SKAction.fadeAlpha(to: 1, duration: 0.2)
        let seqBG:SKAction = SKAction.sequence([fadeOutBG, blockBG, fadeInBG])
        loopingBG.run(seqBG)
        loopingBG2.run(seqBG)
    }
    
    func addScore(id: String, score: Int) async throws {
        try await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [id])
    }
    
    private func updateAchievement(allAchievements: [GKAchievement]) async throws {
        try await GKAchievement.report(allAchievements)
    }
    
    func playBackgroundSound() {
        if (UserDefaults.standard.bool(forKey: "volume")) {
            // start footstep sounds
            if let footstepSoundPlayer = footstepSoundPlayer, !footstepSoundPlayer.isPlaying {
                footstepSoundPlayer.play()
            }
            
            // start background sounds
            if let backgroundSoundPlayer = backgroundSoundPlayer, !backgroundSoundPlayer.isPlaying {
                backgroundSoundPlayer.play()
            }
        }
        if let path = Bundle.main.path(forResource: "windBackgroundSound", ofType: "wav") {
            do {
                backgroundSoundPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                backgroundSoundPlayer?.numberOfLoops = -1
                backgroundSoundPlayer?.play()
            } catch {
                print("error loading background sounds")
            }
        }
    }
    
    private func createLeaderBoards() {
        // remove last nodes
        for nodes in scoreLabels {
            nodes.removeFromParent()
        }
        scoreLabels = []
        
        // update new nodes
        var nodesToCreate: [playerNode] = []
        for i in gameModel.players.indices {
            if gameModel.players[i].isDead {
                nodesToCreate.append(gameModel.players[i])
            }
        }
        
        nodesToCreate.sort { p1, p2 in
            p1.place < p2.place
        }
        
        for i in nodesToCreate.indices {
            let newNode = SKLabelNode()
            let offset:Double = Double(i * 70)
            newNode.text = "\(nodesToCreate[i].place). \(nodesToCreate[i].name.maxLength(length: 12))"
            newNode.fontName = "Party Confetti"
            newNode.fontColor = .white
            newNode.fontSize = 50
            newNode.zPosition = 1000
            newNode.position = CGPoint(x: -700.0, y: 200.0 - offset)
            newNode.horizontalAlignmentMode = .left
            newNode.verticalAlignmentMode = .top
            addChild(newNode)
            scoreLabels.append(newNode)
        }
    }
    
    private func updateOnline() {
        guard gameModel.players.count > 0 else { return }
        guard displayDeathNodes.count > 0 else { return }
        
        // wating for other players
        if isDead {
            createLeaderBoards()
        }
        
        // update wins
        for i in gameModel.players.indices {
            displayDeathNodes[i].text = "\(gameModel.players[i].name)"
            displayWinNodes[i].text = "W: \(gameModel.players[i].wins)"
        }
        
    }
    
    private func resetOnlineWorld() {
        
        
        if didReset {
            return
        }
        didReset = true
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(resetReset), userInfo: nil, repeats: false)
        
        for i in gameModel.players.indices {
            gameModel.players[i].wantsToPlayAgain = false
            gameModel.players[i].isDead = false
            gameModel.players[i].score = 0
        }
        gameModel.gameIsInSession = true
        me.wantsToPlayAgain = false
        me.isDead = false
        me.score = 0
    
        
        if (UserDefaults.standard.bool(forKey: "volume")) {
            // start footstep sounds
            if let footstepSoundPlayer = footstepSoundPlayer, !footstepSoundPlayer.isPlaying {
                footstepSoundPlayer.play()
            }
            
            // start background sounds
            if let backgroundSoundPlayer = backgroundSoundPlayer, !backgroundSoundPlayer.isPlaying {
                backgroundSoundPlayer.play()
            }
        }
        
        worldNode.isPaused = false
        backgroundNode.isPaused = false
        
        for nodes in displayDeathNodes {
            nodes.fontColor = .white
        }
        
        // remove last nodes
        for nodes in scoreLabels {
            nodes.removeFromParent()
        }
        scoreLabels = []
        shape.removeFromParent()
        shape.isHidden = true
        exitButton.removeFromParent()
        playButton.removeFromParent()
        
        restart()
    }
    
    @objc func resetReset() {
        didReset = false
    }
    
    private func sendData() {
        guard let match = Mode.matchData else { return }
        
        if gameModel.players.count > 1 {
            gameModel.players[myIndex] = me
            // update wins
            for i in gameModel.players.indices {
                displayDeathNodes[i].text = "\(gameModel.players[i].name)"
                displayWinNodes[i].text = "W: \(gameModel.players[i].wins)"
            }
        }
        
        do {
            guard let data = try gameModel.encode() else { return }
            try match.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            print("Send data failed")
        }
    }
    
    private func savePlayers() {
        guard let match = Mode.matchData else { return }
        
        // build data model
        gameModel.players.append(me)
        for player in match.players {
            let otherPlayer = playerNode(place: 0, isDead: false, score: 0, name: player.displayName, wins: 0, wantsToPlayAgain: false)
            gameModel.players.append(otherPlayer)
        }
        
        // sort model so all models are equal order across devices
        gameModel.players.sort { p1, p2 in
            p1.name > p2.name
        }
        
        // build label list
        for i in gameModel.players.indices {
            if gameModel.players[i].name == GKLocalPlayer.local.displayName {
                myIndex = i
            }
            let newNode = SKLabelNode()
            let offset:Double = Double((i + 1) * 300)
            newNode.text = "\(gameModel.players[i].name)".maxLength(length: 12)
            let winNode = SKLabelNode()
            winNode.fontName = "Party Confetti"
            winNode.fontColor = .white
            winNode.fontSize = 50
            winNode.zPosition = 1000
            winNode.position = CGPoint(x: -700 + offset, y: 335.0)
            winNode.horizontalAlignmentMode = .left
            winNode.verticalAlignmentMode = .top
            winNode.text = "W: \(gameModel.players[i].wins)"
            
            newNode.fontName = "Party Confetti"
            newNode.fontColor = .white
            newNode.fontSize = 50
            newNode.zPosition = 1000
            newNode.position = CGPoint(x: -700 + offset, y: 375.0)
            newNode.horizontalAlignmentMode = .left
            newNode.verticalAlignmentMode = .top
            addChild(newNode)
            addChild(winNode)
            displayDeathNodes.append(newNode)
            displayWinNodes.append(winNode)
        }
        
        sendData()
    }
}

extension GameScene: GKMatchDelegate {
    
    func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
        false
    }
    
    func disconnect() {
        
        if (UserDefaults.standard.bool(forKey: "volume")) {
            run(click)
        }
        
        // stop confetti
        if let confettiView = confettiView {
            if confettiView.isActive() {
                confettiView.stopConfetti()
            }
        }
        
        if let view = self.view {
            // Load the SKScene from 'MenuScene.sks'
            if let scene = SKScene(fileNamed: "MenuScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .fill
                
                // Present the scene
                let transition:SKTransition = SKTransition.fade(withDuration: 1)
                view.presentScene(scene, transition: transition)
            }
            
            view.ignoresSiblingOrder = true
            view.preferredFramesPerSecond = 120
        }
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case .unknown:
            disconnect()
        case .connected:
            print("connected")
        case .disconnected:
            disconnect()
        @unknown default:
            disconnect()
        }
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        do {
            guard var model = try TournModel.decode(data: data) else { return }
            if model.players.count > 1 {
                model.players[myIndex] = me
            }
            gameModel = model
            updateOnline()
        } catch {
            print("Recieve data Failed")
        }
    }
}

extension String {
   func maxLength(length: Int) -> String {
       var str = self
       let nsString = str as NSString
       if nsString.length >= length {
           str = nsString.substring(with:
               NSRange(
                location: 0,
                length: nsString.length > length ? length : nsString.length)
           )
           str.append("..")
       }
       return  str
   }
}
