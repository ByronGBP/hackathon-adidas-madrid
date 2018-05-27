//
//  ARSceneDelegate.swift
//  hackathon-adidas-madrid
//
//  Created by Byron Bacusoy Pinela on 26/5/18.
//  Copyright © 2018 Byron Bacusoy Pinela. All rights reserved.
//
//
//  ViewController+ARSCNViewDelegate.swift
//  ARKitPoc
//
//  Created by Marcen, Rafael on 4/7/18.
//  Copyright © 2018 adidas. All rights reserved.
//

import ARKit

extension ViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let pointOfView = self.sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        DispatchQueue.main.async {
            
            if self.forUpdate {
                self.updateFocusSquare()
            } else {
                let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
                let location = SCNVector3(transform.m41, transform.m42, transform.m43)
                let position = orientation + location
                let bullet = SCNNode(geometry: SCNSphere(radius: 0.01))
                bullet.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
                bullet.position = position
                let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))
                body.isAffectedByGravity = false
                bullet.physicsBody = body
                bullet.physicsBody?.applyForce(SCNVector3(orientation.x*self.power, orientation.y*self.power, orientation.z*self.power), asImpulse: true)
                bullet.physicsBody?.categoryBitMask = BitMaskCategory.bullet.rawValue
                bullet.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
                self.sceneView.scene.rootNode.addChildNode(bullet)
                bullet.runAction(
                    SCNAction.sequence([SCNAction.wait(duration: 0.1),
                                        SCNAction.removeFromParentNode()])
                )
            }
        }
        
        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        let baseIntensity: CGFloat = 40
        let lightingEnvironment = sceneView.scene.lightingEnvironment
        if let lightEstimate = session.currentFrame?.lightEstimate {
            lightingEnvironment.intensity = lightEstimate.ambientIntensity / baseIntensity
        } else {
            lightingEnvironment.intensity = baseIntensity
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            self.Target = nodeA
        } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            self.Target = nodeB
        }
        
        
        DispatchQueue.main.async {
            if let _ = self.Target {
                self.Target?.removeFromParentNode()
                
                self.createNewBox()
                self.count = 0
                self.confettiAnimation()
            }
        }

    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            print("Surface loaded!")
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        updateQueue.async {
            if let _ = anchor as? ARPlaneAnchor {
                print ("UPDATED")
            } else {
                print ("No updated")
            }
        }
        
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) { }
        
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        /*
         Allow the session to attempt to resume after an interruption.
         This process may not succeed, so the app must be prepared
         to reset the session if the relocalizing status continues
         for a long time -- see `escalateFeedback` in `StatusViewController`.
         */
        return true
    }
}
