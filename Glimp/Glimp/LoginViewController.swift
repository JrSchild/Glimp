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

class LoginViewController: UIViewController, PFLogInViewControllerDelegate {
    
    var logInController : PFLogInViewController!
    
    override func viewDidLoad() {
//        PFUser.logOut()
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if let currentUser = PFUser.currentUser() {
            
            // https://www.parse.com/questions/build-friend-relations-into-pfuser
            Friends.load({
                Requests.load({
                    Glimps.load({
                        self.performSegueWithIdentifier("dismissLogin", sender: nil)
                    })
                })
            })
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
