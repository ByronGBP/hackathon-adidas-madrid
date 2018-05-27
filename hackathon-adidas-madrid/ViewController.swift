//
//  ViewController.swift
//  hackathon-adidas-madrid
//
//  Created by Byron Bacusoy Pinela on 26/5/18.
//  Copyright © 2018 Byron Bacusoy Pinela. All rights reserved.
//

import UIKit
import ARKit

enum BitMaskCategory: Int {
    case bullet = 2
    case target = 3
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {
    
    
    @IBOutlet weak var sceneView: ARSceneView!
    
    
    var positionBox: SCNNode! = nil
    var lenghtSize: Float! = nil
    let power: Float = 50
    var fieldArea = FieldArea()
    var planeArea: SCNNode! =  nil
    var forUpdate = true
    var Target: SCNNode? = nil
    

    let updateQueue = DispatchQueue(label: "com.madidas.adgile")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    var session: ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneView.session.delegate = self
        
        // self.objectInteration = ObjectInteration(sceneView: sceneView)
        setupCamera()
        sceneView.scene.rootNode.addChildNode(fieldArea)
        sceneView.automaticallyUpdatesLighting = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        
        sceneView.addGestureRecognizer(tapGesture)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the `ARSession`.
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    func updateFocusSquare() {
        
        // Perform hit testing only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let result = self.sceneView.smartHitTest(screenCenter) {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.fieldArea)
                self.fieldArea.state = .detecting(hitTestResult: result, camera: camera)
            }
        } else {
            updateQueue.async {
                self.fieldArea.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.fieldArea)
            }
        }
    }
    
    var count: Int = 0
    
    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        if (forUpdate) {
            forUpdate = false
            self.fieldArea.state = .fixed
            createPlane()
        }
        else {
            count += 1
            if (count == 2) {
                count = 0
                self.planeArea.enumerateChildNodes { (node, _) in
                    node.removeFromParentNode()
                }
                confettiAnimation()
                createNewBox()
            }
        }
    }
    
    func confettiAnimation() {
        guard let pointOfView = self.sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let position = orientation + location
        
        let mockThing = SCNNode(geometry: SCNSphere(radius: 1))
        let confetti = SCNParticleSystem(named: "Media.scnassets/Confetti.scnp", inDirectory: nil)
        confetti?.loops = false
        confetti?.particleLifeSpan = 4
        confetti?.emitterShape = mockThing.geometry
        let confettiNode = SCNNode()
        guard let _ = confetti else { return }
        confettiNode.addParticleSystem(confetti!)
        confettiNode.position = position
        self.sceneView.scene.rootNode.addChildNode(confettiNode)
    }
    
    func createNewBox() {
        let maxX = planeArea.boundingBox.max.x * 0.8
        let maxY = planeArea.boundingBox.max.y * 0.8
        // let maxZ = planeArea.boundingBox.max.z * 0.8
        let minX = planeArea.boundingBox.min.x * 0.8
        let minY = planeArea.boundingBox.min.y * 0.8
        // let minZ = planeArea.boundingBox.min.z * 0.8
        let boxNode = SCNNode(geometry: SCNSphere(radius: CGFloat(0.1)))
        planeArea.addChildNode(boxNode)
        let randomX = randomBetweenNumbers(firstNum: CGFloat(maxX), secondNum: CGFloat(minX))
        let randomY = randomBetweenNumbers(firstNum: CGFloat(maxY), secondNum: CGFloat(minY))
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        boxNode.geometry?.firstMaterial?.specular.contents = UIColor.white

        boxNode.transform.m41 = Float(randomX)
        boxNode.transform.m42 = Float(randomY)
        
        boxNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: boxNode, options: nil))
        boxNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        boxNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
    }
    
    private func createPlane() {
        let w = self.fieldArea.boundingBox.max.x * 2
        let h = self.fieldArea.boundingBox.max.z * 2
        planeArea = SCNNode(geometry: SCNPlane(width: CGFloat(w), height: CGFloat(h)))
        planeArea.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        let position = SCNVector3(self.fieldArea.position.x, self.fieldArea.position.y, self.fieldArea.position.z)
        let scale = SCNVector3(self.fieldArea.scale.x, self.fieldArea.scale.y, self.fieldArea.scale.z)
        planeArea.position = position
        planeArea.rotation = fieldArea.rotation
        planeArea.scale = scale
        planeArea.geometry?.firstMaterial?.isDoubleSided = true
        planeArea.eulerAngles =  SCNVector3(90.degreesToRadians, 0, 0)
        self.sceneView.scene.rootNode.addChildNode(planeArea)
    }
    
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, right.y, left.z + right.z)
}

func >(left: SCNVector3, right: SCNVector3) -> Bool {
    return left.x > right.x && left.y > right.y
}

func <(left: SCNVector3, right: SCNVector3) -> Bool {
    return left.x < right.x && left.y < right.y
}





