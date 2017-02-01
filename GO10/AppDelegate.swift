    //
//  Copyright (c) Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
import UIKit
import CoreData
import Fabric
import Crashlytics
import IQKeyboardManagerSwift
import Siren
import BMSCore
import BMSPush

    
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    var window: UIWindow?
    var signInType: String?
    var badgeCount: Int = 9
    
    func application(application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
//        print("UUID : \(UIDevice.currentDevice().identifierForVendor?.UUIDString)")
        NSLog((UIDevice.currentDevice().identifierForVendor?.UUIDString)!, "asdlfkjsldkfnkdwafkl;adfl;k")
        
        let myBMSClient = BMSClient.sharedInstance
        myBMSClient.initialize(bluemixRegion: BMSClient.Region.sydney)
        
        let push =  BMSPushClient.sharedInstance
//        push.initializeWithAppGUID(appGUID: "3c5e9860-be2b-4276-a53b-b12f0d3db6bb", clientSecret:"f1b7da23-fe5e-40d4-99b5-ca39eaae8b35")
        
        let actionOne = BMSPushNotificationAction(identifierName: "FIRST", buttonTitle: "Accept", isAuthenticationRequired: false, defineActivationMode: UIUserNotificationActivationMode.Background)
        
        let actionTwo = BMSPushNotificationAction(identifierName: "SECOND", buttonTitle: "Reject", isAuthenticationRequired: false, defineActivationMode: UIUserNotificationActivationMode.Background)
        
        let category = BMSPushNotificationActionCategory(identifierName: "category", buttonActions: [actionOne, actionTwo])
        
        let notificationOptions = BMSPushClientOptions(categoryName: [category])
        
        push.initializeWithAppGUID(PropertyUtil.getPropertyFromPlist("data",key: "AppGUID"), clientSecret:PropertyUtil.getPropertyFromPlist("data",key: "clientSecret"), options: notificationOptions)
        
        let remoteNotif = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary
        
        if remoteNotif != nil {
            let urlField = remoteNotif?.valueForKey("url") as! String
            UIApplication.sharedApplication().openURL(NSURL(string: urlField)!)
        }

                FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
                var configureError: NSError?
                GGLContext.sharedInstance().configureWithError(&configureError)
                assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
//        showBadgeNumber()
        addObjToCoreData("Notification",val:100, key: "badgeNumber")
//        Fabric.with([Crashlytics.self])
        IQKeyboardManager.sharedManager().enable = true
//        window?.makeKeyAndVisible()
//        setupSiren()
        return true
        
    }
    
    func application(application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: NSError){
        print("**************************** didFailToRegisterForRemoteNotificationsWithError")
        print(error)
    }
    
    func application (application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData){
        print("**************************** didRegisterForRemoteNotificationsWithDeviceToken \(deviceToken) ")
        let push =  BMSPushClient.sharedInstance
        
        push.registerWithDeviceToken(deviceToken, WithUserId: "jirapaschi") { (response, statusCode, error) -> Void in
            if error.isEmpty {
                print( "Response during device registration : \(response)")
                print( "status code during device registration : \(statusCode)")
            }else{
                print( "Error during device registration \(error) ")
                print( "Error during device registration \n  - status code: \(statusCode) \n Error :\(error) \n")
            }
        }
    }
    
    // Send notification status when app is opened by clicking the notifications
