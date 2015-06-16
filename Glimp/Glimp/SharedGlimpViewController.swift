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
    
    let screenSize: CGRect
    let screenWidth: CGFloat!
    let screenHeight: CGFloat!
    let columns = CGFloat(4)
    var friend: PFObject!
    var glimps: [PFObject]!
    var collectionView: UICollectionView!
    
    required init(coder aDecoder: NSCoder) {
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        glimps = Glimps.findSharedGlimps(friend)
        
        // Set the item size on the layout of collectionView, we want four-column thumbnails
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: screenWidth / columns, height: screenWidth / columns)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: headerView.frame.height, width: view.frame.width, height: view.frame.height - headerView.frame.height), collectionViewLayout: layout)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.alwaysBounceVertical = true
        self.view.addSubview(collectionView!)
        
        collectionView!.registerNib(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ThumbnailCollectionViewCell")
        collectionView!.registerNib(UINib(nibName: "HeaderCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "HeaderCollectionViewCell")
        
        var swipeGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "hideSharedGlimps")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeGestureRecognizer)
    }
    
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
        
        if section == 0 {
            return 1
        }
        
        // For now we return use the glimps currentUser has sent
        return glimps.count
    }
    
    // Returns the cell to be rendered.
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
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
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            return CGSize(width: screenWidth, height: 47)
        }
        
        // Otherwise create four column thumbnails.
        return CGSize(width: screenWidth / columns, height: screenWidth / columns);
    }
}

extension SharedGlimpViewController: UICollectionViewDelegate {
    
    // If a cell can be selected.
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}
