//
//  ThumbnailCollectionViewCell.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 04-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit
import Parse

class ThumbnailCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addFriendImage: UIImageView!
    @IBOutlet weak var requestInOverlay: UIImageView!
    @IBOutlet weak var requestOutOverlay: UIImageView!
    @IBOutlet weak var timerOverlay: UIView!
    
    var timer: Int?
    var canSelect = false
    var isSelected = false
    var request: PFObject?
    
    func showCheck() {
        imageView.hidden = false
    }
    
    func hideCheck() {
        imageView.hidden = true
    }
    
    func setSelected() {
        if selected {
            showCheck()
        } else {
            hideCheck()
        }
    }
    
    func isAddFriendButton() {
        backgroundColor = UIColor(red: CGFloat(228) / 255.0, green: CGFloat(228) / 255.0, blue: CGFloat(228) / 255.0, alpha: 1.0)
        addFriendImage.hidden = false
    }
    
    func setLabel(text: String) {
        label!.hidden = false
        label!.text = text
    }
    
    func setRandomBackgroundColor() {
        backgroundColor = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
    }
    
    func setRequest(request: PFObject) {
        // Calculate time left, set frame of timerOverlay and hit up the animation.
        self.request = request
        timerOverlay.hidden = false
    }
    
    func reset() {
        label!.text = ""
        label!.hidden = true
        requestInOverlay.hidden = true
        requestOutOverlay.hidden = true
        addFriendImage.hidden = true
        imageView.hidden = true
        timerOverlay.hidden = true
        request = nil
    }
}
