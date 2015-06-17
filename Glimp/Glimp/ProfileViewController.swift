//
//  ProfileViewController.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 12-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class ProfileViewController: UIViewController {
    
    let imageView = PFImageView()
    let user = PFUser.currentUser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var swipeGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "hideProfile")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        imageView.image = UIImage(named: "user-profile")
        imageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width)
        self.view.addSubview(imageView)
        
        let view = NSBundle.mainBundle().loadNibNamed("ProfileInformationView", owner: self, options: nil)[0] as ProfileInformationView
        view.frame = CGRect(x: 0, y: imageView.frame.height, width: self.view.frame.width, height: view.frame.height)
        view.usernameLabel.text = user?["username"] as? String ?? ""
        view.emailLabel.text = user?["email"] as? String ?? ""
        self.view.addSubview(view)
        
        // Add tap event to image.
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "changeProfilePicture:"))
        imageView.userInteractionEnabled = true
        
        if let photo = user?.objectForKey("photo") as? PFFile {
            imageView.file = photo
            imageView.loadInBackground()
        }
    }
    
    func hideProfile() {
        self.performSegueWithIdentifier("hideProfile", sender: self)
    }

    func changeProfilePicture(gesture: UIGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("ImagePickerViewController") as ImagePickerViewController
        controller.callback = {(image) -> Void in
            self.user["photo"] = PFFile(data: UIImageJPEGRepresentation(image, 0.9))
            self.user.saveInBackgroundWithBlock({ (success, error) -> Void in
                if success {
                    self.imageView.file = self.user["photo"] as PFFile
                    self.imageView.loadInBackground()
                }
            })
        }
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func logOut(sender: UIButton) {
        (UIApplication.sharedApplication().delegate as AppDelegate).logOut()
    }
}
