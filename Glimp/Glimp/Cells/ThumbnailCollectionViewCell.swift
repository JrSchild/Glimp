//
//  ThumbnailCollectionViewCell.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 04-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//
//  A cell for thumbnail. Implements different properties and methods for different types of cells.

import UIKit
import Parse

class ThumbnailCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var checkFriend: UIImageView!
    @IBOutlet weak var addFriendImage: UIImageView!
    @IBOutlet weak var requestInOverlay: UIImageView!
    @IBOutlet weak var requestOutOverlay: UIImageView!
    @IBOutlet weak var timerOverlay: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var isLoading: UIActivityIndicatorView!
    @IBOutlet weak var image: ThumbnailImageView!
    @IBOutlet weak var bottomOverlay: UIView!
    
    let calendar = NSCalendar.currentCalendar()
    var timer : NSTimer!
    var canSelect = false
    var isSelected = false
    var request: PFObject!
    let greyBackground = UIColor(red: CGFloat(228) / 255.0, green: CGFloat(228) / 255.0, blue: CGFloat(228) / 255.0, alpha: 1.0)
    
    // Show or hide selected-image.
    func setSelected() {
        if selected {
            checkFriend.hidden = false
        } else {
            checkFriend.hidden = true
        }
    }
    
    func isAddFriendButton() {
        backgroundColor = greyBackground
        addFriendImage.hidden = false
    }
    
    func setLabel(text: String) {
        label!.hidden = false
        label!.text = text
    }
    
    func setRandomBackgroundColor() {
        backgroundColor = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
    }
    
    // Work in Progress
    func setRequest(request: PFObject) {
        
        // Set request, calculate time left.
        self.request = request
        timerOverlay!.hidden = false
        timerLabel!.hidden = false
        
        let (currentTime, endTime) = getTimeLeft()!
        let width = (currentTime / endTime) * Float(self.frame.width)
        
        self.resetTimerOverlaySize()
        
        // Set frame of timerOverlay with width of 0, defer this until the cell is in the view.
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            let top = self.label!.frame.height
            self.timerOverlay!.frame = CGRect(x: 0, y: top, width: CGFloat(width), height: self.frame.height - top)
            
            // Start the animation.
            UIView.animateWithDuration(Double(endTime - currentTime), delay: 0, options: .CurveLinear, animations: {
                self.timerOverlay!.frame = CGRect(x: 0, y: top, width: self.frame.width, height: self.frame.height - top)
            }, completion: {(finished: Bool) -> Void in
                self.timerOverlay!.hidden = true
                self.timerLabel!.hidden = true
                self.resetTimerOverlaySize()
                self.request = nil
            })
        }
        
        // Start the clock.
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateTime", userInfo: nil, repeats: true)
    }
    
    func setImage(backgroundImage: PFFile) {
        backgroundColor = greyBackground
        isLoading!.hidden = false
        image!.hidden = false
        image!.file = backgroundImage
        image!.loadInBackground({(image, error) -> Void in
            self.isLoading!.hidden = true
        })
    }
    
    func updateTime() {
        let timeLeft = getTimeLeft()
        if timeLeft == nil {
            return
        }
        
        let (currentTime, endTime) = timeLeft!
        let elapsedTime = Int(endTime) - Int(currentTime)
        let hours = Int(elapsedTime / 3600)
        let minutes = Int((elapsedTime - hours * 3600) / 60)
        let seconds = Int(elapsedTime - hours * 3600 - minutes * 60)
        var strTimeLeft : String
        
        if hours > 0 {
            strTimeLeft = "\(hours)h\(minutes)m"
        } else if minutes > 0 {
            strTimeLeft = "\(minutes)m"
        } else {
            strTimeLeft = "\(seconds)s"
        }
        
        timerLabel!.text = strTimeLeft
    }
    
    func resetTimerOverlaySize() {
        self.timerOverlay!.frame = CGRect(x: 0, y: 0, width: 0, height: self.frame.height)
    }
    
    func getTimeLeft() -> (Float, Float)? {
        if request == nil {
            return nil
        }
        let currentTime = Float(calendar.components(.CalendarUnitSecond, fromDate: request.createdAt, toDate: NSDate(), options: nil).second)
        let endTime = Float(calendar.components(.CalendarUnitSecond, fromDate: request.createdAt, toDate: request["expiresAt"] as NSDate, options: nil).second)
        
        return (currentTime, endTime)
    }
    
    func reset() {
        label!.text = ""
        label!.hidden = true
        requestInOverlay!.hidden = true
        requestOutOverlay!.hidden = true
        addFriendImage!.hidden = true
        checkFriend!.hidden = true
        timerOverlay!.hidden = true
        selected = false
        request = nil
        timerLabel!.hidden = true
        timerLabel!.text = ""
        isLoading!.hidden = true
        image!.image = nil
        image!.hidden = true
        bottomOverlay!.hidden = true
        isSelected = false
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
}
