//
//  FriendsCollection.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 05-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//
//  Keep and maintain a list of friends.

import Foundation
import Parse

class FriendsCollection : Collection {
    var friends = [PFObject]()
    
    init() {
        super.init(notificationKey: NotificationDataFriends)
    }
    
    override func query(callback: (() -> Void)!) {
        
        // Create query to retrieve all friends. Someone is a friend when current
        // user and target friend have each others ID in the Friends array.
        let query = PFUser.query()
            .whereKey("objectId", containedIn: user!["Friends"] as? [AnyObject]!)
            .whereKey("Friends", equalTo: user!.objectId)
            .whereKey("objectId", notEqualTo: user!.objectId)
        
        query.findObjectsInBackgroundWithBlock({ (friends: [AnyObject]?, error: NSError?) -> Void in
            if friends != nil {
                self.friends = friends as [PFObject]
            }
            
            // Notifify subscribers and run the callback.
            self.sort()
            self.notify()
            callback()
        })
    }
    
    override func destroy() {
        friends = []
        super.destroy()
    }
    
    func findById(objectId: String) -> PFObject? {
        for friend in friends {
            if friend.objectId == objectId {
                return friend
            }
        }
        return nil
    }
    
    // Sort friends: Most shared glimps to the top, but anyone with an outgoing request to the bottom.
    func sort() {
        friends.sort({ lhs, rhs in
            return Glimps.findSharedGlimps(lhs).count > Glimps.findSharedGlimps(rhs).count
        })
        friends.sort({ lhs, rhs in
            if Glimps.findGlimpRequestOut(rhs) != nil {
                return true
            }
            return Glimps.findSharedGlimps(lhs).count > Glimps.findSharedGlimps(rhs).count
        })
    }
}
