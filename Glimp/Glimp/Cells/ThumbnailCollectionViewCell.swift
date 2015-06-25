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
    var isSelected = false
    var request: PFObject!
    var friend: PFObject!
    let greyBackground = UIColor(red: CGFloat(228) / 255.0, green: CGFloat(228) / 255.0, blue: CGFloat(228) / 255.0, alpha: 1.0)
    
    // Show or hide selected-image.
    func setCheckmark() {
        if selected {
            checkFriend.hidden = false
        } else {
            checkFriend.hidden = true
        }
    }
    
    // Shows a grey background with the plus icon for adding a friend.
    func isAddFriendButton() {
        backgroundColor = greyBackground
        addFriendImage.hidden = false
    }
    
    func setLabel(text: String) {
        label!.hidden = false
        label!.text = text
    }
    
    // Set a pending request with timer and animating overlay.
    func setRequest(request: PFObject) {
        
        // Set request, calculate time left.
        self.request = request
        timerOverlay!.hidden = false
        timerLabel!.hidden = false
        
        // Get the time left, current width of overlay and top of the overlay.
        let (currentTime, endTime) = getTimeLeft()!
        let width = (currentTime / endTime) * Float(self.frame.width)
        let top = self.label!.frame.height
        
        // Set the initial position and size of overlay.
        self.timerOverlay!.frame = CGRect(x: 0, y: top, width: CGFloat(width), height: self.frame.height - top)
        
        // Start the animation.
        UIView.animateWithDuration(Double(endTime - currentTime), delay: 0, options: .CurveLinear, animations: {
            self.timerOverlay!.frame = CGRect(x: 0, y: top, width: self.frame.width, height: self.frame.height - top)
        }, completion: {(finished: Bool) -> Void in
            
            // When the animation is finished, remove the request object and hide the overlay.
            if finished {
                self.timerOverlay!.hidden = true
                self.timerLabel!.hidden = true
                self.timerOverlay!.frame = CGRect(x: 0, y: top, width: 0, height: self.frame.height - top)
                self.request = nil
            }
        })
        
        // Start the clock, update every second.
        updateTime()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateTime", userInfo: nil, repeats: true)
    }
    
    // Set a file on backgroundImage, show a grey background and spinner while it's loading.
    func setImage(backgroundImage: PFFile) {
        backgroundColor = greyBackground
        isLoading!.hidden = false
        image!.hidden = false
        image!.file = backgroundImage
        image!.loadInBackground({(image, error) -> Void in
            self.isLoading!.hidden = true
        })
    }
    
    // Set an incoming Glimp-Request: The label, timer and background picture.
    func setGlimpRequestIn(request: PFObject) {
        setLabel(request["fromUser"]!["username"]! as String)
        setRequest(request)
        if let photo = request["fromUser"]!["photo"] as? PFFile {
            setImage(photo)
        }
    }
    
    // Update the countdown timer.
    func updateTime() {
        let timeLeft = getTimeLeft()
        
        if timeLeft == nil {
            return
        }
        
        let (currentTime, endTime) = timeLeft!
        let elapsedTime = Int(endTime) - Int(currentTime)
        
        // Calculate hours, minutes and seconds left.
        let hours = Int(elapsedTime / 3600)
        let minutes = Int((elapsedTime - hours * 3600) / 60)
        let seconds = Int(elapsedTime - hours * 3600 - minutes * 60)
        var strTimeLeft : String
        
        // Format the string for time left.
        if hours > 0 {
            strTimeLeft = "\(hours)h\(minutes)m"
        } else if minutes > 0 {
            strTimeLeft = "\(minutes)m"
        } else {
            strTimeLeft = "\(seconds)s"
        }
        
        timerLabel!.text = strTimeLeft
    }
    
    // Returns the current- and endtime of the cell's request object.
    func getTimeLeft() -> (Float, Float)? {
        if request == nil {
            return nil
        }
        let currentTime = Float(calendar.components(.CalendarUnitSecond, fromDate: request.createdAt, toDate: NSDate(), options: nil).second)
        let endTime = Float(calendar.components(.CalendarUnitSecond, fromDate: request.createdAt, toDate: request["expiresAt"] as NSDate, options: nil).second)
        
        return (currentTime, endTime)
    }
    
    // Set everything back to the initial state, used for re-using the cell.
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
        friend = nil
        timerLabel!.hidden = true
        timerLabel!.text = ""
        isLoading!.hidden = true
        image!.image = nil
        image!.file = nil
        image!.hidden = true
        bottomOverlay!.hidden = true
        isSelected = false
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
}
