//
//  ThumbnailCollectionView.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 16-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//
//  A CollectionView with a four column layout.

import UIKit

class ThumbnailCollectionView: UICollectionView {
    let screenSize = UIScreen.mainScreen().bounds
    let width: CGFloat!
    let height: CGFloat!
    let thumbnailSize: CGSize!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        width = frame.width
        height = frame.height
        thumbnailSize = CGSize(width: width / COLUMNS, height: width / COLUMNS)
        
        // Set the item size on the layout of collectionView, we want four-column thumbnails
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = thumbnailSize
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        super.init(frame: frame, collectionViewLayout: layout)
        
        backgroundColor = UIColor.whiteColor()
        alwaysBounceVertical = true
        
        // Register most used cell classes for fast re-use.
        registerNib(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ThumbnailCollectionViewCell")
        registerNib(UINib(nibName: "HeaderCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "HeaderCollectionViewCell")
        registerNib(UINib(nibName: "EmptyListCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "EmptyListCollectionViewCell")
    }
}
