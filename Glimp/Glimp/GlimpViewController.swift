//
//  ViewController.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 01-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit
import Parse

class GlimpViewController: UIViewController {
    let refreshControl = UIRefreshControl()
    var collectionView: ThumbnailCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView = ThumbnailCollectionView(frame: self.view.frame)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        self.view.addSubview(collectionView!)
        
        // Add the UIRefreshControl to the view and bind refresh event.
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.addSubview(refreshControl)
        
        var swipeGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "hideGlimps")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    func hideGlimps() {
        self.performSegueWithIdentifier("hideGlimps", sender: self)
    }
    
    // Reload all data.
    // TODO: These methods can be run in paralel.
    func refresh(sender: AnyObject) {
        RefreshData({ () -> Void in
            self.refreshControl.endRefreshing()
            self.collectionView!.reloadData()
        })
    }
}

extension GlimpViewController: UICollectionViewDataSource {
    
    // There are four sections in the collectionView: Header, thumbnails, header, thumbnails.
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    // Returns the length of each section.
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        
        // For now we return use the glimps currentUser has sent
        return Glimps.glimpsOut.count
    }
    
    // Returns the cell to be rendered.
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("HeaderCollectionViewCell", forIndexPath: indexPath) as HeaderCollectionViewCell
            cell.headerText!.text = "GLIMPS RECEIVED"
            
            return cell
        }
        
        // Use a thumbnail for the other cells and reset the properties, it might have been re-used.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThumbnailCollectionViewCell", forIndexPath: indexPath) as ThumbnailCollectionViewCell
        cell.reset()
        cell.setImage((Glimps.glimpsOut[indexPath.row] as PFObject)["photo"] as PFFile)
        
        return cell
    }
    
    // Returns size of cell.
    func collectionView(collectionView: ThumbnailCollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            return CGSize(width: collectionView.width, height: 47)
        }
        
        // Otherwise create four column thumbnails.
        return collectionView.thumbnailSize
    }
}

extension GlimpViewController: UICollectionViewDelegate {
    
    // If a cell can be selected.
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}
