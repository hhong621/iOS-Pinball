//
//  Game.swift
//  GameApp
//
//  Created by admin on 4/10/23.
//

import Foundation
import SwiftUI
import SpriteKit

/*
 KNOWN ISSUES:
 - occassionally the ball goes through the flipper
 - flippers do not reset fully on fast/double tap touches
 - if the ball is going REALLY FAST it can get stuck inside of walls
 - if the ball lacks enough momentum, it can get stuck on top of the flipper walls
*/

class Game: SKScene, SKPhysicsContactDelegate {
    
    var manager: GameManager!
    var contentCreated = false
    var activeTouches = [UITouch:String]()
    
    var leftFlipperOn = false
    var rightFlipperOn = false
    
    var circleSwitchOn1 = false
    var circleSwitchOn2 = false
    var circleSwitchOn3 = false
    
    var squareSwitchOn1 = false
    var squareSwitchOn2 = false
    
    var ballReset = true
    
    var selectedNode: SKNode?
    
    var deathSound = SKAudioNode(fileNamed: "death.wav")
    var extraLifeSound = SKAudioNode(fileNamed: "extra-life.wav")
    var flipperSound = SKAudioNode(fileNamed: "flipper.wav")
    var pingSound = SKAudioNode(fileNamed: "ping.wav")
    var plungerSound = SKAudioNode(fileNamed: "plunger.wav")
    var switchCompleteSound = SKAudioNode(fileNamed: "switch-complete.wav")
    
    var score: Int = 0 {
        didSet {
            guard let scoreNode = childNode(withName: "Score") as? SKLabelNode else { return }
            scoreNode.text = "\(score)"
        }
    }
    var lives = 2 {
        didSet {
            guard let node = childNode(withName: "Lives") as? SKLabelNode else { return }
            node.text = "\(lives)"
        }
    }
    var playerName: String = ""
    
    override func didMove(to view: SKView) {        
        if contentCreated == false {
            // one time setup
            createScene()
            contentCreated = true
        }
        else {
            // reset the game
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = touch.location(in: self)
            let nodesAtPoint = nodes(at: point)
            
            // tap plunger to put ball into play
            if let firstNode = nodesAtPoint.first, let name = firstNode.name, name == "Plunger", ballReset {
                plungerSound.run(SKAction.play())
                if let ball = childNode(withName: "Ball") {
                    ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 190))
                }
                ballReset = false
            }
            
