//
//  ProfileViewController.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 12-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        var swipeGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "hideProfile")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    func hideProfile() {
        self.performSegueWithIdentifier("hideProfile", sender: self)
    }
}
