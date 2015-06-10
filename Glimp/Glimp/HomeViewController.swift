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
        
        // Set the item size on the layout of collectionView, we want four-column thumbnails
        let layout = collectionView!.collectionViewLayout as UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: screenWidth / columns, height: screenWidth / columns)
        
        collectionView!.registerClass(AnswerHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "AnswerHeaderCollectionViewCell")
        collectionView!.registerClass(AskHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "AskHeaderCollectionViewCell")
        
        // Add the UIRefreshControl to the view and bind refresh event.
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
        
        setSendBar()
        
        // Initialize swipe right.
        var swipeGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "showGlimps")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        collectionView!.addGestureRecognizer(swipeGestureRecognizer)
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
    }
    
    func showGlimps() {
        self.performSegueWithIdentifier("showGlimps", sender: self)
    }
    
    // Segue specific code from http://www.appcoda.com/custom-segue-animations/
    // This segue gets called when returning from the GlimpViewController
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {}
    
    @IBAction func returnFromSegueActions(sender: UIStoryboardSegue) {}
    
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
        if Requests.requestsIn.count == 0 {
            return 1
        }
        return Requests.requestsIn.count
    }
    
    // Returns the cell to be rendered.
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Render Header cell.
        if indexPath.section == 0 || indexPath.section == 2 {
            let cellIdentifier = indexPath.section == 0 ? "AnswerHeaderCollectionViewCell" : "AskHeaderCollectionViewCell"
            
            return collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as UICollectionViewCell
        }
        
        // Use a thumbnail for the other cells and reset the properties, it might have been re-used.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThumbnailCell", forIndexPath: indexPath) as ThumbnailCollectionViewCell
        cell.reset()
        
        // The first button is an add-friend button.
        if indexPath.section == 3 && indexPath.row == 0 {
            cell.isAddFriendButton()
        } else {
            cell.setRandomBackgroundColor()
            
            if indexPath.section == 1 {
                if Glimps.requestsIn.count == 0 {
                    return collectionView.dequeueReusableCellWithReuseIdentifier("NoGlimpRequestsCell", forIndexPath: indexPath) as UICollectionViewCell
                } else {
                    let request = Glimps.requestsIn[indexPath.row]
                    cell.setLabel(request["fromUser"]!["username"]! as String)
                    cell.setRequest(request)
                    
                    return cell
                }
                
            // If the cell is in the last section and is not the add-friend button...
            } else if indexPath.section == 3 && indexPath.row > 0 {
                
                // The cell is a friend.
                if indexPath.row <= Friends.friends.count {
                    let friend = Friends.friends[indexPath.row - 1]
                    cell.setLabel(friend["username"] as String)

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
                    cell.setLabel(Requests.requestsIn[indexPath.row - Friends.friends.count - 1]["fromUser"]!["username"] as String)
                    cell.requestInOverlay!.hidden = false
                    
                // The cell is an outgoing request
                } else {
                    cell.setLabel(Requests.requestsOut[indexPath.row - Friends.friends.count - Requests.requestsIn.count - 1]["toUser"]!["username"] as String)
                    cell.requestOutOverlay!.hidden = false
                }
            }
        }
        return cell
    }
    
    // Returns size of cell.
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // If the cell is a header, render with full width
        if indexPath.section == 0 || indexPath.section == 2
        {
            return CGSize(width: screenWidth, height: 46)
        }
        
        if indexPath.section == 1 && Glimps.requestsIn.count == 0 {
            return CGSize(width: screenWidth, height: 46)
        }
        
        // Otherwise create four column thumbnails.
        return CGSize(width: screenWidth / columns, height: screenWidth / columns);
    }
    
    // When a sell was selected.
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        // When the add-friend button was tapped; create a UIAlert with input textfield.
        if indexPath.section == 3 && indexPath.row == 0 {
            var inputTextField: UITextField?
            var alert = UIAlertController(title: "Add a friend", message: "Enter a username", preferredStyle: UIAlertControllerStyle.Alert)

            // On confirm, add the friend with text of input.
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
        
        if indexPath.section == 1 {
            println("take photo")
            return
        }
        
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ThumbnailCollectionViewCell {
            
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
            
            // If the cell was selected, add it to selected friends, otherwise remove it from selected friends.
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
