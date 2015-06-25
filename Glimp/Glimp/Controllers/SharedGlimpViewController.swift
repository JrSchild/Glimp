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
    @IBOutlet weak var headerView: UIView!
    
    var friend: PFObject!
    var glimps: [PFObject]!
    var collectionView: ThumbnailCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        glimps = Glimps.findSharedGlimps(friend)
        
        // Initialize Thumbnail view below the headerView.
        collectionView = ThumbnailCollectionView(frame: CGRect(x: 0, y: headerView.frame.height, width: view.frame.width, height: view.frame.height - headerView.frame.height))
        collectionView!.dataSource = self
        collectionView!.delegate = self
        self.view.addSubview(collectionView!)
        
        // Attach swipe back handler.
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "hideSharedGlimps")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    // When view appears, set the friend's information in the View.
    override func viewDidAppear(animated: Bool) {
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

extension SharedGlimpViewController: UICollectionViewDataSource {
    
    // There are four sections in the collectionView: Header, thumbnails, header, thumbnails.
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    // Returns the length of each section.
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // The first section is a header.
        if section == 0 {
            return 1
        }
        
        return glimps.count
    }
    
    // Returns the cell to be rendered.
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // The first section is a Header.
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("HeaderCollectionViewCell", forIndexPath: indexPath) as HeaderCollectionViewCell
            cell.headerText!.text = "SHARED GLIMPS"
            
            return cell
        }
        
        // Use a thumbnail for the other cells and reset the properties, it might have been re-used.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThumbnailCollectionViewCell", forIndexPath: indexPath) as ThumbnailCollectionViewCell
        cell.reset()
        cell.setImage((glimps[indexPath.row] as PFObject)["photo"] as PFFile)
        
        return cell
    }
    
    // Returns size of cell.
    func collectionView(collectionView: ThumbnailCollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // First section is a Header.
        if indexPath.section == 0 {
            return CGSize(width: collectionView.width, height: 47)
        }
        
        // Otherwise create four column thumbnails.
        return collectionView.thumbnailSize
    }
}

extension SharedGlimpViewController: UICollectionViewDelegate {
    
    // If a cell can be selected.
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}
