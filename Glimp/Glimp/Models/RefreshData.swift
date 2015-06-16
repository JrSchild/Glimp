//
//  RefreshData.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 16-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import Foundation

func RefreshData (callback: () -> Void) {
    let group = dispatch_group_create()
    
    dispatch_group_enter(group)
    Friends.load({
        dispatch_group_leave(group)
    })
    
    dispatch_group_enter(group)
    Requests.load({
        dispatch_group_leave(group)
    })
    
    dispatch_group_enter(group)
    Glimps.load({
        dispatch_group_leave(group)
    })
    
    dispatch_group_notify(group, dispatch_get_main_queue()) {
        callback()
    }
}

func RefreshData() {
    RefreshData({})
}
