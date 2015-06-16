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
    var selectedIndexes = [String:Bool]()
    var currentActionSheet: String!
    var currentCellRequest: ThumbnailCollectionViewCell!
    var currentRequest: PFObject!
    var currentFriend: PFObject!
    let refreshControl = UIRefreshControl()
    var collectionView: ThumbnailCollectionView!
    
    @IBOutlet weak var sendBar: UIView!
    @IBOutlet weak var selectAllButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView = ThumbnailCollectionView(frame: self.view.frame)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        self.view.addSubview(collectionView!)
        
        // Add the Long press gesture recognizer.
        // http://stackoverflow.com/questions/18848725/long-press-gesture-on-uicollectionviewcell
        let lpgr = UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:"))
        lpgr.minimumPressDuration = 0.5
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        
        collectionView!.addGestureRecognizer(lpgr)
        
        // Add the UIRefreshControl to the view and bind refresh event.
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
        
        setSendBar()
        
        // Initialize swipe right.
        var swipeRightGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "showGlimps")
        swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        collectionView!.addGestureRecognizer(swipeRightGestureRecognizer)
        
        // Initialize swipe left.
        var swipeLeftGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "showProfile")
        swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        collectionView!.addGestureRecognizer(swipeLeftGestureRecognizer)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.collectionView!.reloadData()
    }
    
    // Hides or shows the sendbar based on selected friends.
    func setSendBar() {
        if countElements(selectedIndexes) != 0 {
            
            // Set the frame of collectionview at height minus height of sendbar so it doesn't overlap.
            collectionView!.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - sendBar.frame.height)
            sendBar.hidden = false
        } else {
            collectionView!.frame = self.view.frame
            sendBar.hidden = true
        }
        selectAllButton.setTitle(countElements(selectedIndexes) == Friends.friends.count ? "NONE" : "ALL", forState: UIControlState.Normal)
    }
    
    func showGlimps() {
        self.performSegueWithIdentifier("showGlimps", sender: self)
    }
    
    func showProfile() {
        self.performSegueWithIdentifier("showProfile", sender: self)
    }
    
    // Segue specific code from http://www.appcoda.com/custom-segue-animations/
    // This segue gets called when returning from the GlimpViewController
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        
        if let id = identifier {
            if id == "hideGlimps" {
                let unwindSegue = SwipeRightSegueUnwind(identifier: id, source: fromViewController, destination: toViewController, performHandler: { () -> Void in
                })
                return unwindSegue
            } else if id == "hideProfile" {
                let unwindSegue = SwipeLeftSegueUnwind(identifier: id, source: fromViewController, destination: toViewController, performHandler: { () -> Void in
                })
                return unwindSegue
            } else if id == "hideSharedGlimps" {
                let unwindSegue = SwipeLeftSegueUnwind(identifier: id, source: fromViewController, destination: toViewController, performHandler: { () -> Void in
                })
                return unwindSegue
            }
        }
        
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    // Add friend by username, on success reload the data.
    func addFriend(username: String) {
        Requests.invite(username, callback: { (success, error) -> Void in
            if success {
                self.collectionView!.reloadData()
            }
        })
    }
    
    // Create UIActionSheet for options on incoming friend request
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
    
    // Create UIActionSheet for options on outgoing friend request
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
    
    // Accept incoming friend request.
    // TODO:
    //  - It would be more reliable to pass the request and find the index in the Request array. This breaks if the data has changed in between.
    //  - Move to FriendRequestsCollection.
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
    
    // Delete incoming friend request.
    func deleteFriendRequestIn(requestIndex: Int) {
        Requests.requestsIn[requestIndex].deleteInBackground()
        Requests.requestsIn.removeAtIndex(requestIndex)
        
        collectionView!.reloadData()
    }
    
    // Delete outgoing friend request.
    func deleteFriendRequestOut(requestIndex: Int) {
        let user = PFUser.currentUser()
        user.removeObject(Requests.requestsOut[requestIndex]["toUser"].objectId, forKey: "Friends")
        user.saveInBackground()
        
        Requests.requestsOut[requestIndex].deleteInBackground()
        Requests.requestsOut.removeAtIndex(requestIndex)
        
        collectionView!.reloadData()
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showImagePicker" {
            let imagePickerViewController = segue.destinationViewController as ImagePickerViewController
            
            // Attach callback to ImagePickerViewController, when it returns.
            imagePickerViewController.callback = {(image: UIImage!) -> Void in
                if image != nil && self.currentCellRequest != nil && self.currentRequest != nil {
                    
                    // Show loading indicator on cell and answer the glimp.
                    self.currentCellRequest.isLoading!.hidden = false
                    Glimps.answerGlimpRequestIn(self.currentRequest, image: image!, callback: { () -> Void in
                        self.collectionView!.reloadData()
                    })
                }
                self.currentCellRequest = nil
                self.currentRequest = nil
            }
        } else if segue.identifier == "showSharedGlimps" && currentFriend != nil {
            let sharedGlimpViewController = segue.destinationViewController as SharedGlimpViewController
            sharedGlimpViewController.friend = currentFriend
            currentFriend = nil
        }
    }
    
    func toggleSelectFriend(objectId: String, select: Bool) {
        
        // If the cell was selected, add it to selected friends, otherwise remove it from selected friends.
        if (select) {
            selectedIndexes[objectId] = true
        } else {
            selectedIndexes.removeValueForKey(objectId)
        }
        setSendBar()
    }
    
    @IBAction func returnFromSegueActions(sender: UIStoryboardSegue) {
    }
    
    @IBAction func selectAllFriends(sender: UIButton) {
        
        // If all are selected, remove everyone. Otherwise add everyone
        if countElements(selectedIndexes) == Friends.friends.count {
            for objectId in selectedIndexes.keys.array {
                selectedIndexes.removeValueForKey(objectId)
            }
        } else {
            for friend in Friends.friends {
                selectedIndexes[friend.objectId] = true
            }
        }
        self.collectionView!.reloadData()
        setSendBar()
    }
    
    @IBAction func sendGlimpRequest(sender: UIButton) {
        // Save copy of selected friends, clear selected friends and sendbar.
        let friendIds = selectedIndexes.keys.array
        selectedIndexes = [:]
        setSendBar()
        
        // Send the actual Glimp requests. For now time is 60 minutes.
        Glimps.sendRequests(friendIds, time: 60, callback: {() -> Void in
            self.collectionView!.reloadData()
        })
    }
    
    @IBAction func unwindToImagePickerViewController(segue: UIStoryboardSegue) {
        println("unwinnnndddd")
        println(segue)
    }
    
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        let p = gestureRecognizer.locationInView(self.collectionView!)
        if let indexPath = self.collectionView!.indexPathForItemAtPoint(p) {
            let cell = collectionView!.cellForItemAtIndexPath(indexPath) as ThumbnailCollectionViewCell
            if let friend = cell.friend {
                currentFriend = friend
                performSegueWithIdentifier("showSharedGlimps", sender: self)
            }
        }
    }
}

