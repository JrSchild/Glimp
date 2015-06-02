//
//  ThumbnailCollectionViewCell.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 02-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit

class ThumbnailCollectionViewCell: UICollectionViewCell {
    var timer : Int?
    let offset = 5
    var canSelect = false
    var isSelected = false
    var imageView : UIImageView?
    
    func showCheck() {
        if imageView == nil {
            imageView = UIImageView(image: UIImage(named: "check-friend")!)
            imageView!.frame = CGRect(x: CGFloat(offset), y: self.frame.height - imageView!.frame.height - CGFloat(offset), width: imageView!.frame.width, height: imageView!.frame.height)
        }
        self.addSubview(imageView!)
    }
    
    func hideCheck() {
        imageView!.removeFromSuperview()
    }
    
    func setSelected() {
        if selected {
            showCheck()
        } else {
            hideCheck()
        }
    }
}
