//
//  ViewController.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 01-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit
import Parse

class HomeViewController: UIViewController {
    var collectionView: UICollectionView?
    let screenSize : CGRect
    let screenWidth: CGFloat!
    let screenHeight: CGFloat!
    let columns = CGFloat(4)
    let homeData = HomeData()
    var selectedIndexes = [Int:Bool]()
    
    @IBOutlet weak var sendBar: UIView!
    
    required init(coder aDecoder: NSCoder) {
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: screenWidth / columns, height: screenWidth / columns)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.registerClass(ThumbnailCollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")
        collectionView!.registerClass(AnswerHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "AnswerHeaderCollectionViewCell")
        collectionView!.registerClass(AskHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "AskHeaderCollectionViewCell")
        self.view.addSubview(collectionView!)
        collectionView!.layer.zPosition = 5
        sendBar.layer.zPosition = 10
        setSendBar()
        
        var swipeGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "showGlimps")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        collectionView!.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    func setSendBar() {
        if countElements(selectedIndexes) != 0 {
            collectionView!.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - 60)
            sendBar.hidden = false
        } else {
            collectionView!.frame = self.view.frame
            sendBar.hidden = true
        }
    }
    
    func showGlimps() {
        self.performSegueWithIdentifier("showGlimps", sender: self)
    }
    
    // Segue specific code from http://www.appcoda.com/custom-segue-animations/
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        
        if let id = identifier {
            if id == "hideGlimps" {
                let unwindSegue = FirstCustomSegueUnwind(identifier: id, source: fromViewController, destination: toViewController, performHandler: { () -> Void in
                })
                return unwindSegue
            }
        }
        
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    func addFriend(username: String) {
        // Find the user if he exists.
        var query = PFUser.query()
        query.whereKey("username", equalTo: username)
        query.getFirstObjectInBackgroundWithBlock({ (friend: PFObject?, error: NSError?) -> Void in
            if error != nil {
                println("Found error retrieving user: \(error)")
                return
            }
            if friend == nil {
                self.couldNotFindFriend()
                return
            }
            
            let user = PFUser.currentUser()
            user["Friends"] = user["Friends"] ?? [String]()
            user["Friends"].addObject(friend!.objectId) // TODO: check if already exists.
            user.saveInBackground()

            var friendRequest = PFObject(className: "FriendRequest")
            friendRequest["fromUser"] = user
            friendRequest["toUser"] = friend
            friendRequest.saveInBackground()
            println("added friend \(friend)")
        })
    }
    
    func acceptFriend() {
        
    }
    
    func couldNotFindFriend() {}
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {}
    
    @IBAction func returnFromSegueActions(sender: UIStoryboardSegue) {}
    
}

extension HomeViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 || section == 2 {
            return 1
        }
        if section == 3 {
            return Friends.count + 1
        }
        return homeData.data[(section - 1) / 2].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell : UICollectionViewCell
        
        if indexPath.section == 0 || indexPath.section == 2 {
            let cellIdentifier = indexPath.section == 0 ? "AnswerHeaderCollectionViewCell" : "AskHeaderCollectionViewCell"
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as UICollectionViewCell
            cell.frame.size.width = screenWidth
            cell.frame.size.height = 46
            cell.backgroundColor = UIColor.whiteColor()
        } else {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("UICollectionViewCell", forIndexPath: indexPath) as UICollectionViewCell
            cell.frame.size.width = screenWidth / columns
            cell.frame.size.height = screenWidth / columns
            if indexPath.section == 3 && indexPath.row == 0 {
                cell.backgroundColor = UIColor(red: CGFloat(228) / 255.0, green: CGFloat(228) / 255.0, blue: CGFloat(228) / 255.0, alpha: 1.0)
                let imageView = UIImageView(image: UIImage(named: "add-friend")!)
                imageView.frame = CGRect(x: (cell.frame.width - imageView.frame.width) / 2, y: (cell.frame.height - imageView.frame.height) / 2, width: imageView.frame.width, height: imageView.frame.height)
                cell.addSubview(imageView)
            } else {
                cell.backgroundColor = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
                
                if indexPath.section == 3 && indexPath.row > 0 {
                    var label = UILabel()
                    label.text = String(Friends[indexPath.row - 1]["username"] as NSString)
                    label.frame = CGRect(x: 0, y: 0, width: screenWidth / columns, height: 50)
                    label.font = UIFont(name: label.font.familyName, size: 12)
                    cell.addSubview(label)
                }
            }
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if indexPath.section == 0 || indexPath.section == 2
        {
            return CGSize(width: screenWidth, height: 46)
        }
        return CGSize(width: screenWidth / columns, height: screenWidth / columns);
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 3 && indexPath.row == 0 {
            var inputTextField: UITextField?
            var alert = UIAlertController(title: "Add a friend", message: "Enter a username", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.Default, handler: { alertAction in
                self.addFriend(inputTextField!.text)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alert.addTextFieldWithConfigurationHandler({ textField in
                inputTextField = textField
            })
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ThumbnailCollectionViewCell {
            cell.isSelected = !cell.isSelected
            cell.setSelected()
            if (cell.isSelected) {
                selectedIndexes[indexPath.row] = true
            } else {
                selectedIndexes.removeValueForKey(indexPath.row)
            }
            setSendBar()
        }
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 3 {
            return true
        }
        return false
    }
}
extension HomeViewController: UICollectionViewDelegateFlowLayout {}
