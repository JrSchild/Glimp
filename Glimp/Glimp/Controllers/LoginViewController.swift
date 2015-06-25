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

var Friends = FriendsCollection()
var Requests = FriendRequestsCollection()
var Glimps = GlimpsCollection()

class LoginViewController: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    
    var logInController: PFLogInViewController!
    var signUpViewController: PFSignUpViewController!
    
    override func viewDidAppear(animated: Bool) {
        
        if let currentUser = PFUser.currentUser() {
            let installation = PFInstallation.currentInstallation()
            installation["User"] = PFUser.currentUser()
            installation.saveInBackground()

            if currentUser.objectForKey("Friends") == nil {
                currentUser["Friends"] = []
                currentUser.save()
            }
            
            RefreshData({ () -> Void in
                self.performSegueWithIdentifier("dismissLogin", sender: nil)
            })
        } else {
            signUpViewController = PFSignUpViewController()
            signUpViewController.delegate = self
            
            logInController = PFLogInViewController()
            logInController.delegate = self
            logInController.signUpController = signUpViewController
            presentViewController(logInController, animated: false, completion: nil)
        }
    }
    
    func logInViewController(controller: PFLogInViewController, didLogInUser user: PFUser!) -> Void {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    func signUpViewController(signUpController: PFSignUpViewController!, didSignUpUser user: PFUser!) {
        dismissViewControllerAnimated(false, completion: nil)
    }
}
