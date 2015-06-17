//
//  AppDelegate.swift
//  Glimp
//
//  Created by Joram Ruitenschild on 01-06-15.
//  Copyright (c) 2015 Joram Ruitenschild. All rights reserved.
//

import UIKit
import Parse
import Bolts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        UIApplication.sharedApplication().statusBarHidden = true
        
        // [Optional] Power your app with Local Datastore. For more info, go to
        // https://parse.com/docs/ios_guide#localdatastore/iOS
        Parse.enableLocalDatastore()
        
        // Initialize Parse.
        Parse.setApplicationId("4pO9hsMdcEHxoFFVC1GWR05P1uZZt7W8COIvsBnb", clientKey: "RfZZ8PUwWNaEaRmrOkBgcJER5dw0u56la449Wswh")
        
        // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        if application.respondsToSelector(Selector("registerUserNotificationSettings:")) {
            let notificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
            let settings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
        } else {
            let notificationTypes = UIRemoteNotificationType.Alert | UIRemoteNotificationType.Badge | UIRemoteNotificationType.Sound
            application.registerForRemoteNotificationTypes(notificationTypes)
        }
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            println("Push notifications are not supported in simulator")
        } else {
            println("application:didFailToRegisterForRemoteNotificationsWithError: \(error)")
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
        RefreshData()
    }
    
    func logOut() {
        Friends.destroy()
        Requests.destroy()
        Glimps.destroy()
        
        let installation = PFInstallation.currentInstallation()
        installation.removeObjectForKey("User")
        installation.saveInBackground()
        
        PFUser.logOutInBackgroundWithBlock { (error) -> Void in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as LoginViewController
            self.window!.rootViewController = controller
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

