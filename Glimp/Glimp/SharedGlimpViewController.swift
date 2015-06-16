//
//  SharedGlimpViewController.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 16-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit
import Parse

class SharedGlimpViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileImage: ThumbnailImageView!
    var friend : PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var swipeGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "hideSharedGlimps")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    override func viewDidAppear(animated: Bool) {
        println(friend)
        if friend != nil {
            usernameLabel!.text = friend["username"] as? String
            if let image = friend["photo"] as? PFFile {
                profileImage!.file = image
            }
        }
    }
    
    func hideSharedGlimps() {
        self.performSegueWithIdentifier("hideSharedGlimps", sender: self)
    }
}
