//
//  TournModel.swift
//  NinjaRunner
//
//  Created by Isaac Paschall on 4/29/22.
//

import Foundation
import UIKit
import GameKit

struct TournModel: Codable {
    var players: [playerNode]
    var gameIsInSession: Bool
    var prevWinner: String
}

struct playerNode: Codable {
    var place: Int
    var isDead: Bool
    var score: Int
    var name: String
    var wins: Int
    var wantsToPlayAgain: Bool
}

extension TournModel {
    func encode() throws -> Data? {
        return try JSONEncoder().encode(self)
    }
    
    static func decode(data: Data) throws -> TournModel? {
        return try JSONDecoder().decode(TournModel.self, from: data)
    }
}
