//
//  HeaderCollectionViewCell2.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 12-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//
//  A Header Cell for in the CollectionView.

import UIKit

class HeaderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var headerText: UILabel!
    @IBOutlet weak var timerButton: UIButton!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    var time = DEFAULT_ANSWER_TIME
    
    // Show the button to change the time-to-reply for a Glimp-Request.
    func setTimerButton() {
        timerButton!.hidden = false
        timerButton!.layer.borderColor = UIColor.blackColor().CGColor
        timerButton!.layer.borderWidth = 1
        
        time = defaults.objectForKey("countdown-time") as? Int ?? time
        updateTimeButton()
    }
    
    // Change the text of the timer button.
    func updateTimeButton() {
        let timeIndex = ANSWER_TIMES_GLIMP_REQUEST.filter({ $0[0] == self.time })
        
        if timeIndex.count > 0 {
            timerButton!.setTitle(timeIndex[0][2] as? String, forState: .Normal)
        }
    }
    
    // Set the time for time-to-reply a Glimp-Request.
    @IBAction func selectTime(sender: UIButton) {
        let sheet: UIActionSheet = UIActionSheet();
        sheet.delegate = self;
        for time in ANSWER_TIMES_GLIMP_REQUEST {
            sheet.addButtonWithTitle(time[1] as String);
        }
        sheet.addButtonWithTitle("Cancel");
        sheet.cancelButtonIndex = ANSWER_TIMES_GLIMP_REQUEST.count;
        sheet.showInView(self.superview);
    }
    
    func reset() {
        timerButton!.hidden = true
    }
}

extension HeaderCollectionViewCell: UIActionSheetDelegate {
    
    // When an actionsheet is closed, set the new time and update the button.
    func actionSheet(sheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex < ANSWER_TIMES_GLIMP_REQUEST.count {
            time = ANSWER_TIMES_GLIMP_REQUEST[buttonIndex][0] as Int
            defaults.setObject(time, forKey: "countdown-time")
            defaults.synchronize()
            updateTimeButton()
        }
    }
}
