//
//  RefreshData.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 16-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//
//  Refreshes data in parallel, optional callback can be passed for when action is completed.

import Foundation

func RefreshData (callback: () -> Void) {
    let group = dispatch_group_create()
    
    // Load all data in parallel, use dispatch to keep track of finished requests.
    dispatch_group_enter(group)
    Friends.load({
        dispatch_group_leave(group)
    })
    
    dispatch_group_enter(group)
    Requests.load({
        Friends.sort()
        dispatch_group_leave(group)
    })
    
    dispatch_group_enter(group)
    Glimps.load({
        Friends.sort()
        dispatch_group_leave(group)
    })
    
    // When all requests have been loaded, call the callback.
    dispatch_group_notify(group, dispatch_get_main_queue()) {
        callback()
    }
}

func RefreshData() {
    RefreshData({})
}
