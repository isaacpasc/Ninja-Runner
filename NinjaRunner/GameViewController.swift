//
//  GameViewController.swift
//  NinjaRunner
//
//  Created by Isaac Paschall on 4/21/22.
//

import UIKit
import SpriteKit
import GameplayKit
import GameKit

enum Mode {
    static var type = 0
    static var matchData: GKMatch?
}

enum Auth {
    static var isAuth = false
    static var playClick = false
}

class GameViewController: UIViewController, GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, GKLocalPlayerListener  {
    
    
    private var click:AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'MenuScene.sks'
            if let scene = SKScene(fileNamed: "MenuScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .fill
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            view.preferredFramesPerSecond = 120
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Auth.playClick = true
        gameCenterViewController.dismiss(animated: true)
    }
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        Auth.playClick = true
        viewController.dismiss(animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        // Dismiss the view controller.
        viewController.dismiss(animated: true, completion: nil)
        Mode.type = 2
        Mode.matchData = match
        
        if let view = self.view as! SKView? {
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
    }
    
    func player(_ player: GKPlayer, didAccept invite: GKInvite)   {
        // Present the view controller in the invitation state.
        let viewController = GKMatchmakerViewController(invite: invite)
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let vc2 = windowScene?.keyWindow?.rootViewController
        viewController?.matchmakerDelegate = vc2 as? GKMatchmakerViewControllerDelegate
        vc2?.present(viewController!, animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        print("Matchmaker vc did fail with error: \(error.localizedDescription).")
    }
    
    private func auth() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { vc, error in
            if let vc = vc {
                self.view?.window?.rootViewController?.present(vc, animated: true)
            } else if localPlayer.isAuthenticated {
                Auth.isAuth = true
                localPlayer.register(self)
                self.checkForUpdateScore()
            }
        }
    }
    
    private func checkForUpdateScore() {
        // if score was prev not save, save it
        if (UserDefaults.standard.valueExists(forKey: "scoreNeedsUpdate")) {
            if (UserDefaults.standard.bool(forKey: "scoreNeedsUpdate")) {
                Task {
                    do {
                        try await self.addScore(id: UserDefaults.standard.string(forKey: "updateID")!, score: UserDefaults.standard.integer(forKey: "updatedScore"))
                        UserDefaults.standard.set(false, forKey: "scoreNeedsUpdate")
                    } catch {
                        UserDefaults.standard.set(true, forKey: "scoreNeedsUpdate")
                    }
                }
            }
        }
    }
    
    func addScore(id: String, score: Int) async throws {
        try await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [id])
    }
}