//    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
//        print("**************************** didReceiveRemoteNotification clicking the notifications")
//        let respJson = (userInfo as NSDictionary).valueForKey("payload") as! String
//        let data = respJson.dataUsingEncoding(NSUTF8StringEncoding)
//        
//        do {
//            let responseObject:NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary
//            let nid = responseObject.valueForKey("nid") as! String
//            print(nid)
//            
//            let push =  BMSPushClient.sharedInstance
//            
//            push.sendMessageDeliveryStatus(nid, completionHandler: { (response, statusCode, error) in
//                
//                print("Send message status to the Push server")
//            })
//            
//        } catch let error as NSError {
//            print("error: \(error.localizedDescription)")
//        }
//    }
    
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        print("**************************** didReceiveRemoteNotification")
        
        let payLoad = ((((userInfo as NSDictionary).valueForKey("aps") as! NSDictionary).valueForKey("alert") as! NSDictionary).valueForKey("body") as! NSString)
        print("payload \(payLoad)")
        let alert = UIAlertController(title: "Recieved Push notifications", message: payLoad as String, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
        self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)

        let respJson = (userInfo as NSDictionary).valueForKey("payload") as! String
        let data = respJson.dataUsingEncoding(NSUTF8StringEncoding)
        
        do {
            let responseObject:NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary
            let nid = responseObject.valueForKey("nid") as! String
            print("nid \(nid)")
            let push =  BMSPushClient.sharedInstance
            
            push.sendMessageDeliveryStatus(nid, completionHandler: { (response, statusCode, error) in
                completionHandler(UIBackgroundFetchResult.NewData)
            })
            
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func showBadgeNumber()
    {
//        self.badgeCount += 1
        NSLog("badgeCount : \(self.badgeCount)")
        let application = UIApplication.sharedApplication()
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Badge, .Alert, .Sound], categories: nil))
        application.applicationIconBadgeNumber = self.badgeCount
    }
    
    func setupSiren() {
        let siren = Siren.sharedInstance
        siren.delegate = self
        siren.debugEnabled = true
        siren.majorUpdateAlertType = .Option
        siren.minorUpdateAlertType = .Option
        siren.patchUpdateAlertType = .Option
        siren.revisionUpdateAlertType = .Option
        print("XXXXXXXXXXXXXXX : setupSiren")
        siren.checkVersion(.Immediately)
    }
    
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("XXXXXXXXXXXXXXX : applicationWillEnterForeground")
        Siren.sharedInstance.checkVersion(.Immediately)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("XXXXXXXXXXXXXXX : applicationDidBecomeActive")
        print("XXXXXXXXXXXXXXX BadgeNumberFromCoreDate \(getValuefromCoreDate("Notification", key: "badgeNumber") as! Int)")
//        self.badgeCount = 0
//        showBadgeNumber()
        Siren.sharedInstance.checkVersion(.Daily)
    }
    
    func addObjToCoreData(entityName:String,val:AnyObject,key:String){
        print("XXXXXXXXXXXXXXX : addObjToCoreData")
        let context: NSManagedObjectContext = self.managedObjectContext
        do{             let fetchReq = NSFetchRequest(entityName: entityName)
            let result = try context.executeFetchRequest(fetchReq)
            if(result.count > 0){
                print("set Old User")
                result[0].setValue(val, forKey: key)
            }else{
                print("set New User")
                let newUser = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context)
                newUser.setValue(val, forKey: key)
            }
            try context.save()
            print("\(NSDate().formattedISO8601) Save Data Success")
        }catch{
            print("\(NSDate().formattedISO8601) Error Saving Profile Data")
        }
    }
    
    func getValuefromCoreDate(entityName:String,key:String) -> AnyObject{
        let context: NSManagedObjectContext = self.managedObjectContext
        do{
            let fetchReq = NSFetchRequest(entityName: entityName)
            let result = try context.executeFetchRequest(fetchReq) as! [NSManagedObject]
            return result[0].valueForKey(key)!
        }catch{
            print("\(NSDate().formattedISO8601) Error Reading Data")
            return false
        }
    }

    
    func application(application: UIApplication,
                     openURL url: NSURL, sourceApplication: String?,
                             annotation: AnyObject) -> Bool {
        
        print("signInType \(signInType)")
        if(signInType == "Facebook"){
            return FBSDKApplicationDelegate.sharedInstance().application(
                application,
                openURL: url,
                sourceApplication: sourceApplication,
                annotation: annotation)
        } else {
            return GIDSignIn.sharedInstance().handleURL(url,
                                                        sourceApplication: sourceApplication,
                                                        annotation: annotation)
        }
        
    }
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,
                withError error: NSError!) {
        print("signin AppDeligate")
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!,
                withError error: NSError!) {
    }
    
    
    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "co.th.gosoft.testCoreData" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("GO10", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}
    extension AppDelegate: SirenDelegate
    {
        func sirenDidShowUpdateDialog(alertType: SirenAlertType) {
            print(#function, alertType)
        }
        
        func sirenUserDidCancel() {
            print(#function)
        }
        
        func sirenUserDidSkipVersion() {
            print(#function)
        }
        
        func sirenUserDidLaunchAppStore() {
            print(#function)
        }
        
        func sirenDidFailVersionCheck(error: NSError) {
            print(#function, error)
        }
        
        func sirenLatestVersionInstalled() {
            print(#function, "Latest version of app is installed")
        }
        
        /**
         This delegate method is only hit when alertType is initialized to .None
         */
        func sirenDidDetectNewVersionWithoutAlert(message: String) {
            print(#function, "\(message)")
        }
    }

