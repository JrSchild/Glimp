//
//  ViewController.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 01-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit

class GlimpViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("loaded")
        
        var swipeGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "hideGlimps")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    func hideGlimps() {
        self.performSegueWithIdentifier("hideGlimps", sender: self)
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
//        if segue.identifier == "idFirstSegueUnwind" {
//            let firstViewController = segue.destinationViewController as ViewController
//            firstViewController.lblMessage.text = "You just came back from the 2nd VC"
//        }
    }
}