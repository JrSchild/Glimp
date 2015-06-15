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
    let screenSize: CGRect
    let screenWidth: CGFloat!
    let screenHeight: CGFloat!
    let columns = CGFloat(4)
    let refreshControl = UIRefreshControl()
    var collectionView: UICollectionView!
    
    required init(coder aDecoder: NSCoder) {
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the item size on the layout of collectionView, we want four-column thumbnails
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: screenWidth / columns, height: screenWidth / columns)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView!.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(collectionView!)
        
        collectionView!.registerNib(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ThumbnailCollectionViewCell")
        collectionView!.registerNib(UINib(nibName: "HeaderCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "HeaderCollectionViewCell")
        
        // Add the UIRefreshControl to the view and bind refresh event.
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
        
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
        Friends.load({ () -> Void in
            Requests.load({ () -> Void in
                Glimps.load({ () -> Void in
                    self.refreshControl.endRefreshing()
                    self.collectionView!.reloadData()
                })
            })
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
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            return CGSize(width: screenWidth, height: 47)
        }
        
        // Otherwise create four column thumbnails.
        return CGSize(width: screenWidth / columns, height: screenWidth / columns);
    }
}

extension GlimpViewController: UICollectionViewDelegate {
    
    // If a cell can be selected.
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}
