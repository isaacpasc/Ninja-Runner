//
//  MenuScene.swift
//  NinjaRunner
//
//  Created by Isaac Paschall on 4/21/22.
//

import SpriteKit
import AVFAudio
import GameKit

class MenuScene: SKScene, GKLocalPlayerListener {
    
    // sound
    private var backgroundSoundPlayer:AVAudioPlayer?
    private let click = SKAction.playSoundFileNamed("Click.wav", waitForCompletion: true)
    
    // nodes
    private var singlePlayerButton = SKSpriteNode()
    private var splitScreenButton = SKSpriteNode()
    private var onLineButton = SKSpriteNode()
    private var shareButton = SKSpriteNode()
    private var leaderboardButton = SKSpriteNode()
    private var volumeButton = SKSpriteNode()
    private var questionButton = SKSpriteNode()
    private var menuBG = SKSpriteNode()
    private var title = SKSpriteNode()
    private var help = SKSpriteNode()
    
    // textures
    private let singlePlayerTexture = SKTexture(imageNamed: "SinglePlayerButton")
    private let splitScreenTexture = SKTexture(imageNamed: "SplitScreenButton")
    private let onlineTexture = SKTexture(imageNamed: "OnlineButton")
    private let shareTexture = SKTexture(imageNamed: "ShareIcon")
    private let leaderboardTexture = SKTexture(imageNamed: "TrophyIcon")
    private let volumeTexture = SKTexture(imageNamed: "VolumeIcon")
    private let muteTexture = SKTexture(imageNamed: "MuteIcon")
    private let questionTexture = SKTexture(imageNamed: "QuestionIcon")
    private let menuBGTexture = SKTexture(imageNamed: "MenuBG")
    private let titleTexture = SKTexture(imageNamed: "Title")
    private var helpTexture = SKTexture(imageNamed: "Help")
    
    private var removed = true
    private var showingHelp = false
    
