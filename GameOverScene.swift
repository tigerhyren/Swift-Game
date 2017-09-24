

import Foundation
import SpriteKit

// this file sets what happens in each game over scenario (win or lose)
class GameOverScene: SKScene {
 
  init(size: CGSize, won:Bool) {
 
    super.init(size: size)
 
    backgroundColor = SKColor.whiteColor()
 
    let message = won ? "You Won against the monsters" : "The monsters got to the prison"
 
    let label = SKLabelNode(fontNamed: "Calibri")
    label.text = message
    label.fontSize = 40
    label.fontColor = SKColor.blackColor()
    label.position = CGPoint(x: size.width/2, y: size.height/2)
    addChild(label)
 
    runAction(SKAction.sequence([
      SKAction.waitForDuration(3.0),
      SKAction.runBlock() {
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        let scene = GameScene(size: size)
        self.view?.presentScene(scene, transition:reveal)
      }
    ]))
 
  }
 
  required init(coder aDecoder: NSCoder) {
    fatalError("there has been an error")       // if there is an error with the code
  }
}