//
//  ViewController.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 01-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class LoginViewController: UIViewController, PFLogInViewControllerDelegate {
    
    var logInController : PFLogInViewController!
    
    override func viewDidAppear(animated: Bool) {
        
        if var currentUser = PFUser.currentUser() {
            self.performSegueWithIdentifier("dismissLogin", sender: nil)
        } else {
            logInController = PFLogInViewController()
            logInController.delegate = self
            presentViewController(logInController, animated: false, completion: nil)
        }
    }
    
    func logInViewController(controller: PFLogInViewController, didLogInUser user: PFUser!) -> Void {
        dismissViewControllerAnimated(false, completion: nil)
    }
}
