//
//  AppDelegate.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/15/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import CoreData
import SwiftyUserDefaults
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var bgService: ServiceRequestBackground!
    var userProfile: Profile? = CoreDataModel.sharedInstance().getUserProfle()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

       // UISearchBar.appearance().tintColor = UIColor.ReachMeColor()
        window?.tintColor = UIColor.ReachMeColor()

        //UINavigationBar.appearance().tintColor = UIColor.ReachMeColor()
        
//        let reachMeNavVC = UIStoryboard(name: "NavController", bundle: nil).instantiateViewController(withIdentifier: "ReachMeNavControllerID") as! UINavigationController
//        let activateReachMeVC = UIStoryboard(name: "ActivateReachMe", bundle: nil).instantiateViewController(withIdentifier: Constants.STORYBOARD_ID_ACTIVATE_REACHME) as! ActivateReachMeViewController
//        reachMeNavVC.viewControllers = [activateReachMeVC]
//        window?.rootViewController = reachMeNavVC
        
        let reachMeNavVC = UIStoryboard(name: "NavController", bundle: nil).instantiateViewController(withIdentifier: "ReachMeNavControllerID") as! UINavigationController
        // Check if launched from notification
        if let _ = launchOptions?[.remoteNotification] as? [String: AnyObject], Defaults[.IsLoggedInKey] {
            //TODO:--
            // let aps = notification["aps"] as! [String: AnyObject]
            
        //If Carrier not selected, display carrier list
        } else if Defaults[.IsCarrierSelection] {
            let selectCarrierVC = UIViewController.selectCarrierViewController()
            reachMeNavVC.viewControllers = [selectCarrierVC]
            window?.rootViewController = reachMeNavVC
            
            //If onboarding not done, show onboarding
        } else if Defaults[.IsOnBoarding] {
            let activateReachMeVC = UIViewController.activateReachMeViewController()
            reachMeNavVC.viewControllers = [activateReachMeVC]
            window?.rootViewController = reachMeNavVC
            
            //If Personalisation not done, show Personalisation
        } else if Defaults[.IsPersonalisation] {
            let personalisationVC = UIViewController.personalisationViewController()
            reachMeNavVC.viewControllers = [personalisationVC]
            window?.rootViewController = reachMeNavVC
            
        } else if Defaults[.IsLoggedInKey] {
            //ServiceRequest.shared().connectMQTT()
            UNUserNotificationCenter.current().delegate = self
            RMUtility.registerForPushNotifications()
            RMUtility.showdDashboard()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        ServiceRequest.shared().disConnectMQTT()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
//        if Defaults[.IsLoggedInKey] {
//            ServiceRequest.shared().connectMQTT()
//            ServiceRequest.shared().startRequestForFetchMessages(completionHandler: nil)
//        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        if Defaults[.APICloudeSecureKey] != token || Defaults[.needSetDeviceInfo] {
            ServiceRequest.shared().startRequestForSetDeviceInfo(forDeviceToken: token, completionHandler: {
                Defaults[.needSetDeviceInfo] = false
            })
        } else {
            print("New and Cached device tokens are same.")
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register Remotenotification: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
       // let aps = userInfo["aps"] as! [String: AnyObject]
        
        switch application.applicationState {
        case .active:
            ServiceRequest.shared().startRequestForFetchMessages(completionHandler: nil)

        case .background:
            guard bgService == nil else {
                completionHandler(.noData)
                return
            }
            
            bgService = ServiceRequestBackground()
            bgService.startRequestForFetchMessages(completionHandler: { (success) in
                self.bgService = nil
                guard success else {
                    completionHandler(.noData)
                    return
                }
                completionHandler(.newData)
            })
            
        default:
            completionHandler(.newData)

        }

    }
}

extension AppDelegate {
   
}

// MARK: - Push Notification Delegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler   completionHandler: @escaping (_ options: UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
    }
}