            let side = findTouchSide(touch: touch)
            activeTouches[touch] = side
            tapBegin(side: side)
        }
    }
    
    func tapBegin(side: String) {
        //print("\(side) touch begin")
        flipperSound.run(SKAction.play())
        if side == "left" {
            if let left = childNode(withName: "LeftFlipper") {
                let rotateAction = SKAction.rotate(byAngle: 1.0, duration: 0.075)
                left.run(rotateAction)
            }
        }
        else if side == "right" {
            if let right = childNode(withName: "RightFlipper") {
                let rotateAction = SKAction.rotate(byAngle: -1.0, duration: 0.075)
                right.run(rotateAction)
            }
        }
    }
    
    func findTouchSide(touch: UITouch) -> String {
        let location = touch.location(in: self)
        if location.x > self.frame.width/2 {
            return "right"
        } else {
            return "left"
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            // reset flippers
            guard let side = activeTouches[touch] else { fatalError("Touch ended but not found in activeTouches") }
            activeTouches[touch] = nil
            tapEnd(side: side)
        }
    }
    
    func tapEnd(side: String) {
        //print("\(side) touch end")
        if side == "left" {
            if let left = childNode(withName: "LeftFlipper") {
                left.zRotation = .pi + 5 * .pi / 6
            }
        }
        else if side == "right" {
            if let right = childNode(withName: "RightFlipper") {
                right.zRotation = .pi / 6
            }
        }
    }
    
    // detect contact
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node, let nameA = nodeA.name else { return }
        guard let nodeB = contact.bodyB.node, let nameB = nodeB.name else { return }

        if (nameA == "Ball" && nameB == "Floor") || (nameA == "Floor" && nameB == "Ball") {
            deathSound.run(SKAction.play())
            lives -= 1
            if lives >= 0 {
                resetBall()
            }
            else {
                gameOver()
            }
        }
        
        if (nameA == "Ball" && (nameB == "LeftTriBumper" || nameB == "RightTriBumper")) || ((nameA == "LeftTriBumper" || nameA == "RightTriBumper") && nameB == "Ball") {
            pingSound.run(SKAction.play())
            score += 5
        }
        
        if (nameA == "Ball" && (nameB == "Bumper1" || nameB == "Bumper2" || nameB == "Bumper3")) || ((nameA == "Bumper1" || nameA == "Bumper2" || nameA == "Bumper3") && nameB == "Ball") {
            pingSound.run(SKAction.play())
            score += 10
        }
        
        if (nameA == "Ball" && nameB == "Spring") || (nameA == "Spring" && nameB == "Ball") {
            pingSound.run(SKAction.play())
            score += 15
        }
        
        if (nameA == "Ball" && nameB == "LeftGuard") || (nameA == "LeftGuard" && nameB == "Ball") {
            closeGate()
        }
        
        if (nameA == "Ball" && nameB == "Button") || (nameA == "Button" && nameB == "Ball") {
            print("*** life button contact ***")
            extraLifeSound.run(SKAction.play())
            lives += 1
        }
        
        if (nameA == "Ball" && nameB == "CircleSwitch1") || (nameA == "CircleSwitch1" && nameB == "Ball") {
            if let circle = childNode(withName: "CircleSwitch1") as? SKShapeNode {
                circle.fillColor = .blue
            }
            circleSwitchOn1 = true
            circleSwitchCheck()
        }
        
        if (nameA == "Ball" && nameB == "CircleSwitch2") || (nameA == "CircleSwitch2" && nameB == "Ball") {
            if let circle = childNode(withName: "CircleSwitch2") as? SKShapeNode {
                circle.fillColor = .blue
            }
            circleSwitchOn2 = true
            circleSwitchCheck()
        }
        
        if (nameA == "Ball" && nameB == "CircleSwitch3") || (nameA == "CircleSwitch3" && nameB == "Ball") {
            if let circle = childNode(withName: "CircleSwitch3") as? SKShapeNode {
                circle.fillColor = .blue
            }
            circleSwitchOn3 = true
            circleSwitchCheck()
        }
        
        if (nameA == "Ball" && nameB == "SquareSwitch1") || (nameA == "SquareSwitch1" && nameB == "Ball") {
            if let square = childNode(withName: "SquareSwitch1") as? SKSpriteNode {
                square.color = .yellow
            }
            squareSwitchOn1 = true
            squareSwitchCheck()
        }
        
        if (nameA == "Ball" && nameB == "SquareSwitch2") || (nameA == "SquareSwitch2" && nameB == "Ball") {
            if let square = childNode(withName: "SquareSwitch2") as? SKSpriteNode {
                square.color = .yellow
            }
            squareSwitchOn2 = true
            squareSwitchCheck()
        }
    }
    
    func circleSwitchCheck() {
        if circleSwitchOn1 && circleSwitchOn2 && circleSwitchOn3 {
            print("* all circle switches on *")
            switchCompleteSound.run(SKAction.play())
            score += 300
            resetCircleSwitches()
        }
    }
    
    func squareSwitchCheck() {
        if squareSwitchOn1 && squareSwitchOn2 {
            print("* all square switches on *")
            switchCompleteSound.run(SKAction.play())
            score += 200
            resetSquareSwitches()
        }
    }
    
    func resetCircleSwitches() {
        circleSwitchOn1 = false
        circleSwitchOn2 = false
        circleSwitchOn3 = false
        if let circle = childNode(withName: "CircleSwitch1") as? SKShapeNode {
            circle.fillColor = .gray
        }
        if let circle = childNode(withName: "CircleSwitch2") as? SKShapeNode {
            circle.fillColor = .gray
        }
        if let circle = childNode(withName: "CircleSwitch3") as? SKShapeNode {
            circle.fillColor = .gray
        }
    }
    
    func resetSquareSwitches() {
        squareSwitchOn1 = false
        squareSwitchOn2 = false
        if let square = childNode(withName: "SquareSwitch1") as? SKSpriteNode {
            square.color = .gray
        }
        if let square = childNode(withName: "SquareSwitch2") as? SKSpriteNode {
            square.color = .gray
        }
    }
    
    func gameOver() {
        manager.leaderboard.updateScores(playerName: playerName, value: score)
        view?.presentScene(manager.leaderboard)
    }
    
    func resetGame() {
        resetBall()
        resetCircleSwitches()
        resetSquareSwitches()
        score = 0
        lives = 2
    }
    
    func setName(name: String) {
        playerName = name
        print(playerName)
    }
}