extension HomeViewController: UICollectionViewDataSource {

    // There are four sections in the collectionView: Header, thumbnails, header, thumbnails.
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 4
    }
    
    // Returns the length of each section.
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Section 0 and 2 are headers so have a length of 1
        if section == 0 || section == 2 {
            return 1
        }
        
        // Section 3 consist of an 'add-friend' button (+1), all friends, all incoming friends and outgoing friends.
        if section == 3 {
            return 1 + Friends.friends.count + Requests.requestsIn.count + Requests.requestsOut.count
        }
        
        // Section 1 is incoming glimp requests: Use dummy data.
        // If there are no requests, show a cell explaining there are no requests.
        if Glimps.requestsIn.count == 0 {
            return 1
        }
        return Glimps.requestsIn.count
    }
    
    // Returns the cell to be rendered.
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Render Header cell.
        if indexPath.section == 0 || indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("HeaderCollectionViewCell", forIndexPath: indexPath) as HeaderCollectionViewCell
            cell.headerText!.text = indexPath.section == 0 ? "ANSWER A GLIMP" : "ASK A GLIMP"
            
            return cell
        }
        
        // Use a thumbnail for the other cells and reset the properties, it might have been re-used.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThumbnailCollectionViewCell", forIndexPath: indexPath) as ThumbnailCollectionViewCell
        cell.reset()
        
        // The first button is an add-friend button.
        if indexPath.section == 3 && indexPath.row == 0 {
            cell.isAddFriendButton()
        } else {
            cell.setRandomBackgroundColor()
            
            if indexPath.section == 1 {
                if Glimps.requestsIn.count == 0 {
                    return collectionView.dequeueReusableCellWithReuseIdentifier("EmptyListCollectionViewCell", forIndexPath: indexPath) as UICollectionViewCell
                } else {
                    let request = Glimps.requestsIn[indexPath.row]
                    cell.setLabel(request["fromUser"]!["username"]! as String)
                    cell.setRequest(request)
                    if let photo = request["fromUser"]!["photo"] as? PFFile {
                        cell.setImage(photo)
                    }
                    
                    return cell
                }
                
            // If the cell is in the last section and is not the add-friend button...
            } else if indexPath.section == 3 && indexPath.row > 0 {
                
                // The cell is a friend.
                if indexPath.row <= Friends.friends.count {
                    let friend = Friends.friends[indexPath.row - 1]
                    cell.setLabel(friend["username"] as String)
                    if let photo = friend["photo"] as? PFFile {
                        cell.setImage(photo)
                    }
                    cell.friend = friend

                    // If a glimp request has been sent, set it on the cell.
                    if let request = Glimps.findRequestOut(friend) {
                        cell.setRequest(request)
                    }
                    
                    // If it was selected (before collectionView.reloadData()), select it again.
                    if selectedIndexes[friend.objectId] != nil {
                        cell.isSelected = true
                        cell.setSelected()
                        setSendBar()
                    }
                
                // The cell is an incoming request.
                } else if indexPath.row <= Friends.friends.count + Requests.requestsIn.count {
                    let fromUser = Requests.requestsIn[indexPath.row - Friends.friends.count - 1]["fromUser"]! as PFObject
                    cell.setLabel(fromUser["username"] as String)
                    cell.requestInOverlay!.hidden = false
                    cell.bottomOverlay!.hidden = false
                    if let photo = fromUser["photo"] as? PFFile {
                        cell.setImage(photo)
                    }
                    
                // The cell is an outgoing request
                } else {
                    let toUser = Requests.requestsOut[indexPath.row - Friends.friends.count - Requests.requestsIn.count - 1]["toUser"]! as PFObject
                    cell.setLabel(toUser["username"] as String)
                    cell.requestOutOverlay!.hidden = false
                    cell.bottomOverlay!.hidden = false
                    if let photo = toUser["photo"] as? PFFile {
                        cell.setImage(photo)
                    } else {
                        println("none")
                        println(toUser["username"] as String)
                    }
                }
            }
        }
        return cell
    }
    
    // Returns size of cell.
    func collectionView(collectionView: ThumbnailCollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // If the cell is a header, render with full width
        if indexPath.section == 0 || indexPath.section == 2
        {
            return CGSize(width: collectionView.width, height: 46)
        }
        
        if indexPath.section == 1 && Glimps.requestsIn.count == 0 {
            return CGSize(width: collectionView.width, height: 46)
        }
        
        // Otherwise create four column thumbnails.
        return collectionView.thumbnailSize;
    }
    
    // When a sell was selected.
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        // When the add-friend button was tapped; create a UIAlert with input textfield.
        if indexPath.section == 3 && indexPath.row == 0 {
            let alert = UIAlertView()
            alert.title = "Add a friend"
            alert.delegate = self
            alert.message = "Enter a username"
            alert.alertViewStyle = UIAlertViewStyle.PlainTextInput
            alert.addButtonWithTitle("Done")
            alert.addButtonWithTitle("Cancel")
            alert.show()
        
        // The cell is in the friend list.
        } else if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ThumbnailCollectionViewCell {

            // Use ImagePickerViewController to grab a square photo.
            if indexPath.section == 1 {
                self.performSegueWithIdentifier("showImagePicker", sender: nil)
                
                if let request = cell.request {
                    currentCellRequest = cell
                    currentRequest = request
                }
                return
            }
            
            // If the cell is an incoming request.
            if indexPath.row > Friends.friends.count && indexPath.row <= Friends.friends.count + Requests.requestsIn.count {
                return addOrIgnoreFriendRequestIn(indexPath.row - Friends.friends.count - 1)
                
            // If the cell is an outgoing request.
            } else if indexPath.row > Friends.friends.count + Requests.requestsIn.count {
                return addOrIgnoreFriendRequestOut(indexPath.row - Friends.friends.count - Requests.requestsIn.count - 1)
            }
            
            // Otherwise the cell is a normal friend, toggle the select, but only if there is no request on it.
            if cell.request != nil {
                return
            }
            cell.isSelected = !cell.isSelected
            cell.setSelected()
            
            toggleSelectFriend(Friends.friends[indexPath.row - 1].objectId, select: cell.isSelected)
        }
    }
}

extension HomeViewController: UICollectionViewDelegate {
    
    // If a cell can be selected.
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        // For now only cells in the last section can be selected.
        if indexPath.section == 3 || (indexPath.section == 1 && Glimps.requestsIn.count > 0) {
            return true
        }
        return false
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {}

extension HomeViewController: UIGestureRecognizerDelegate {}

extension HomeViewController: UIAlertViewDelegate {
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0:
            if let username = alertView.textFieldAtIndex(0)?.text {
                self.addFriend(username)
            }
            break;
        default:
            break;
        }
    }
}

extension HomeViewController: UIActionSheetDelegate {
    
    // When an actionsheet is closed.
    func actionSheet(sheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int) {
        
        // If the action sheet was for incoming requests.
        if currentActionSheet == "requestIn" {
            if buttonIndex == 0 {
                acceptFriendRequestIn(sheet.tag)
            } else if buttonIndex == 1 {
                deleteFriendRequestIn(sheet.tag)
            }
        
        // If the action sheet was for outgoing requests.
        } else if currentActionSheet! == "requestOut" {
            if buttonIndex == 0 {
                deleteFriendRequestOut(sheet.tag)
            }
        }
    }
}
