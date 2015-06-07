//
//  Collection.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 05-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import Foundation
import Parse

class Collection {
    var user: PFUser?
    
    init() {}
    
    func load() {
        return load(nil)
    }
    
    func load(callback: (() -> Void)!) {
        destroy()
        if let user = PFUser.currentUser() {
            self.user = user
            query(callback)
        }
    }
    
    func query(callback: (() -> Void)!) {
        callback()
    }
    
    func destroy() {
        user = nil
    }
}
