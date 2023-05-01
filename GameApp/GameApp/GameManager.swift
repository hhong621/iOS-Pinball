//
//  GameManager.swift
//  GameApp
//
//  Created by admin on 4/21/23.
//

import Foundation
import SwiftUI
import SpriteKit

class GameManager: ObservableObject {
    
    var game: Game
    var leaderboard: Leaderboard
    @Published var showNameInput: Bool = true
    
    init(bounds: CGRect) {
        game = Game(size: bounds.size)
        leaderboard = Leaderboard(size: bounds.size)
        
        game.manager = self
        leaderboard.manager = self
    }
}
