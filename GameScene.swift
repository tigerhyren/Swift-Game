import SpriteKit
import GameplayKit

struct PhysicsCategory {
  static let None      : UInt32 = 0
  static let All       : UInt32 = UInt32.max
  static let Monster   : UInt32 = 0b1
  static let Projectile: UInt32 = 0b10
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
 
func - (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
 
func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}
 
func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}
 
#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
  return CGFloat(sqrtf(Float(a)))
}
#endif
 
extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
 
  func normalized() -> CGPoint {
    return self / length()
  }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
 
  // creates a physics body for the Soldier
  let player = SKSpriteNode(imageNamed: "player")
  var monstersDestroyed = 0
  
  override func didMoveToView(view: SKView) {
    backgroundColor = SKColor.whiteColor()
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    addChild(player)
    
    physicsWorld.gravity = CGVectorMake(0, 0)
    physicsWorld.contactDelegate = self
    
    runAction(SKAction.repeatActionForever(
      SKAction.sequence([
        SKAction.runBlock(addMonster),
        SKAction.waitForDuration(1.0)
      ])
    ))
    // set a background music
    let backgroundMusic = SKAudioNode(fileNamed: "Upright Funk 12.caf")
    backgroundMusic.autoplayLooped = true
    addChild(backgroundMusic)
    
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }
   
  func random(min min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }

  func addMonster() {
   
    // create enemy
    let monster = SKSpriteNode(imageNamed: "monster")
   
    monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size)
    monster.physicsBody?.dynamic = true
    monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
    monster.physicsBody?.collisionBitMask = PhysicsCategory.None
   
    // determine where to spawn the monster along the Y axis
    let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
   
    monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
   
    addChild(monster)
   
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
   
    // create the actions for the game
    let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()
    let loseAction = SKAction.runBlock() {
    let reveal = SKTransition.flipHorizontalWithDuration(0.5)
    let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    monster.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
   
  }

  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {

    // choose one of the touches to work with
    guard let touch = touches.first else {
      return
    }
    let touchLocation = touch.locationInNode(self)
   
    // set up initial location of projectile
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position
   
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.dynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
    projectile.physicsBody?.usesPreciseCollisionDetection = true
   
    let offset = touchLocation - projectile.position
   
    if (offset.x < 0) { return }
   
    addChild(projectile)
   
    // Get the direction of where to shoot
    let direction = offset.normalized()
   
    // Make it shoot far enough to be guaranteed off screen
    let shootAmount = direction * 1000
   
    let realDest = shootAmount + projectile.position
   
    // create the actions
    let actionMove = SKAction.moveTo(realDest, duration: 2.0)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    
    // run the sound effect
    runAction(SKAction.playSoundFileNamed("Golf Hit.caf", waitForCompletion: false))
   
  }
  
  func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
    print("Hit")
    projectile.removeFromParent()  // remove the projectile
    monster.removeFromParent()     // remove the monster
  }
  
  func didBeginContact(contact: SKPhysicsContact) {

    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
   
    if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
        (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
      projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, monster: secondBody.node as! SKSpriteNode)
    }
    
    monstersDestroyed++
    if (monstersDestroyed > 30) {
      let reveal = SKTransition.flipHorizontalWithDuration(0.5)
      let gameOverScene = GameOverScene(size: self.size, won: true)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }

   
  }
  
}
