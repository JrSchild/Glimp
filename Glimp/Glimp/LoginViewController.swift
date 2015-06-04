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

var Friends = [PFObject]()
var Requests = [AnyObject]()

class LoginViewController: UIViewController, PFLogInViewControllerDelegate {
    
    var logInController : PFLogInViewController!
    
    override func viewDidLoad() {
        PFUser.logOut()
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if let currentUser = PFUser.currentUser() {
            
            // https://www.parse.com/questions/build-friend-relations-into-pfuser
            let query = PFUser.query()
            query.whereKey("objectId", containedIn: currentUser["Friends"] as? [AnyObject]!)
            query.whereKey("Friends", equalTo: currentUser.objectId)
            query.whereKey("objectId", notEqualTo: currentUser.objectId)
            query.findObjectsInBackgroundWithBlock({ (friends: [AnyObject]?, error: NSError?) -> Void in
                if error != nil {
                    println("ERROR \(error)")
                }
                Friends = (friends ?? Friends) as [PFObject]
                
                // Retrieve all friend requests.
                let friendRequestQuery = PFQuery(className: "FriendRequest")
                friendRequestQuery.whereKey("toUser", equalTo: currentUser.objectId)
                friendRequestQuery.includeKey("fromUser")
                friendRequestQuery.findObjectsInBackgroundWithBlock({ (requests: [AnyObject]?, error: NSError?) -> Void in
                    if error != nil {
                        println("ERROR \(error)")
                    }
                    
                    // Filter requests and delete the doubles or ones already in friend lists.
                    var tmpRequests = [String:Bool]()
                    for request in requests! {
                        let requestFromUser = request["fromUser"] as PFObject
                        let fromUserId = requestFromUser.objectId
                        if tmpRequests[fromUserId] != nil || contains(currentUser["Friends"] as [String], fromUserId) {
                            request.deleteInBackground()
                        }
                        tmpRequests[fromUserId] = true
                        Requests.append(request)
                    }
                    
                    self.performSegueWithIdentifier("dismissLogin", sender: nil)
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
