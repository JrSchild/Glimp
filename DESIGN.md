## Glimp Design Document

### Framworks and APIs
- Parse: Contains all data handling/querying, user management, security, configuration.
- ParseUI: User interface element for loging in.
- Bolts: For keeping asynchronous actions off the main thread.
- DBCamera: Custom camera for taking square images.

### View Controllers
**LoginViewController** : UIViewController, PFLogInViewControllerDelegate  
*The first view that gets loaded on app launch. Initilizes the login and user.*

\- viewDidAppear(animated: Bool)  
*Checks if the user is already logged in, if not, launch the PFLogInViewController from Parse. After logging in, the Friends, FriendRequests and Glimps will be loaded with their Models.*

\- logInViewController(controller: PFLogInViewController, didLogInUser user: PFUser!)  
*Dismisses the PFLogInViewController after log in.*

**HomeViewController** : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate   
*Home view contains most of the controls. By swiping right and left, respectivly the GlimpView and ProfileView will appear. It allows adding, accepting, deleting friends. Asking and answering a GlimpRequest.*  

let columns = CGFloat(4) *How many columns should the thumbnails render*  
var selectedIndexes = \[Int:Bool\]() *Remember which thumbnails have been selected*  
@IBOutlet var collectionView: UICollectionView! *Reference to the collection view. The collection view is split up in four sections, two for a sub header and two for the thumbnails.*  
@IBOutlet var sendBar: UIView! *Reference to send bar*  

\- viewDidLoad()  
*Attach swipe handlers. Initialize layout.*  

\- setSendBar()  
*Show or hide the send bar depending on if users are selected.*  

\- selectAllFriends()  

\- sendGlimpRequest()  
*Uses the GlimpRequestsCollection to send the glimp requests.*  

\- addOrIgnoreFriend()  
*Show action sheet with the options: Accept Request, Delete Request, Cancel. The action handlers will be made on the FriendRequestsCollection.*  

\- UICollectionViewDataSource  
The collectionview is split up in four sections:
- Header (Answer a Glimp)
- Thumbnails with incoming requests
- Header (Ask a Glimp)
- Thumbnails with friends and friend actinos.

Sections two and four are selectable. Meaning didSelectItemAtIndexPath will trigger when tapping on them.  
Section two: Trigger the AnswerGlimpViewController to reply a Glimp.  
Section three: Header contains a button to change the time the other user has to reply.  
Section four: Starts with an 'add-friend' button, when tapping opens a UIAlertViewController with a textfield where the user can enter a name. Continued by all the current friends (select a user or hold to optionally delete friendship), continued by the incoming friend requests (tap triggers addOrIgnoreFriend()).  

**GlimpViewController** : UIViewController, UICollectionViewDataSource  
*For the MVP this shows an overview of all Glimps received. Extra functionalities can include a tab bar that also shows the sent Glimps, delete Glimps, or open a slideshow.*  

\- viewDidLoad()  
*Attach swipe handlers. Initialize layout.*  

\- UICollectionViewDataSource  
Renders the images from the GlimpsCollection  

**ProfileViewController**: UIViewController, UIActionSheetDelegate  
*Show and change your current profile picture.*  

\- viewDidLoad()  
*Attach swipe handlers.*  

\- shouldChangeProfilePicture()  
*Show a UIActionSheet with the option to change the profile picture or cancel.*

\- changeProfilePicture()  
*Calls UserModel.changeProfilePicture()*  

**AnswerGlimpViewController** : UIViewController  
*A view dedicated to answering a glimp.*

var request : PFObject? *The request object of the glimp, passed through from the HomeViewController*  

\- viewDidLoad()  
*Fires up the DBCamera to take a square image.*  

\- answerRequest()  
*Answers the request with the resulting image from DBCamera and removes the request.*  

### Models
**FriendsCollection**  
*Hold a list of friends*  

let user : PFUser *Hold a reference to the current user.*  
var friends : \[PFObject\]? *An array containing all friends.*  