    override func didMove(to view: SKView) {
        
        if let match = Mode.matchData {
            match.disconnect()
            Mode.matchData = nil
        }
        
        let scale = 0.7
        let iconScale = 0.4
        let height = UIScreen.main.bounds.height
        let width = UIScreen.main.bounds.width
        
        // background
        menuBG.texture = menuBGTexture
        menuBG.zPosition = 1
        menuBG.size = CGSize(width: 1500, height: 768)
        menuBG.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(menuBG)
        
        // title
        title.texture = titleTexture
        title.zPosition = 2
        title.size = CGSize(width: 1200 * scale, height: 400 * scale)
        title.position = CGPoint(x: frame.midX, y: frame.midY + (height * 0.6))
        addChild(title)
        
        // share icon
        shareButton.texture = shareTexture
        shareButton.zPosition = 3
        shareButton.size = CGSize(width: 200 * iconScale, height: 200 * iconScale)
        shareButton.position = CGPoint(x: frame.midX - (width * 0.7), y: frame.midY + (height * 0.75))
        addChild(shareButton)
        
        // question icon
        questionButton.texture = questionTexture
        questionButton.zPosition = 5
        questionButton.size = CGSize(width: 200 * iconScale, height: 200 * iconScale)
        questionButton.position = CGPoint(x: frame.midX - (width * 0.6), y: frame.midY + (height * 0.75))
        addChild(questionButton)
        
        // help menu
        help.texture = helpTexture
        help.zPosition = 10
        help.size = CGSize(width: 1024, height: 672)
        help.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // volume icon
        if (UserDefaults.standard.valueExists(forKey: "volume")) {
            if (UserDefaults.standard.bool(forKey: "volume")) {
                volumeButton.texture = volumeTexture
                playBackgroundSound()
            } else {
                volumeButton.texture = muteTexture
            }
        } else {
            UserDefaults.standard.set(true, forKey: "volume")
            volumeButton.texture = volumeTexture
            playBackgroundSound()
        }
        volumeButton.zPosition = 6
        volumeButton.size = CGSize(width: 200 * iconScale, height: 200 * iconScale)
        volumeButton.position = CGPoint(x: frame.midX + (width * 0.6), y: frame.midY + (height * 0.75))
        addChild(volumeButton)
        
        // online button
        onLineButton.texture = onlineTexture
        onLineButton.zPosition = 7
        onLineButton.size = CGSize(width: 1000 * scale, height: 200 * scale)
        onLineButton.position = CGPoint(x: frame.midX, y: frame.midY - (height * 0.6))
        addChild(onLineButton)
        
        // split screen button
        splitScreenButton.texture = splitScreenTexture
        splitScreenButton.zPosition = 8
        splitScreenButton.size = CGSize(width: 1000 * scale, height: 200 * scale)
        splitScreenButton.position = CGPoint(x: frame.midX, y: frame.midY - (height * 0.25))
        addChild(splitScreenButton)
        
        // single player button
        singlePlayerButton.texture = singlePlayerTexture
        singlePlayerButton.zPosition = 9
        singlePlayerButton.size = CGSize(width: 1000 * scale, height: 200 * scale)
        singlePlayerButton.position = CGPoint(x: frame.midX, y: frame.midY + (height * 0.1))
        addChild(singlePlayerButton)
        
        // trophy icon
        leaderboardButton.texture = leaderboardTexture
        leaderboardButton.zPosition = 4
        leaderboardButton.size = CGSize(width: 200 * iconScale, height: 200 * iconScale)
        leaderboardButton.position = CGPoint(x: frame.midX + (width * 0.7), y: frame.midY + (height * 0.75))
        addChild(leaderboardButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let pos = touch.location(in: self)
            let node = self.atPoint(pos)
            if !showingHelp {
                if node == volumeButton {
                    if volumeButton.texture == muteTexture {
                        // unmute
                        UserDefaults.standard.set(true, forKey: "volume")
                        volumeButton.texture = volumeTexture
                        run(click)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        resumeSound()
                        
                    } else {
                        // mute
                        UserDefaults.standard.set(false, forKey: "volume")
                        volumeButton.texture = muteTexture
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        pauseSound()
                        
                    }
                } else if node == leaderboardButton {
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    if (Auth.isAuth) {
                        showLeader()
                    }
                    
                    
                } else if node == shareButton {
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    pauseSound()
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    shareSheet()
                } else if node == questionButton {
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    addChild(help)
                    showingHelp = true
                    
                } else if node == singlePlayerButton {
                    pauseSound()
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    Mode.type = 0
                    if let view = self.view {
                        // Load the SKScene from 'GameScene.sks'
                        if let scene = SKScene(fileNamed: "GameScene") {
                            // Set the scale mode to scale to fit the window
                            scene.scaleMode = .fill
                            
                            // Present the scene
                            let transition:SKTransition = SKTransition.fade(withDuration: 1)
                            view.presentScene(scene, transition: transition)
                        }
                        
                        view.ignoresSiblingOrder = true
                        view.preferredFramesPerSecond = 120
                    }
                } else if node == splitScreenButton {
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    pauseSound()
                    Mode.type = 1
                    if let view = self.view {
                        // Load the SKScene from 'GameScene.sks'
                        if let scene = SKScene(fileNamed: "GameScene") {
                            // Set the scale mode to scale to fit the window
                            scene.scaleMode = .fill
                            
                            // Present the scene
                            let transition:SKTransition = SKTransition.fade(withDuration: 1)
                            view.presentScene(scene, transition: transition)
                        }
                        
                        view.ignoresSiblingOrder = true
                        view.preferredFramesPerSecond = 120
                    }
                } else if node == onLineButton {
                    if (UserDefaults.standard.bool(forKey: "volume")) {
                        run(click)
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    presentMatchmakerVs()
                }
            } else {
                if (UserDefaults.standard.bool(forKey: "volume")) {
                    run(click)
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                help.removeFromParent()
                showingHelp = false
            }
        }
    }
    
    func presentMatchmakerVs() {
        guard Auth.isAuth else {return}
        
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 4
        request.inviteMessage = "Play a game of Ninja Runner with me?"
        
        guard let vc = GKMatchmakerViewController(matchRequest: request) else {return}
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let vc2 = windowScene?.keyWindow?.rootViewController
        vc.matchmakerDelegate = vc2 as? GKMatchmakerViewControllerDelegate
        vc.canStartWithMinimumPlayers = true
        vc2?.present(vc, animated: true)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        // remove leaderboard if not auth
        if (!removed && !GKLocalPlayer.local.isAuthenticated) {
            leaderboardButton.removeFromParent()
            removed = true
        }
        
        if !UserDefaults.standard.bool(forKey: "volume") {
            pauseSound()
        }
        
        // play click if returning from achievements
        if (Auth.playClick) {
            if (UserDefaults.standard.bool(forKey: "volume")) {
                run(click)
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            Auth.playClick = false
        }
    }
    
    private func showLeader() {
        let gcVC = GKGameCenterViewController(state: .dashboard)
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let vc = windowScene?.keyWindow?.rootViewController
        gcVC.gameCenterDelegate = vc as? GKGameCenterControllerDelegate
        vc?.present(gcVC, animated: true)
    }
    
    private func resumeSound() {
        // start background sounds
        if let backgroundSoundPlayer = backgroundSoundPlayer, !backgroundSoundPlayer.isPlaying {
            backgroundSoundPlayer.play()
        } else {
            playBackgroundSound()
        }
    }
    
    private func pauseSound() {
        // start background sounds
        if let backgroundSoundPlayer = backgroundSoundPlayer, backgroundSoundPlayer.isPlaying {
            backgroundSoundPlayer.pause()
        }
    }
    
    private func playBackgroundSound() {
        if let path = Bundle.main.path(forResource: "BGMusic", ofType: "wav") {
            do {
                backgroundSoundPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                backgroundSoundPlayer?.numberOfLoops = -1
                backgroundSoundPlayer?.play()
            } catch {
                print("error loading background sounds")
            }
        }
    }
    
    func addScore(id: String, score: Int) async throws {
        try await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [id])
    }
    
    private func shareSheet() {
        let AV = UIActivityViewController(activityItems: [URL(string: "https://apps.apple.com/us/app/id1621604077")!], applicationActivities: nil)
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        windowScene?.keyWindow?.rootViewController?.present(AV, animated: true, completion: resumeSound)
    }
}


// check if value exists in userdefaults
extension UserDefaults {
    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
