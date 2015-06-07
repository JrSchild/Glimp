//
//  FriendRequestsCollection.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 05-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import Foundation
import Parse

class FriendRequestsCollection : Collection {
    var requestsIn = [PFObject]()
    var requestsOut = [PFObject]()
    
    override func query(callback: (() -> Void)!) {
        
        // Retrieve all in- and outcoming requests.
        let requestsInQuery = PFQuery(className: "FriendRequest")
        requestsInQuery.whereKey("toUser", equalTo: user!)
        
        let requestsOutQuery = PFQuery(className: "FriendRequest")
        requestsOutQuery.whereKey("fromUser", equalTo: user!)
        
        let query = PFQuery.orQueryWithSubqueries([requestsInQuery, requestsOutQuery])
        query.includeKey("fromUser")
        query.includeKey("toUser")
        query.findObjectsInBackgroundWithBlock({ (requests: [AnyObject]?, error: NSError?) -> Void in
            if error != nil {
                println("ERROR \(error)")
            }
            
            // Filter requests and delete the doubles or ones already in friend lists.
            if requests != nil {
                let friends = self.user!["Friends"] as [String]
                var tmpRequestsIn = [String:Bool]()
                var tmpRequestsOut = [String:Bool]()
                
                for request in requests! {
                    let requestFromUser = request["fromUser"] as PFObject
                    let requestToUser = request["toUser"] as PFObject
                    let fromUserId = requestFromUser.objectId
                    let toUserId = requestToUser.objectId
                    
                    // Request is to me
                    if toUserId == self.user!.objectId {
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
    
    func invite(username: String) {}
    
    override func destroy() {
        super.destroy()
        requestsIn = []
        requestsOut = []
    }
}