\- init(user: PFUser)  

\- load()  
*(Re)load the data.*  

**FriendRequestsCollection**  
*Manage and hold all friend requests.*

let user : PFUser *Hold a reference to the current user.*  
var requests : \[PFObject\]? *An array containing all friendsrequests.*  

\- init(user: PFUser)  

\- load()  
*(Re)load the data.*  

\- createRequest(toUser: PFObject)  
*Check if this user exists in database. If so, create a FriendRequest object and add his objectId to current users' FriendsCollection.*  

\- acceptRequest(request: PFObject)  
*Add new friends objectId to users friend list, FriendsCollectionModel, delete the request and persist everything to the database.*  

\- deleteRequest(request: PFObject)  
*Delete the request and persist.*  

**GlimpsCollection**  
*Maintain a list of all Glimps received*  

let user : PFUser *Hold a reference to the current user.*  
var glimps : [PFObject]? *Hold a list of all received Glimps*  

\- init(user: PFUser)  

\- load()  
*(Re)load the data.*  

**GlimpRequestsCollection**  
*Maintain a list of all Glimp requests.*  

let user : PFUser *Hold a reference to the current user.*  
var glimpRequests : [PFObject]? *Hold a list of all requests*  

\- init(user: PFUser)  

\- load()  
*(Re)load the data.*  

**UserModel**  
*User-level specific methods.*

let user : PFUser *Hold a reference to the current user.*  

\- init(user: PFUser)  

\- changeProfilePicture()  
*Upload a new profile picture*  

### Database
**User**  
objectId : String  
username : String  
password : String (hashed)  
email : String  
Friends : Array *An array with objectIds of friends*  

**FriendRequest**  
objectId : String  
fromUser : String *objectId of sender*  
toUser : String *objectId of receiver*  

**Glimp**  
*The status of a glimp can be seen by which fields are entered. It is expired when the expiresAt surpasses the current date, it is active when the current date is between createdAt and expiresAt, and it is answered when photo is filled in. Due to this nature, all pending requests can be queried from this table.*  
fromUser : String *objectId of sender*  
toUser : String *objectId of receiver*  
createdAt : Date  
expiresAt : Date *When the request expires*  
photo : File  

### Specific Functionalities
**Friends System**  
Each user holds a list of objectIds of the friends they invited or accepted. The users friendslist can be generated by querying for objectIds that are both in the users and in the friends list. Essentialy, if they have each others id in their friend list, they are friends. When a user wants to add a friend, he adds the friends id in his Friends list and creates a FriendRequest entry. The other friend will then know someone invited him. He can accept or delete the request. Either way the entry will be deleted. If he accepts him, his id will be added to his friends list as well and they are considered friends.  

**Storing Photos**  
The images are first parsed to NSData. This object is stored in a PFFile object and set on the GlimpRequest object. Then the saveInBackgroundWithBlock method is called to upload the photo and update the GlimpRequest object. [See here for more info](https://www.parse.com/tutorials/anypic#post)  

**Refreshing Data**  
Parse does not provide methods to push data to the client. Because of this, a pull-to-refresh will be implemented in all collection views to manually do the update. This reloads the Friends-, FriendRequests- and GlimpsCollection Models.  

**Push Notifications**  
Cloud code is used to send push notifications. [More about that here](https://www.parse.com/tutorials/anypic#push) A notification will be sent in the following scenario's:  
- Someone wants to be your friend.
- Someone accepts your friend request.
- Someone sents you a Glimp request.
- Someone answers your Glimp request.

In all of these scenario's the Data will be automatically refreshed.

### Minimum Viable Product
All of the features above are considered to be part of the MVP (unless indicated otherwise).  

**Additional Features**  
- Create a slideshow for the Glimps received.
- Also show which Glimps you've sent.
- Show a view from a specific user with all the Glimps you have shared. (The rightmost column in the design image.)
- Customize login and register view.

### And now the Design!
![Design](/doc/design.jpg)