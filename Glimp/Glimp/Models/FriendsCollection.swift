//
//  FriendsCollection.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 05-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import Foundation
import Parse

class FriendsCollection : Collection {
    var friends = [PFObject]()
    let friendsUpdated = Event<[PFObject]>()
    
    override func query(callback: (() -> Void)!) {
        let query = PFUser.query()
        query.whereKey("objectId", containedIn: user!["Friends"] as? [AnyObject]!)
        query.whereKey("Friends", equalTo: user!.objectId)
        query.whereKey("objectId", notEqualTo: user!.objectId)
        query.findObjectsInBackgroundWithBlock({ (friends: [AnyObject]?, error: NSError?) -> Void in
            if error != nil {
                println("ERROR \(error)")
            }
            if friends != nil {
                self.friends = friends as [PFObject]
            }
            self.friendsUpdated.raise(self.friends)
            callback()
        })
    }
    
    override func destroy() {
        super.destroy()
        friends = []
    }
    
    func findById(objectId: String) -> PFObject? {
        for friend in friends {
            if friend.objectId == objectId {
                return friend
            }
        }
        return nil
    }
}
