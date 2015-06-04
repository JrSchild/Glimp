//
//  ThumbnailCollectionViewCell.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 04-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit

class ThumbnailCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addFriendImage: UIImageView!
    @IBOutlet weak var requestOverlay: UILabel!
    
    var timer : Int?
    var canSelect = false
    var isSelected = false
    
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
    
    func reset() {
        label!.text = ""
        label!.hidden = true
        requestOverlay.hidden = true
        addFriendImage.hidden = true
        imageView.hidden = true
    }
}
