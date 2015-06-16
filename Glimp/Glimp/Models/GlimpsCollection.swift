//
//  GlimpsCollection.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 08-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//
//  Keep and maintain a list of glimps (sent + received) and glimp requests (sent + received).

import Foundation
import Parse

class GlimpsCollection : Collection {
    let calendar = NSCalendar.currentCalendar()
    var requestsIn = [PFObject]()
    var requestsOut = [PFObject]()
    var glimpsIn = [PFObject]()
    var glimpsOut = [PFObject]()
    
    override func query(callback: (() -> Void)!) {
        
        // Retrieve all in- and outcoming requests, plus received and sent Glimps.
        let requestsInQuery = PFQuery(className: "Glimp")
            .whereKey("toUser", equalTo: user!)
            .whereKey("expiresAt", greaterThan: NSDate())
            .whereKeyDoesNotExist("photo")
        
        let requestsOutQuery = PFQuery(className: "Glimp")
            .whereKey("fromUser", equalTo: user!)
            .whereKey("expiresAt", greaterThan: NSDate())
            .whereKeyDoesNotExist("photo")
        
        let glimpsInQuery = PFQuery(className: "Glimp")
            .whereKey("toUser", equalTo: user!)
            .whereKeyExists("photo")
        
        let glimpsOutQuery = PFQuery(className: "Glimp")
            .whereKey("fromUser", equalTo: user!)
            .whereKeyExists("photo")
        
        let query = PFQuery.orQueryWithSubqueries([requestsInQuery, requestsOutQuery, glimpsInQuery, glimpsOutQuery])
            .includeKey("fromUser")
            .includeKey("toUser")
        
        query.findObjectsInBackgroundWithBlock({ (glimps: [AnyObject]?, error: NSError?) -> Void in
            if error != nil {
                println("ERROR \(error)")
            }
            self.requestsIn = []
            self.requestsOut = []
            self.glimpsIn = []
            self.glimpsOut = []
            
            // Place each glimp in their corresponding array. If a photo is set it is a glimp, otherwise it's a request.
            if glimps != nil {
                for glimp in glimps! as [PFObject] {
                    let fromUserId = glimp["fromUser"].objectId
                    let toUserId = glimp["toUser"].objectId

                    if glimp.objectForKey("photo") != nil {
                        if toUserId == self.user!.objectId {
                            self.glimpsOut.append(glimp)
                        } else {
                            self.glimpsIn.append(glimp)
                        }
                    } else {
                        if toUserId == self.user!.objectId {
                            self.addRequestIn(glimp)
                        } else {
                            self.addRequestOut(glimp)
                        }
                    }
                }
            }
            callback()
        })
    }
    
    func sendRequests(friends: [String], time: Int, callback: (() -> Void)) {
        let expiresAt = NSDate().dateByAddingTimeInterval((Double(time) * 60.0))
        let user = PFUser.currentUser()
        var requests = [PFObject]()
        for friend in friends {
            if let friend = Friends.findById(friend) {
                var request = PFObject(className: "Glimp")
                request["fromUser"] = user!
                request["toUser"] = friend
                request["expiresAt"] = expiresAt
                requests.append(request)
            }
        }
        
        println("Send requests to: \(friends)")
        PFObject.saveAllInBackground(requests, block: { (success, error) -> Void in
            println("Saved glimp requests")
            for request in requests {
                self.addRequestOut(request)
            }
            callback()
        })
    }
    
    func answerGlimpRequestIn(request: PFObject, image: UIImage, callback: () -> Void) {
        if contains(requestsIn, request) {
            request["photo"] = PFFile(data: UIImageJPEGRepresentation(image, 0.9))
            request.saveInBackgroundWithBlock({ (success, error) -> Void in
                if success {
                    if let index = find(self.requestsIn, request) {
                        self.requestsIn.removeAtIndex(index)
                        self.glimpsOut.append(request)
                    }
                }
                callback()
            })
        }
    }
    
    func addRequestOut(request: PFObject) {
        let expiresAt = request["expiresAt"] as NSDate
        let seconds = calendar.components(NSCalendarUnit.CalendarUnitSecond, fromDate: NSDate(), toDate: expiresAt, options: nil).second

        let delay = Double(seconds) * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        requestsOut.append(request)
        dispatch_after(time, dispatch_get_main_queue()) {
            if let index = find(self.requestsOut, request) {
                self.requestsOut.removeAtIndex(index)
            }
        }
    }
    
    func addRequestIn(request: PFObject) {
        let expiresAt = request["expiresAt"] as NSDate
        let seconds = calendar.components(NSCalendarUnit.CalendarUnitSecond, fromDate: NSDate(), toDate: expiresAt, options: nil).second
        
        let delay = Double(seconds) * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        requestsIn.append(request)
        dispatch_after(time, dispatch_get_main_queue()) {
            if let index = find(self.requestsOut, request) {
                self.requestsIn.removeAtIndex(index)
            }
        }
    }
    
    func findRequestOut(friend: PFObject) -> PFObject? {
        for request in requestsOut {
            if request["toUser"].objectId == friend.objectId {
                return request
            }
        }
        return nil
    }
    
    // Return a list of glimps the current user shares with given friend.
    func findSharedGlimps(friend: PFObject) -> [PFObject] {
        var glimps = [PFObject]()
        
        if self.user == nil {
            return glimps
        }
        
        for glimp in glimpsIn {
            if glimp["toUser"].objectId == friend.objectId {
                glimps.append(glimp)
            }
        }
        for glimp in glimpsOut {
            if glimp["fromUser"].objectId == friend.objectId {
                glimps.append(glimp)
            }
        }
        
        glimps.sort({ $1.createdAt.compare($0.createdAt) == NSComparisonResult.OrderedAscending })
        
        return glimps
    }
    
    override func destroy() {
        super.destroy()
        requestsIn = []
        requestsOut = []
        glimpsIn = []
        glimpsOut = []
    }
}
