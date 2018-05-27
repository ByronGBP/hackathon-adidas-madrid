//
//  ViewControllerOne.swift
//  hackathon-adidas-madrid
//
//  Created by Byron Bacusoy Pinela on 27/5/18.
//  Copyright © 2018 Byron Bacusoy Pinela. All rights reserved.
//

import UIKit

class ViewControllerOne: UIViewController {

    @IBAction func actionThing(_ sender: Any) {
        buttonLayout.alpha = 0.5
        print("topo")
    }
    @IBOutlet weak var buttonLayout: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
