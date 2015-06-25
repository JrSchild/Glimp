## Final Report
Glimp lets users ask for a Glimp (glimpse) in someone's life when yóu want it. Current social media is built around push content. Your friends determine when and what they push to you. You don't have any control over this. With Glimp, the user is in control of what he/she receives content from and when. This is called pull-messaging. The content sent is unique because users are only able to send the pictures to one person. The Glimps are made at a specific moment because the user can set a timer how much time your friend has to answer. All Glimps are collected and can only be seen by the user himself.

The app works as following: Select a friend from your contacts, choose how much time he has to answer and press sent. Your friend receives a notification on his phone, makes a photo and sends it back. This picture is called a Glimp and is added to your collection of other Glimps.

Glimp provides a solution to the decreasing interest-span of friends with conventional social media like Facebook and Instagram. 20 - 30% of your Facebook friends are power-users. This is a small group of people who generate roughly 80% of the content for you to see. The interest-span in your friends decreases over time because you always see the same kind of content from the same people. Glimp solves this problem by keeping the interest-span in your friends high: You specifically ask for content, everything is unique and only meant for you.

Users define what Glimp means for them. Glimp is exciting because you never know from whom you will receive a request, it is intuitive because when timer runs out it is up to you what to do and it is playful because you can collect glimpses of your friends' life when you feel like it. No longer will you have a Facebook feed with content you didn't ask for. All the material you receive is personal and only meant for you. You are in control of the content you receive.

### Technical Overview
Anything with regard to the representation in the view is done in the ViewControllers. For instance, rendering of data, providing user feedback, retrieving user input is handled in there. The app is bound together by five ViewControllers. At first the LoginViewController is loaded to check if the user is logged in, if not it will show the LoginView provided by Parse. When the user is present, the controller will load the HomeViewController. This is where main functionality of the app is implemented. This view shows all your friends, incoming/outgoing Glimp requests and incoming/outgoing Friend requests. From here the user can: accept/ignore a friend request, add a new friend and answer a Glimp request.

Upon sliding left the GlimpViewController will appear. This view simply shows all the Glimps you have received. When sliding right from the HomeViewController the ProfileView shows. Here the user can change his profile picture, see his user information and log out. If the user tap-holds a friend in the HomeView the SharedGlimpViewController slides in. This view shows all the Glimps you have shared with this user.

##### Data Handling
Manipulation of data, retrieving and storing of objects is done in the Collections. They abstract all the data handling into specific singletons. Each collection is inherited from the base Collection class. This class provides methods for loading, destroying and notifying (more on that below) of data.  
The collections are instantiated the moment the app is loaded. Each collection holds one or more arrays of data. Every collection has individual methods for filtering and manipulating data. The FriendsCollection for instance only stores an array of Friends, but the GlimpsCollection has an array for the Glimps sent, -received and for the requests sent, -received. This data can be retrieved with one detailed query and is then placed in their specific arrays. All these arrays will be empty the moment they are initialized and seeded when the data is loaded.

The GlimpsRequestCollection has methods for sending and answering a Glimp request, makes sure requests are deleted when they expire and finding the shared Glimps between users. The FriendRequestsCollection is responsible for handling incoming and outgoing friend requests. The FriendsCollection only stores a list of current Friends.

RefreshData is a global method used to reload all the collections described above in parallel. This is done with `dispatch_group_enter` and `dispatch_group_leave`. By loading collections in parallel all data can be loaded at the same time which results in a big performance boost over loading in waterfall (one after the other).

##### Parse
The focus of this project lies in app development. Creating an API, setting up and maintaining a server would be time consuming and outside of the scope of this project. Parse provides a great abstraction for anything related with data. It provides a login screen, querying, file uploading, caching and much more. This made the development so much smoother because it made me focus on the app and user experience, rather than the database.

### Design Decissions
##### Notifying Views
Data in the app is stored across different collections. This abstracts the data handling away from the views and makes it easier to use in separate  places. The problem this brings is that views need to know when the data is updated so it can be recalculated. The collections need to notify every class that is dependent of that data. I have looked at several implementations for an EventEmitter, I have found that none of them suited my needs. Eventually I have decided to settle with the native NSNotificationsCenter. The syntax is a little bit verbose, but I decided to user it because it provides a powerful set of features for notifications and automatically cleans up listeners.  
Each collection has its own notification-key. When a ViewController is instantiated it attaches a listener with that key. When a notification comes in, the view knows it needs to update its content to keep the data synchronized between memory and view.

##### Friend System
Each user holds an array of objectIds of the friends they invited or accepted. The users friendslist can be generated by querying for objectIds that are both in the users and in the friends list. Essentially, if they have each other's id in their friend list, they are friends. When a user wants to add a friend, he adds the friend's id in his Friends list and creates a FriendRequest entry. The other friend will then know someone invited him. He can accept or delete the request. If he accepts him, his id will be added to his friends list as well and they are considered friends.  
All of this functionality is implemented in the FriendsRequestCollection. This turned out to work very well and some fellow students have implemented this approach as well.

##### Taking Square Images
Square pictures have been a design decission to get rid of horizontal or portrait images. Initially I planned to implement DBCamera, this is a custom camera which is able to take pictures form a square camera view. This turned out harder to implement that I thought. Also when a user uploads a profile picture it still needs to be cropped to square proportions.  
Because of this I decided to implement a cropper view which requires the user to always use. This allows the user to scale and move the picture. At first I implemented BABCropperView, this worked fine until I found a bug where portrait images weren't scaled properly. The author of this library didn't seem very responsive so I eventually I moved to VKImageCropper.

##### Thumbnail CollectionView
At three different places a set of thumbnails is shown in a four-column format. I subclassed the standard UICollectionView to configure the view with custom settings. It initializes the super class with a custom layout and registers common custom cell classes. This works well because now the CollectionView only needs to be configured in one place and can be used across the entire application.

##### Custom Transitions
Navigating across the app is mostly done with swipe gestures between views. The standard navigation has limitations with dynamically added ViewControllers. This is why I choose to create a custom Segue. When a view is loaded, the controller attaches the swipe gestures, which perform a Segue when triggered. The basic Segue-classes are written by Gabriel Theodoropoulos and I adjusted them to work left-to-right and right-to-left. The current implementation is not optimal but works best for the current scenario.

##### Thumbnail CollectionViewCell
Each square cell in a ThumbnailCollectionView is a subclassed CollectionViewCell. A ThumbnailCell could be in one of the following states: selected, in/outgoing friend request, running in/outgoing Glimp request. Also an image should be able to set on the cell. All other properties can be hidden or made visible depending on state/type. A cell has a reset method to set all the subviews to hidden. Because cells are reused this doesn't cause any performance overhead.