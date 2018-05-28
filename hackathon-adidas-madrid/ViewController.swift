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
    
    @IBOutlet weak var infoImage: UIImageView!
    @IBOutlet weak var counterTimer: UILabel!
    @IBOutlet weak var cronoLabel: UILabel!

    @IBOutlet weak var resultImage: UIImageView!
    @IBOutlet weak var secondLabels: UILabel!
    
    
    @IBOutlet weak var leftLabel: UILabel!
    
    @IBOutlet weak var sceneView: ARSceneView!
    
    
    var timer = Timer()
    var seconds = 3
    
    var counter = 0
    
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
    
    var infoTimer = Timer()
    
    var session: ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneView.session.delegate = self

        setupCamera()
        sceneView.scene.rootNode.addChildNode(fieldArea)
        sceneView.automaticallyUpdatesLighting = false
        
        counterTimer.text = ""
        cronoLabel.text = ""
        
    
        infoTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: (#selector(desapearView)), userInfo: nil, repeats: true)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        
        sceneView.addGestureRecognizer(tapGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the `ARSession`.
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    
    var centinella = 10;
    @objc func desapearView() {
        centinella -= 1
        
        if (centinella < 0) {
            infoImage.alpha -= 0.05
        }
        
        if infoImage.alpha < 0 {
            infoTimer.invalidate()
            
        }
    }
    
    @objc func appearView() {
        resultImage.alpha += 0.1
        secondLabels.alpha += 0.1

        if infoImage.alpha > 1 {
            infoTimer.invalidate()
        }
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
    
    func runTimerCounter() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    
    func runTimerCrono() {
        seconds = 1
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(updateCronoTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        
        counterTimer.text = "\(seconds)"
        seconds -= 1
        if (seconds < 0) {
 
            counterTimer.text = ""
            timer.invalidate()
            createNewBox()
            runTimerCrono()
        }
    }
    
//    let hours = Int(time) / 3600
//    let minutes = Int(time) / 60 % 60
//    let seconds = Int(time) % 60
//    return String(format:”%02i:%02i:%02i”, hours, minutes, seconds)
    
    @objc func updateCronoTimer() {
        cronoLabel.text = "\(seconds)"
        seconds += 1
        
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
            runTimerCounter()
        }
        else {
            // little hack in case colision fails during presentation :P
            count += 1
            if (count == 2) {
                count = 0
                self.planeArea.enumerateChildNodes { (node, _) in
                    node.removeFromParentNode()
                }
                updatedColision()
                confettiAnimation()
                createNewBox()
            }
        }
    }
    
    // what tha fack is this name?
    func updatedColision () {
        self.counter += 1
        self.leftLabel.text = "\(self.counter) / 12"
        
        if (counter == 12) {
            secondLabels.text = "\(seconds)"
            // self.confettiAnimation()
            timer.invalidate()
                    infoTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: (#selector(appearView)), userInfo: nil, repeats: true)
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



