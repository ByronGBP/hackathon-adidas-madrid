//
//  ViewController.swift
//  hackathon-adidas-madrid
//
//  Created by Byron Bacusoy Pinela on 26/5/18.
//  Copyright © 2018 Byron Bacusoy Pinela. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = ARWorldTrackingConfiguration()
        self.sceneView.debugOptions = [ ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        
        self.sceneView.autoenablesDefaultLighting = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let concreteNode = SCNNode(geometry: SCNPlane(width: 1, height: 1))
        concreteNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        concreteNode.name = "plane"
        concreteNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        concreteNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        return concreteNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        print("updating floor's anchor...")
        node.enumerateChildNodes { (childNode, _) in
            if (childNode.name == "plane") {
                print("yes!")
                childNode.removeFromParentNode()
            }
        }
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
    }
    

}


extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

