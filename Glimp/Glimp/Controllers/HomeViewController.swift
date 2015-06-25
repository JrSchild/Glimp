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
        
        // Initialize Thumbnail view in full size
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
        
        Friends.sort()
        setSendBar()
        
        // Initialize swipe right.
        let swipeRightGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "showGlimps")
        swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        collectionView!.addGestureRecognizer(swipeRightGestureRecognizer)
        
        // Initialize swipe left.
        let swipeLeftGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "showProfile")
        swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        collectionView!.addGestureRecognizer(swipeLeftGestureRecognizer)
        
        // Attach notification listeners
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadData", name: NotificationDataFriendRequests, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadData", name: NotificationDataFriends, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadData", name: NotificationDataGlimps, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        reloadData()
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
        selectAllButton.setTitle(countElements(selectedIndexes) >= (Friends.friends.count - Glimps.requestsOut.count) ? "NONE" : "ALL", forState: UIControlState.Normal)
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
                return SwipeRightSegueUnwind(identifier: id, source: fromViewController, destination: toViewController, performHandler: {})
            } else if id == "hideProfile" {
                return SwipeLeftSegueUnwind(identifier: id, source: fromViewController, destination: toViewController, performHandler: {})
            } else if id == "hideSharedGlimps" {
                return SwipeLeftSegueUnwind(identifier: id, source: fromViewController, destination: toViewController, performHandler: {})
            }
        }
        
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    // Add friend by username, on success reload the data.
    func addFriend(username: String) {
        Requests.invite(username, callback: {(success, error) -> Void in
            if error != nil && error == "FriendNotFound" {
                let alert = UIAlertView()
                alert.title = "Error"
                alert.message = "User not found"
                alert.addButtonWithTitle("OK")
                alert.show()
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
    func acceptFriendRequestIn(requestIndex: Int) {
        Requests.acceptFriendRequestIn(Requests.requestsIn[requestIndex])
    }
    
    // Delete incoming friend request.
    func deleteFriendRequestIn(requestIndex: Int) {
        Requests.deleteFriendRequestIn(Requests.requestsIn[requestIndex])
    }
    
    // Delete outgoing friend request.
    func deleteFriendRequestOut(requestIndex: Int) {
        Requests.deleteFriendRequestOut(Requests.requestsOut[requestIndex])
    }
    
    // Reload all data.
    func refresh(sender: AnyObject) {
        RefreshData({ () -> Void in
            self.refreshControl.endRefreshing()
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // showImagePicker is used when answering a Glimp request.
        if segue.identifier == "showImagePicker" {
            let vpViewController = segue.destinationViewController as VPViewController
            vpViewController.delegate = self
            vpViewController.method = "PhotoLibrary"

        // Set the friend on SharedGlimpViewController
        } else if segue.identifier == "showSharedGlimps" && currentFriend != nil {
            let sharedGlimpViewController = segue.destinationViewController as SharedGlimpViewController
            sharedGlimpViewController.friend = currentFriend
            currentFriend = nil
        }
    }
    
    // If the cell was selected, add it to selected friends, otherwise remove it.
    func toggleSelectFriend(objectId: String, select: Bool) {
        if (select) {
            selectedIndexes[objectId] = true
        } else {
            selectedIndexes.removeValueForKey(objectId)
        }
        setSendBar()
    }
    
    // Method required for returning from segue
    @IBAction func returnFromSegueActions(sender: UIStoryboardSegue) {}
    
    // If all friends are selected, unselect everyone. Otherwise select everyone.
    @IBAction func selectAllFriends(sender: UIButton) {
        if countElements(selectedIndexes) >= (Friends.friends.count - Glimps.requestsOut.count) {
            for objectId in selectedIndexes.keys.array {
                selectedIndexes.removeValueForKey(objectId)
            }
        } else {
            for friend in Friends.friends {
                if Glimps.findGlimpRequestOut(friend) == nil {
                    selectedIndexes[friend.objectId] = true
                }
            }
        }
        reloadData()
        setSendBar()
    }
    
    // Send the Glimp requests.
    @IBAction func sendGlimpRequest(sender: UIButton) {
        
        // Save copy of selected friends, clear selected friends and sendbar.
        let friendIds = selectedIndexes.keys.array
        selectedIndexes = [:]
        setSendBar()
        
        // Get the cell with the chosen time stored on it.
        let cell = collectionView!.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 2)) as HeaderCollectionViewCell    
        
        // Send the actual Glimp requests. Use the time from cell.
        Glimps.sendGlimpRequests(friendIds, time: cell.time, callback: {})
    }
    
    // When a long press is triggered on a ThumbnailViewCell
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        
        // Retrieve the corresponding cell, get the friend from cell and perform the Segue.
        let location = gestureRecognizer.locationInView(self.collectionView!)
        if let indexPath = self.collectionView!.indexPathForItemAtPoint(location) {
            let cell = collectionView!.cellForItemAtIndexPath(indexPath) as ThumbnailCollectionViewCell
            if let friend = cell.friend {
                currentFriend = friend
                performSegueWithIdentifier("showSharedGlimps", sender: self)
            }
        }
    }
    
    // Helper method to refresh the CollectionView.
    func reloadData() {
        self.collectionView!.reloadData()
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
        // If there are no requests, show a cell explaining there are no requests, thus still making the length 1)
        let requestsInCount = Glimps.requestsIn.count
        return requestsInCount == 0 ? 1 : requestsInCount
    }
    
    // Returns the cell to be rendered.
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Render Header cell.
        if indexPath.section == 0 || indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("HeaderCollectionViewCell", forIndexPath: indexPath) as HeaderCollectionViewCell
            cell.reset()
            
            // Set the text for the first and second header.
            if indexPath.section == 0 {
                cell.headerText!.text = "ANSWER A GLIMP"
            } else {
                cell.headerText!.text = "ASK A GLIMP"
                
                // Show the button for modifying time-to-reply.
                cell.setTimerButton()
            }
            
            return cell
        }
        
        // Use a thumbnail for the other cells and reset the properties, it might have been re-used.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThumbnailCollectionViewCell", forIndexPath: indexPath) as ThumbnailCollectionViewCell
        cell.reset()
        
        // Section one are the incoming Glimp-Requests.
        if indexPath.section == 1 {
            
            // If there are no incoming Glimp-Requests, return a cell with feedback.
            if Glimps.requestsIn.count == 0 {
                return collectionView.dequeueReusableCellWithReuseIdentifier("EmptyListCollectionViewCell", forIndexPath: indexPath) as UICollectionViewCell
            
            // Otherwise retrieve the incoming request-data and set it on the cell.
            } else {
                cell.setGlimpRequestIn(Glimps.requestsIn[indexPath.row])
            }
            
        // The first button of the bottom section is the add-a-new-friend button.
        } else if indexPath.section == 3 && indexPath.row == 0 {
            cell.isAddFriendButton()
        
        // Otherwise the cell is a friend button. It must be section 3, and row higher higher than 0.
        } else {
            
            // The cell is a friend.
            if indexPath.row <= Friends.friends.count {
                let friend = Friends.friends[indexPath.row - 1]
                cell.setLabel(friend["username"] as String)
                if let photo = friend["photo"] as? PFFile {
                    cell.setImage(photo)
                }
                cell.friend = friend

                // If a glimp request has been sent, set it on the cell.
                if let request = Glimps.findGlimpRequestOut(friend) {
                    cell.setRequest(request)
                }
                
                // If it was selected (before collectionView.reloadData()), select it again.
                if selectedIndexes[friend.objectId] != nil {
                    cell.isSelected = true
                    cell.setCheckmark()
                }
            
            // The cell is an incoming Friend-Request.
            } else if indexPath.row <= Friends.friends.count + Requests.requestsIn.count {
                let fromUser = Requests.requestsIn[indexPath.row - Friends.friends.count - 1]["fromUser"]! as PFObject
                cell.setLabel(fromUser["username"] as String)
                cell.requestInOverlay!.hidden = false
                cell.bottomOverlay!.hidden = false
                if let photo = fromUser["photo"] as? PFFile {
                    cell.setImage(photo)
                }
                
            // The cell is an outgoing Friend-Request
            } else {
                let toUser = Requests.requestsOut[indexPath.row - Friends.friends.count - Requests.requestsIn.count - 1]["toUser"]! as PFObject
                cell.setLabel(toUser["username"] as String)
                cell.requestOutOverlay!.hidden = false
                cell.bottomOverlay!.hidden = false
                if let photo = toUser["photo"] as? PFFile {
                    cell.setImage(photo)
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
            return CGSize(width: collectionView.width, height: HEADER_ROW_HEIGHT)
        }
        
        // If the cell is the feedback-cell with the message: 'No current glimp requests'
        if indexPath.section == 1 && Glimps.requestsIn.count == 0 {
            return CGSize(width: collectionView.width, height: HEADER_ROW_HEIGHT)
        }
        
        // Otherwise create four column thumbnails.
        return collectionView.thumbnailSize;
    }
    
    // When a sell was tapped (selected).
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

            // Use ImagePickerViewController to grab a square photo for cells in section 1.
            if indexPath.section == 1 {
                if let request = cell.request {
                    currentCellRequest = cell
                    currentRequest = request
                }
                
                self.performSegueWithIdentifier("showImagePicker", sender: nil)
                
                return
            }
            
            // If the cell is an incoming Friend-Request.
            if indexPath.row > Friends.friends.count && indexPath.row <= Friends.friends.count + Requests.requestsIn.count {
                return addOrIgnoreFriendRequestIn(indexPath.row - Friends.friends.count - 1)
                
            // If the cell is an outgoing Friend-Request.
            } else if indexPath.row > Friends.friends.count + Requests.requestsIn.count {
                return addOrIgnoreFriendRequestOut(indexPath.row - Friends.friends.count - Requests.requestsIn.count - 1)
            }
            
            // Otherwise the cell is a normal friend, toggle the select, but only if there is no request on it.
            if cell.request != nil {
                return
            }
            cell.isSelected = !cell.isSelected
            cell.setCheckmark()
            
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

// Delegate required for gestures.
extension HomeViewController: UIGestureRecognizerDelegate {}

extension HomeViewController: UIAlertViewDelegate {
    
    // AlertView for adding new friends by username.
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            if let username = alertView.textFieldAtIndex(0)?.text {
                self.addFriend(username)
            }
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

// Delegate for callbacks on CropperView
extension HomeViewController: VPViewControllerDelegate {
    func imageCropper(cropperViewController: VPViewController!, didFinished editedImage: UIImage!) {
        
        // When an image is successfully returned, answer the Glimp-Request.
        if editedImage != nil && self.currentCellRequest != nil && self.currentRequest != nil {
            Glimps.answerGlimpRequestIn(self.currentRequest, image: editedImage!, callback: {})
        }
        self.currentCellRequest = nil
        self.currentRequest = nil
    }
}
