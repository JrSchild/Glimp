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

class LoginViewController: UIViewController {
    
    var logInController: PFLogInViewController!
    var signUpViewController: PFSignUpViewController!
    
    override func viewDidAppear(animated: Bool) {
        
        // If a user was already logged in on the device.
        if let currentUser = PFUser.currentUser() {
            
            // Always update the Installation with the latest user.
            let installation = PFInstallation.currentInstallation()
            installation["User"] = PFUser.currentUser()
            installation.saveInBackground()
            
            // Set an empty array for the friends if isn't set yet.
            if currentUser.objectForKey("Friends") == nil {
                currentUser["Friends"] = []
                currentUser.save()
            }
            
            // Reload all data in parallel and move to the HomeView
            RefreshData({ () -> Void in
                self.performSegueWithIdentifier("dismissLogin", sender: nil)
            })
            
        // Otherwise show the login view.
        } else {
            let logo = UIImageView(image: UIImage(named: "login-logo"))
            
            // Attach custom image and delegate for callback to SignUpView.
            signUpViewController = PFSignUpViewController()
            signUpViewController.delegate = self
            (signUpViewController.signUpView.logo as UIImageView).image = logo.image
            
            // Attach custom image, delegate and SignUpView to LogInView.
            logInController = PFLogInViewController()
            logInController.delegate = self
            logInController.signUpController = signUpViewController
            logInController.logInView.logo = logo
            presentViewController(logInController, animated: false, completion: nil)
        }
    }
    
}

// Custom callback for logging in.
extension LoginViewController: PFLogInViewControllerDelegate {
    func logInViewController(controller: PFLogInViewController, didLogInUser user: PFUser!) -> Void {
        dismissViewControllerAnimated(false, completion: nil)
    }
}

// Custom callback for signing up.
extension LoginViewController: PFSignUpViewControllerDelegate {
    func signUpViewController(signUpController: PFSignUpViewController!, didSignUpUser user: PFUser!) {
        dismissViewControllerAnimated(false, completion: nil)
    }
}
