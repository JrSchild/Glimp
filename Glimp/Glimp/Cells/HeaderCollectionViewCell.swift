//
//  HeaderCollectionViewCell2.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 12-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit

class HeaderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var headerText: UILabel!
    @IBOutlet weak var timerButton: UIButton!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let times = [
        [15,  "15 min", "15m"],
        [30,  "30 min", "30m"],
        [60,  "1 hour", "1H"],
        [120, "2 hour", "2H"],
        [300, "5 hour", "5H"]
    ]
    var time = 60
    
    func setTimerButton() {
        timerButton!.hidden = false
        timerButton!.layer.borderColor = UIColor.blackColor().CGColor
        timerButton!.layer.borderWidth = 1
        
        time = defaults.objectForKey("countdown-time") as? Int ?? time
        updateTimeButton()
    }
    
    func updateTimeButton() {
        let timeIndex = times.filter({ $0[0] == self.time })
        
        if timeIndex.count > 0 {
            timerButton!.setTitle(timeIndex[0][2] as? String, forState: .Normal)
        }
    }
    
    @IBAction func selectTime(sender: UIButton) {
        let sheet: UIActionSheet = UIActionSheet();
        sheet.delegate = self;
        for time in times {
            sheet.addButtonWithTitle(time[1] as String);
        }
        sheet.addButtonWithTitle("Cancel");
        sheet.cancelButtonIndex = times.count;
        sheet.showInView(self.superview);
    }
    
    func reset() {
        timerButton!.hidden = true
    }
}

extension HeaderCollectionViewCell: UIActionSheetDelegate {
    
    // When an actionsheet is closed.
    func actionSheet(sheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex < times.count {
            time = times[buttonIndex][0] as Int
            defaults.setObject(time, forKey: "countdown-time")
            defaults.synchronize()
            updateTimeButton()
        }
    }
}
