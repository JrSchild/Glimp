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
    let screenSize: CGRect
    let screenWidth: CGFloat!
    let screenHeight: CGFloat!
    let columns = CGFloat(4)
    let homeData = HomeData()
    var selectedIndexes = [String:Bool]()
    var currentActionSheet: String!
    let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sendBar: UIView!
    
    required init(coder aDecoder: NSCoder) {
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = collectionView!.collectionViewLayout as UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: screenWidth / columns, height: screenWidth / columns)
        
        collectionView!.registerClass(AnswerHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "AnswerHeaderCollectionViewCell")
        collectionView!.registerClass(AskHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "AskHeaderCollectionViewCell")
        self.view.addSubview(collectionView!)
        collectionView!.layer.zPosition = 5
        sendBar.layer.zPosition = 10
        
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
        
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
        Requests.invite(username, callback: { (success, error) -> Void in
            if success {
                self.collectionView!.reloadData()
            }
        })
    }
    
    func addOrIgnoreFriendRequestIn(request: Int) {
        let sheet: UIActionSheet = UIActionSheet();
        sheet.delegate = self;
        sheet.addButtonWithTitle("Accept Request");
        sheet.addButtonWithTitle("Delete Request");
        sheet.addButtonWithTitle("Cancel");
        sheet.cancelButtonIndex = 2;
        sheet.tag = request
        sheet.showInView(self.view);
        currentActionSheet = "requestIn"
    }
    
    func addOrIgnoreFriendRequestOut(request: Int) {
        let sheet: UIActionSheet = UIActionSheet();
        sheet.delegate = self;
        sheet.addButtonWithTitle("Delete Request");
        sheet.addButtonWithTitle("Cancel");
        sheet.cancelButtonIndex = 1;
        sheet.tag = request
        sheet.showInView(self.view);
        currentActionSheet = "requestOut"
    }
    
    // It would be more reliable to pass the request and find the index in the Request array. This breaks if the data has changed in between.
    // Rename to acceptRequest
    func acceptFriendRequestIn(requestIndex: Int) {
        var user = PFUser.currentUser()!
        var request: AnyObject = Requests.requestsIn[requestIndex]
        var friend = request["fromUser"] as PFObject
        
        // Update data in memory
        user["Friends"].addObject(friend.objectId)
        Friends.friends.append(friend)
        Requests.requestsIn.removeAtIndex(requestIndex)
        
        // Persist changes to the database
        user.saveInBackground()
        request.deleteInBackground()
        
        collectionView!.reloadData()
    }
    
    func deleteFriendRequestIn(requestIndex: Int) {
        Requests.requestsIn[requestIndex].deleteInBackground()
        Requests.requestsIn.removeAtIndex(requestIndex)
        
        collectionView!.reloadData()
    }
    
    func deleteFriendRequestOut(requestIndex: Int) {
        let user = PFUser.currentUser()
        user.removeObject(Requests.requestsOut[requestIndex]["toUser"].objectId, forKey: "Friends")
        user.saveInBackground()
        
        Requests.requestsOut[requestIndex].deleteInBackground()
        Requests.requestsOut.removeAtIndex(requestIndex)
        
        collectionView!.reloadData()
    }
    
    func refresh(sender: AnyObject) {
        Friends.load({ () -> Void in
            Requests.load({ () -> Void in
                self.refreshControl.endRefreshing()
                self.collectionView!.reloadData()
            })
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {}
    
    @IBAction func returnFromSegueActions(sender: UIStoryboardSegue) {}
    
    @IBAction func sendGlimpRequest(sender: UIButton) {
        // For now time is 60 minutes.
        Glimps.sendRequests(selectedIndexes.keys.array, time: 60, callback: {() -> Void in})
    }
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
            return Friends.friends.count + Requests.requestsIn.count + Requests.requestsOut.count + 1
        }
        return homeData.data[(section - 1) / 2].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 || indexPath.section == 2 {
            let cellIdentifier = indexPath.section == 0 ? "AnswerHeaderCollectionViewCell" : "AskHeaderCollectionViewCell"
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as UICollectionViewCell
            cell.frame.size.width = screenWidth
            cell.frame.size.height = 46
            cell.backgroundColor = UIColor.whiteColor()
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThumbnailCell", forIndexPath: indexPath) as ThumbnailCollectionViewCell
        cell.frame.size.width = screenWidth / columns
        cell.frame.size.height = screenWidth / columns
        cell.reset()
        
        if indexPath.section == 3 && indexPath.row == 0 {
            cell.isAddFriendButton()
        } else {
            cell.setRandomBackgroundColor()
            
            if indexPath.section == 3 && indexPath.row > 0 {
                if indexPath.row <= Friends.friends.count {
                    let friend = Friends.friends[indexPath.row - 1]
                    cell.setLabel(friend["username"] as String)
                    if selectedIndexes[friend.objectId] != nil {
                        cell.isSelected = true
                        cell.setSelected()
                        setSendBar()
                    }
                } else if indexPath.row <= Friends.friends.count + Requests.requestsIn.count {
                    cell.setLabel(Requests.requestsIn[indexPath.row - Friends.friends.count - 1]["fromUser"]!["username"] as String)
                    cell.requestInOverlay!.hidden = false
                } else {
                    cell.setLabel(Requests.requestsOut[indexPath.row - Friends.friends.count - Requests.requestsIn.count - 1]["toUser"]!["username"] as String)
                    cell.requestOutOverlay!.hidden = false
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
            if indexPath.row > Friends.friends.count && indexPath.row <= Friends.friends.count + Requests.requestsIn.count {
                addOrIgnoreFriendRequestIn(indexPath.row - Friends.friends.count - 1)
                return
            } else if indexPath.row > Friends.friends.count + Requests.requestsIn.count {
                addOrIgnoreFriendRequestOut(indexPath.row - Friends.friends.count - Requests.requestsIn.count - 1)
                return
            }
            
            cell.isSelected = !cell.isSelected
            cell.setSelected()
            if (cell.isSelected) {
                selectedIndexes[Friends.friends[indexPath.row - 1].objectId] = true
            } else {
                selectedIndexes.removeValueForKey(Friends.friends[indexPath.row - 1].objectId)
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

extension HomeViewController: UIActionSheetDelegate {
    func actionSheet(sheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int) {
        if currentActionSheet == "requestIn" {
            if buttonIndex == 0 {
                acceptFriendRequestIn(sheet.tag)
            } else if buttonIndex == 1 {
                deleteFriendRequestIn(sheet.tag)
            }
        } else if currentActionSheet! == "requestOut" {
            if buttonIndex == 0 {
                deleteFriendRequestOut(sheet.tag)
            }
        }
    }
}
