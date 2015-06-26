//
//  constants.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 16-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//
//  Constants file for magic numbers.

let NotificationDataGlimps = "Notification.DataGlimps"
let NotificationDataFriends = "Notification.DataFriends"
let NotificationDataFriendRequests = "Notification.DataFriendRequests"

let COLUMNS = CGFloat(4)
let HEADER_ROW_HEIGHT = CGFloat(46)
let ANSWER_TIMES_GLIMP_REQUEST = [
    [15,  "15 min", "15m"],
    [30,  "30 min", "30m"],
    [60,  "1 hour", "1H"],
    [120, "2 hour", "2H"],
    [300, "5 hour", "5H"]
]
let DEFAULT_ANSWER_TIME = 60