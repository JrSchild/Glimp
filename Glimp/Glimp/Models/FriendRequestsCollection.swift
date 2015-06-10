//
//  FriendRequestsCollection.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 05-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//
//  Keep and maintain a list of friends requests, in- and outcoming.

import Foundation
import Parse

class FriendRequestsCollection : Collection {
    var requestsIn = [PFObject]()
    var requestsOut = [PFObject]()
    
    override func query(callback: (() -> Void)!) {
        
        // A friend request is either sent from me, or to me.
        let requestsInQuery = PFQuery(className: "FriendRequest")
            .whereKey("toUser", equalTo: user!)

        let requestsOutQuery = PFQuery(className: "FriendRequest")
            .whereKey("fromUser", equalTo: user!)
        
        // Include the user objects.
        let query = PFQuery.orQueryWithSubqueries([requestsInQuery, requestsOutQuery])
            .includeKey("fromUser")
            .includeKey("toUser")
        
        query.findObjectsInBackgroundWithBlock({ (requests: [AnyObject]?, error: NSError?) -> Void in
            if error != nil {
                println("ERROR \(error)")
            }
            
            // Reset the data arrays.
            self.requestsIn = []
            self.requestsOut = []
            
            // Filter requests and delete the doubles or ones already in friend lists.
            if requests != nil {
                let friends = self.user!["Friends"] as [String]
                
                // A temporary dictionary is created to remove double invitations.
                var tmpRequestsIn = [String:Bool]()
                var tmpRequestsOut = [String:Bool]()
                
                for request in requests! {
                    let requestFromUser = request["fromUser"] as PFObject
                    let requestToUser = request["toUser"] as PFObject
                    let fromUserId = requestFromUser.objectId
                    let toUserId = requestToUser.objectId
                    
                    // Request is to me.
                    if toUserId == self.user!.objectId {
                        
                        // A request can be deleted when the id is already in the others' friends-list.
                        if tmpRequestsIn[fromUserId] != nil || contains(friends, fromUserId) {
                            request.deleteInBackground()
                        } else {
                            tmpRequestsIn[fromUserId] = true
                            self.requestsIn.append(request as PFObject)
                        }
                    
                    // Request is from me
                    } else if fromUserId == self.user!.objectId {
                        if tmpRequestsOut[toUserId] != nil || contains(requestToUser["Friends"] as [String], toUserId) {
                            request.deleteInBackground()
                        } else {
                            tmpRequestsOut[toUserId] = true
                            self.requestsOut.append(request as PFObject)
                        }
                    }
                }
            }
            callback()
        })
    }
    
    // Invite a friend by username.
    func invite(username: String, callback: ((success: Bool, error: String!) -> Void)) {
        
        // Find the user if he exists.
        var query = PFUser.query()
            .whereKey("username", equalTo: username)
        
        query.getFirstObjectInBackgroundWithBlock({ (friend: PFObject?, error: NSError?) -> Void in
            if error != nil {
                return callback(success: false, error: "Found error retrieving user: \(error)")
            }
            if friend == nil {
                return callback(success: false, error: "FriendNotFound")
            }
            
            if Requests.requestsOut.filter({ $0["toUser"].objectId == friend!.objectId}).count > 0 {
                return callback(success: false, error: "UserAlreadyFriends")
            }
            
            // Create the friendRequest object, set the properties and save it.
            var friendRequest = PFObject(className: "FriendRequest")
            friendRequest["fromUser"] = self.user!
            friendRequest["toUser"] = friend!
            friendRequest.saveInBackgroundWithBlock({ (_success: Bool, error: NSError!) -> Void in
                if error != nil {
                    return callback(success: false, error: "ServerError: \(error)")
                }
                Requests.requestsOut.append(friendRequest)
                
                // If current user didn't already have the requestee's id as friend, add it and save.
                if !contains(self.user!["Friends"] as [String], friend!.objectId) {
                    self.user!.addObject(friend!.objectId, forKey: "Friends")
                    self.user!.saveInBackground()
                }

                return callback(success: true, error: nil)
            })
        })
    }
    
    override func destroy() {
        super.destroy()
        requestsIn = []
        requestsOut = []
    }
}
