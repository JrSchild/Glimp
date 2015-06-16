//
//  Collection.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 05-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//
//  Base Collection class.

import Foundation
import Parse

class Collection {
    var user: PFUser?
    let notificationKey: String
    
    init(notificationKey: String) {
        self.notificationKey = notificationKey
    }
    
    func load() {
        return load(nil)
    }
    
    // Set the current user and run the query.
    func load(callback: (() -> Void)!) {
        if let user = PFUser.currentUser() {
            self.user = user
            query(callback)
        }
    }
    
    // Query method should be overwritten to run the load method.
    func query(callback: (() -> Void)!) {
        callback()
    }
    
    // Destroy must be overwritten to reset the data.
    func destroy() {
        user = nil
        self.notify()
    }
    
    func notify() {
        NSNotificationCenter.defaultCenter().postNotificationName(self.notificationKey, object: self)
    }
}
