//
//  GlimpsCollection.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 08-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import Foundation
import Parse

class GlimpsCollection : Collection {
    let calendar = NSCalendar.currentCalendar()
    var requestsIn = [PFObject]()
    var requestsOut = [PFObject]()
    var glimpsIn = [PFObject]()
    var glimpsOut = [PFObject]()
    
    override func query(callback: (() -> Void)!) {
        
        // Constraints for the query:
        // - requestsIn: toUser:me and expiresAt:beforeNow
        // - requestsOut: fromUser:me and expiresAt:beforeNow
        // - glimpsIn: toUser:me and photo:not-null
        // - glimpsOut: fromUser:me and photo:not-null
        
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
    
    func addRequestOut(request: PFObject) {
        let expiresAt = request["expiresAt"] as NSDate
        println(expiresAt)
        // http://stackoverflow.com/questions/27182023/getting-the-difference-between-two-nsdates-in-months-days-hours-minutes-seconds
        var seconds = calendar.components(NSCalendarUnit.CalendarUnitSecond, fromDate: NSDate(), toDate: expiresAt, options: nil).second
        
//        let delay = Double(seconds) * Double(NSEC_PER_SEC)
        let delay = 4.5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        requestsOut.append(request)
        println(requestsOut)
        dispatch_after(time, dispatch_get_main_queue()) {
            if let index = find(self.requestsOut, request) {
                self.requestsOut.removeAtIndex(index)
            }
            println(self.requestsOut)
        }
    }
    
    override func destroy() {
        super.destroy()
        requestsIn = []
        requestsOut = []
        glimpsIn = []
        glimpsOut = []
    }
}