extension Game {
    
    func resetBall() {
        openGate()
        ballReset = true
        guard let ball = childNode(withName: "Ball") as? SKSpriteNode else { return }
        ball.removeFromParent()
        createBall()
    }
    
    // prevents the ball from entering the plunger track once in play
    func createGate() {
        let gate = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 40))
        gate.name = "Gate"
        gate.alpha = 0.0
        gate.position = CGPoint(x: 240, y: frame.height - 100)
        let body = SKPhysicsBody(circleOfRadius: 20)
        body.isDynamic = false
        body.categoryBitMask = 0b0001
        body.collisionBitMask = 0b0001
        body.contactTestBitMask = 1
        gate.physicsBody = body
        addChild(gate)
    }
    
    // collides to stop the ball
    func closeGate() {
        guard let gate = childNode(withName: "Gate") as? SKSpriteNode else { return }
        gate.physicsBody?.categoryBitMask = 0b0001
        print("--gate closed")
    }
    
    // ball passes through
    func openGate() {
        guard let gate = childNode(withName: "Gate") as? SKSpriteNode else { return }
        gate.physicsBody?.categoryBitMask = 0b0010
        print("--gate open")
    }
    
    func createScene() {
        createGate()
        createBall()
        createButtonsSwitches()
        createWalls()
        resetBall()
        createFlippers()
        createBumpers()
        createPlunger()
        createSounds()
        createScore()
        createLives()
        
        physicsWorld.contactDelegate = self
    }
    
    func createScore() {
        let scoreNode = SKLabelNode(text: "\(score)")
        scoreNode.name = "Score"
        scoreNode.fontName = "Menlo Regular"
        scoreNode.fontSize = 36
        scoreNode.fontColor = .black
        scoreNode.horizontalAlignmentMode = .right
        scoreNode.verticalAlignmentMode = .top
        scoreNode.position = CGPoint(x: frame.width - 20, y: frame.height - 40)
        addChild(scoreNode)
    }
    
    func createLives() {
        let livesNode = SKLabelNode(text: "\(lives)")
        livesNode.name = "Lives"
        livesNode.fontName = "Menlo Regular"
        livesNode.fontSize = 36
        livesNode.fontColor = .black
        livesNode.horizontalAlignmentMode = .left
        livesNode.verticalAlignmentMode = .top
        livesNode.position = CGPoint(x: 20, y: frame.height - 40)
        addChild(livesNode)
    }
    
    func createSounds() {
        deathSound.isPositional = false
        deathSound.autoplayLooped = false
        addChild(deathSound)
        
        extraLifeSound.isPositional = false
        extraLifeSound.autoplayLooped = false
        addChild(extraLifeSound)
        
        flipperSound.isPositional = false
        flipperSound.autoplayLooped = false
        addChild(flipperSound)
        
        pingSound.isPositional = false
        pingSound.autoplayLooped = false
        addChild(pingSound)
        
        plungerSound.isPositional = false
        plungerSound.autoplayLooped = false
        addChild(plungerSound)
        
        switchCompleteSound.isPositional = false
        switchCompleteSound.autoplayLooped = false
        addChild(switchCompleteSound)
    }
    
    func createFlippers() {        
        let leftFlipperTexture = SKTexture(imageNamed: "left-flipper")
        let leftFlipper = SKSpriteNode(texture: leftFlipperTexture, size: CGSize(width: 146, height: 47))
        leftFlipper.name = "LeftFlipper"
        leftFlipper.position = CGPoint(x: 175, y: 152)
        leftFlipper.anchorPoint = CGPoint(x: 0, y: 0.5)
        leftFlipper.zRotation = .pi + 5 * .pi / 6
        
        let leftCenterPoint = CGPoint(x: leftFlipper.size.width/2 - (leftFlipper.size.width * leftFlipper.anchorPoint.x), y: leftFlipper.size.height/2 - (leftFlipper.size.height * leftFlipper.anchorPoint.y))
        let leftBody = SKPhysicsBody(rectangleOf: CGSize(width: 146, height: 30), center: leftCenterPoint)
        leftBody.isDynamic = false
        leftBody.usesPreciseCollisionDetection = true
        leftBody.restitution = 1.5
        leftFlipper.physicsBody = leftBody
        addChild(leftFlipper)
        
        let rightFlipperTexture = SKTexture(imageNamed: "right-flipper")
        let rightFlipper = SKSpriteNode(texture: rightFlipperTexture, size: CGSize(width: 146, height: 47))
        rightFlipper.name = "RightFlipper"
        rightFlipper.position = CGPoint(x: 505, y: 152)
        rightFlipper.anchorPoint = CGPoint(x: 1, y: 0.5)
        rightFlipper.zRotation = .pi / 6
        
        let rightCenterPoint = CGPoint(x: rightFlipper.size.width/2 - (rightFlipper.size.width * rightFlipper.anchorPoint.x), y: rightFlipper.size.height/2 - (rightFlipper.size.height * rightFlipper.anchorPoint.y))
        let rightBody = SKPhysicsBody(rectangleOf: CGSize(width: 146, height: 30), center: rightCenterPoint)
        rightBody.isDynamic = false
        rightBody.usesPreciseCollisionDetection = true
        rightBody.restitution = 1.5
        rightFlipper.physicsBody = rightBody
        addChild(rightFlipper)
    }
    
    func createBall() {
        let ballTexture = SKTexture(imageNamed: "ball")
        let ball = SKSpriteNode(texture: ballTexture)
        ball.name = "Ball"
        ball.size = CGSize(width: 50, height: 50)
        ball.position = CGPoint(x: 728, y: 190)
        let ballBody = SKPhysicsBody(circleOfRadius: ball.size.height/2)
        ballBody.usesPreciseCollisionDetection = true
        ballBody.categoryBitMask = 0b0001
        ballBody.collisionBitMask = 0b0001
        ballBody.contactTestBitMask = 1
        ball.physicsBody = ballBody
        addChild(ball)
    }
    
    func createPlunger() {
        let plunger = SKSpriteNode(color: .blue, size: CGSize(width: 40, height: 40))
        plunger.name = "Plunger"
        plunger.position = CGPoint(x: 724, y: 103)
        addChild(plunger)
    }
    
    func createButtonsSwitches() {
        let springTexture = SKTexture(imageNamed: "spring")
        let spring = SKSpriteNode(texture: springTexture)
        spring.name = "Spring"
        spring.position = CGPoint(x: 496, y: 630)
        spring.zRotation = 0.93
        let springBody = SKPhysicsBody(texture: springTexture, size: springTexture.size())
        springBody.isDynamic = false
        springBody.restitution = 1.5
        spring.physicsBody = springBody
        addChild(spring)
        
        let button = SKSpriteNode(color: .green, size: CGSize(width: 20, height: 20))
        button.name = "Button"
        button.position = CGPoint(x: 510, y: 562)
        button.zRotation = 0.93
        let buttonBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 20))
        buttonBody.isDynamic = false
        buttonBody.restitution = 1
        button.physicsBody = buttonBody
        addChild(button)
        
        let circleSwitch1 = SKShapeNode(circleOfRadius: 12)
        circleSwitch1.name = "CircleSwitch1"
        circleSwitch1.position = CGPoint(x: 248, y: 784)
        circleSwitch1.fillColor = .gray
        circleSwitch1.strokeColor = .gray
        let circleBody1 = SKPhysicsBody(circleOfRadius: 14)
        circleBody1.isDynamic = false
        circleBody1.categoryBitMask = 0b0010
        circleBody1.collisionBitMask = 0b0001
        circleBody1.contactTestBitMask = 1
        circleSwitch1.physicsBody = circleBody1
        addChild(circleSwitch1)
        
        let circleSwitch2 = SKShapeNode(circleOfRadius: 12)
        circleSwitch2.name = "CircleSwitch2"
        circleSwitch2.position = CGPoint(x: 334, y: 810)
        circleSwitch2.fillColor = .gray
        circleSwitch2.strokeColor = .gray
        let circleBody2 = SKPhysicsBody(circleOfRadius: 14)
        circleBody2.isDynamic = false
        circleBody2.categoryBitMask = 0b0010
        circleBody2.collisionBitMask = 0b0001
        circleBody2.contactTestBitMask = 1
        circleSwitch2.physicsBody = circleBody2
        addChild(circleSwitch2)
        
        let circleSwitch3 = SKShapeNode(circleOfRadius: 12)
        circleSwitch3.name = "CircleSwitch3"
        circleSwitch3.position = CGPoint(x: 420, y: 805)
        circleSwitch3.fillColor = .gray
        circleSwitch3.strokeColor = .gray
        let circleBody3 = SKPhysicsBody(circleOfRadius: 14)
        circleBody3.isDynamic = false
        circleBody3.categoryBitMask = 0b0010
        circleBody3.collisionBitMask = 0b0001
        circleBody3.contactTestBitMask = 1
        circleSwitch3.physicsBody = circleBody3
        addChild(circleSwitch3)
        
        let squareSwitch1 = SKSpriteNode(color: .gray, size: CGSize(width: 24, height: 24))
        squareSwitch1.name = "SquareSwitch1"
        squareSwitch1.position = CGPoint(x: 132, y: 544)
        let squareBody1 = SKPhysicsBody(rectangleOf: CGSize(width: 24, height: 24))
        squareBody1.isDynamic = false
        squareBody1.categoryBitMask = 0b0010
        squareBody1.collisionBitMask = 0b0001
        squareBody1.contactTestBitMask = 1
        squareSwitch1.physicsBody = squareBody1
        addChild(squareSwitch1)
        
        let squareSwitch2 = SKSpriteNode(color: .gray, size: CGSize(width: 24, height: 24))
        squareSwitch2.name = "SquareSwitch2"
        squareSwitch2.position = CGPoint(x: 606, y: 544)
        let squareBody2 = SKPhysicsBody(rectangleOf: CGSize(width: 24, height: 24))
        squareBody2.isDynamic = false
        squareBody2.categoryBitMask = 0b0010
        squareBody2.collisionBitMask = 0b0001
        squareBody2.contactTestBitMask = 1
        squareSwitch2.physicsBody = squareBody2
        addChild(squareSwitch2)
    }
    
    func createBumpers() {
        let leftTriBumperTexture = SKTexture(imageNamed: "left-tri-bumper")
        let leftTriBumper = SKSpriteNode(texture: leftTriBumperTexture)
        leftTriBumper.name = "LeftTriBumper"
        leftTriBumper.position = CGPoint(x: 173, y: 283)
        let leftTriBody = SKPhysicsBody(texture: leftTriBumperTexture, size: leftTriBumperTexture.size())
        leftTriBody.isDynamic = false
        leftTriBody.restitution = 1.2
        leftTriBumper.physicsBody = leftTriBody
        addChild(leftTriBumper)
        
        let rightTriBumperTexture = SKTexture(imageNamed: "right-tri-bumper")
        let rightTriBumper = SKSpriteNode(texture: rightTriBumperTexture)
        rightTriBumper.name = "RightTriBumper"
        rightTriBumper.position = CGPoint(x: 508, y: 283)
        let rightTriBody = SKPhysicsBody(texture: rightTriBumperTexture, size: rightTriBumperTexture.size())
        rightTriBody.isDynamic = false
        rightTriBody.restitution = 1.2
        rightTriBumper.physicsBody = rightTriBody
        addChild(rightTriBumper)
        
        
        let bumperTexture = SKTexture(imageNamed: "circle-bumper")
        
        let bumper1 = SKSpriteNode(texture: bumperTexture)
        bumper1.position = CGPoint(x: 265, y: 674)
        bumper1.name = "Bumper1"
        let body1 = SKPhysicsBody(circleOfRadius: bumper1.size.height/2)
        body1.isDynamic = false
        body1.restitution = 1.2
        bumper1.physicsBody = body1
        addChild(bumper1)
        
        let bumper2 = SKSpriteNode(texture: bumperTexture)
        bumper2.position = CGPoint(x: 384, y: 708)
        bumper2.name = "Bumper2"
        let body2 = SKPhysicsBody(circleOfRadius: bumper2.size.height/2)
        body2.isDynamic = false
        body2.restitution = 1.2
        bumper2.physicsBody = body2
        addChild(bumper2)
        
        let bumper3 = SKSpriteNode(texture: bumperTexture)
        bumper3.position = CGPoint(x: 356, y: 590)
        bumper3.name = "Bumper3"
        let body3 = SKPhysicsBody(circleOfRadius: bumper3.size.height/2)
        body3.isDynamic = false
        body3.restitution = 1.2
        bumper3.physicsBody = body3
        addChild(bumper3)
    }
    
    func createWalls() {
        let floor = SKSpriteNode(color: .black, size: CGSize(width: frame.width, height: 10))
        floor.position = CGPoint(x: frame.midX, y: -100)
        floor.name = "Floor"
        let floorBody = SKPhysicsBody(rectangleOf: floor.size)
        floorBody.isDynamic = false
        floorBody.categoryBitMask = 0b0010
        floorBody.collisionBitMask = 0b0001
        floorBody.contactTestBitMask = 1
        floor.physicsBody = floorBody
        addChild(floor)
        
        let leftEdge = SKSpriteNode(color: SKColor.white, size: CGSize(width: 20, height: frame.height))
        leftEdge.position = CGPoint(x: 0, y: frame.midY)
        leftEdge.name = "Left"
        let leftBody = SKPhysicsBody(rectangleOf: leftEdge.size)
        leftBody.isDynamic = false
        leftEdge.physicsBody = leftBody
        addChild(leftEdge)
        
        let rightEdge = SKSpriteNode(color: SKColor.white, size: CGSize(width: 20, height: frame.height))
        rightEdge.position = CGPoint(x: frame.width, y: frame.midY)
        rightEdge.name = "Right"
        let rightBody = SKPhysicsBody(rectangleOf: rightEdge.size)
        rightBody.isDynamic = false
        rightEdge.physicsBody = rightBody
        addChild(rightEdge)
        
        let topTexture = SKTexture(imageNamed: "top-wall")
        let topWall = SKSpriteNode(texture: topTexture)
        topWall.position = CGPoint(x: frame.midX, y: frame.height - 183)
        let topBody = SKPhysicsBody(texture: topTexture, size: topTexture.size())
        topBody.isDynamic = false
        topWall.physicsBody = topBody
        addChild(topWall)
        
        let bottomLeftTexture = SKTexture(imageNamed: "left-bottom-wall")
        let bottomLeftWall = SKSpriteNode(texture: bottomLeftTexture)
        bottomLeftWall.position = CGPoint(x: 123, y: 71)
        let bottomLeftBody = SKPhysicsBody(texture: bottomLeftTexture, size: bottomLeftTexture.size())
        bottomLeftBody.isDynamic = false
        bottomLeftWall.physicsBody = bottomLeftBody
        addChild(bottomLeftWall)
        
        let bottomRightTexture = SKTexture(imageNamed: "right-bottom-wall")
        let bottomRightWall = SKSpriteNode(texture: bottomRightTexture)
        bottomRightWall.position = CGPoint(x: frame.width - 167, y: 71)
        let bottomRightBody = SKPhysicsBody(texture: bottomRightTexture, size: bottomRightTexture.size())
        bottomRightBody.isDynamic = false
        bottomRightWall.physicsBody = bottomRightBody
        addChild(bottomRightWall)
        
        let plungerWallTexture = SKTexture(imageNamed: "plunger-wall")
        let plungerWall = SKSpriteNode(texture: plungerWallTexture)
        plungerWall.position = CGPoint(x: frame.width - 302, y: 464)
        let plungerWallBody = SKPhysicsBody(texture: plungerWallTexture, size: plungerWallTexture.size())
        plungerWallBody.isDynamic = false
        plungerWall.physicsBody = plungerWallBody
        addChild(plungerWall)
        
        let leftGuardTexture = SKTexture(imageNamed: "left-guard")
        let leftGuard = SKSpriteNode(texture: leftGuardTexture)
        leftGuard.name = "LeftGuard"
        leftGuard.position = CGPoint(x: 34, y: frame.height - 511)
        let leftGuardBody = SKPhysicsBody(texture: leftGuardTexture, size: leftGuardTexture.size())
        leftGuardBody.isDynamic = false
        leftGuardBody.categoryBitMask = 0b0001
        leftGuardBody.collisionBitMask = 0b0001
        leftGuardBody.contactTestBitMask = 1
        leftGuard.physicsBody = leftGuardBody
        addChild(leftGuard)
        
        let rightGuardTexture = SKTexture(imageNamed: "right-guard")
        let rightGuard = SKSpriteNode(texture: rightGuardTexture)
        rightGuard.position = CGPoint(x: frame.width - 120, y: frame.height - 511)
        let rightGuardBody = SKPhysicsBody(texture: rightGuardTexture, size: rightGuardTexture.size())
        rightGuardBody.isDynamic = false
        rightGuard.physicsBody = rightGuardBody
        addChild(rightGuard)
        
        let leftFlipperWallTexture = SKTexture(imageNamed: "left-flipper-wall")
        let leftFlipperWall = SKSpriteNode(texture: leftFlipperWallTexture)
        leftFlipperWall.position = CGPoint(x: 127, y: 260)
        let leftFlipperWallBody = SKPhysicsBody(texture: leftFlipperWallTexture, size: leftFlipperWallTexture.size())
        leftFlipperWallBody.isDynamic = false
        leftFlipperWall.physicsBody = leftFlipperWallBody
        addChild(leftFlipperWall)
        
        let rightFlipperWallTexture = SKTexture(imageNamed: "right-flipper-wall")
        let rightFlipperWall = SKSpriteNode(texture: rightFlipperWallTexture)
        rightFlipperWall.position = CGPoint(x: 554, y: 260)
        let rightFlipperWallBody = SKPhysicsBody(texture: rightFlipperWallTexture, size: rightFlipperWallTexture.size())
        rightFlipperWallBody.isDynamic = false
        rightFlipperWall.physicsBody = rightFlipperWallBody
        addChild(rightFlipperWall)
        
        let caveWallTexture = SKTexture(imageNamed: "cave-wall")
        let caveWall = SKSpriteNode(texture: caveWallTexture)
        caveWall.position = CGPoint(x: 536, y: 669)
        let caveWallBody = SKPhysicsBody(texture: caveWallTexture, size: caveWallTexture.size())
        caveWallBody.isDynamic = false
        caveWall.physicsBody = caveWallBody
        addChild(caveWall)
        
        let angleWallTexture = SKTexture(imageNamed: "angle-wall")
        let angleWall = SKSpriteNode(texture: angleWallTexture)
        angleWall.position = CGPoint(x: 200, y: 643)
        let angleWallBody = SKPhysicsBody(texture: angleWallTexture, size: angleWallTexture.size())
        angleWallBody.isDynamic = false
        angleWallBody.restitution = 0.85
        angleWall.physicsBody = angleWallBody
        addChild(angleWall)
        
        let switchWall1 = SKSpriteNode(color: .white, size: CGSize(width: 16, height: 44))
        switchWall1.position = CGPoint(x: 286, y: 790)
        let switchWall1Body = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 44))
        switchWall1Body.isDynamic = false
        switchWall1.physicsBody = switchWall1Body
        addChild(switchWall1)
        
        let switchWall2 = SKSpriteNode(color: .white, size: CGSize(width: 16, height: 44))
        switchWall2.position = CGPoint(x: 380, y: 810)
        let switchWall2Body = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 44))
        switchWall2Body.isDynamic = false
        switchWall2.physicsBody = switchWall2Body
        addChild(switchWall2)
    }
}
