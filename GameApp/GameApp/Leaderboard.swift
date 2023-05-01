//
//  Leaderboard.swift
//  GameApp
//
//  Created by admin on 4/21/23.
//

import Foundation
import SwiftUI
import SpriteKit

class Leaderboard: SKScene {
    var contentCreated = false
    var manager: GameManager!
    var scoreNodes: [SKLabelNode] = []
    
    struct Score {
        var name: String
        var value: Int
    }
    
    var scores = [
        Score(name: "---", value: 0),
        Score(name: "---", value: 0),
        Score(name: "---", value: 0),
        Score(name: "---", value: 0),
        Score(name: "---", value: 0),
        Score(name: "---", value: 0),
        Score(name: "---", value: 0),
        Score(name: "---", value: 0),
        Score(name: "---", value: 0),
        Score(name: "---", value: 0)
    ]
    
    override func didMove(to view: SKView) {
        let title = SKLabelNode(text: "High Scores")
        title.name = "Title"
        title.fontName = "Menlo Bold"
        title.fontSize = 50;
        title.position = CGPoint(x: frame.midX, y: frame.height - 100)
        addChild(title)
        
        var index = 1
        let nameX = 100
        let dY = 60
        let valueX = frame.width - 100
        
        // draw scores on the screen
        for score in scores {
            let name = SKLabelNode(text: score.name)
            name.fontName = "Menlo Regular"
            name.fontSize = 30
            name.horizontalAlignmentMode = .left
            name.position = CGPoint(x: Double(nameX), y: frame.height - 120 - Double(index * dY))
            
            let value = SKLabelNode(text: String(score.value))
            value.fontName = "Menlo Regular"
            value.fontSize = 30
            value.horizontalAlignmentMode = .right
            value.position = CGPoint(x: Double(valueX), y: frame.height - 120 - Double(index * dY))
            
            scoreNodes.append(name)
            scoreNodes.append(value)
            addChild(name)
            addChild(value)
            index += 1
        }
        
        let newGameButton = SKSpriteNode(color: .blue, size: CGSize(width: 150, height: 50))
        newGameButton.name = "NewGameButton"
        newGameButton.position = CGPoint(x: frame.midX, y: 200)
        addChild(newGameButton)
        
        let newGameText = SKLabelNode(text: "NEW GAME")
        newGameText.name = "NewGameText"
        newGameText.fontName = "Menlo Bold"
        newGameText.fontSize = 18;
        newGameText.fontColor = .white
        newGameText.horizontalAlignmentMode = .center
        newGameText.verticalAlignmentMode = .center
        newGameText.position = CGPoint(x: frame.midX, y: 200)
        addChild(newGameText)
    }
 
    func updateScores(playerName: String, value: Int) {
        // clear screen of nodes
        if scoreNodes.count > 0 {
            for node in scoreNodes {
                node.removeFromParent()
            }
            scoreNodes.removeAll()
        }
        
        // score makes the board - is high enough
        if(value > scores[9].value) {
            // prompt for name
            scores.append(Score(name: playerName, value: value))
            scores.sort {
                $0.value > $1.value
            }
            scores.removeLast()
        }
        else { return }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = touch.location(in: self)
            let nodesAtPoint = nodes(at: point)
            
            if let firstNode = nodesAtPoint.first, let name = firstNode.name, name == "NewGameButton" || name == "NewGameText" {
                manager.game.resetGame()
                manager.showNameInput = true
            }
        }
    }
}
