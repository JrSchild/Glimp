//
//  ViewController.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 01-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    var collectionView: UICollectionView?
    let screenSize : CGRect
    let screenWidth: CGFloat!
    let screenHeight: CGFloat!
    let columns = 4 as CGFloat
    
    required init(coder aDecoder: NSCoder) {
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: screenWidth / columns, height: screenWidth / columns)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")
        collectionView!.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(collectionView!)
    }
}

extension HomeViewController: UICollectionViewDataSource {
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 60
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UICollectionViewCell", forIndexPath: indexPath) as UICollectionViewCell
        cell.backgroundColor = UIColor.whiteColor()
        cell.layer.borderColor = UIColor.blackColor().CGColor
        cell.layer.borderWidth = 0
        cell.frame.size.width = screenWidth / columns
        cell.frame.size.height = screenWidth / columns
        
        var randomRed:CGFloat = CGFloat(drand48())
        var randomGreen:CGFloat = CGFloat(drand48())
        var randomBlue:CGFloat = CGFloat(drand48())
        
        cell.backgroundColor = UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
        
        return cell
    }
}

extension HomeViewController: UICollectionViewDelegate {}
extension HomeViewController: UICollectionViewDelegateFlowLayout {}
