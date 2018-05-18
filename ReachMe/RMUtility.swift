//
//  RMUtility.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/20/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import UIKit
import Reachability
import SwiftyUserDefaults
import RxSwift
import RxCocoa
import MobileCoreServices
import UserNotifications
import Photos
import CoreData

class RMUtility: NSObject {
    
    static let kUTTypeHEVC = "public.heic"

    enum ReachMeType {
        case home
        case international
        case voicemail
    }
        
    class func showAlert(withMessage message: String, title: String? = nil) {
        let alert = UIAlertController(style: .alert, title: title, message: message)
        alert.addAction(title: "OK")
        alert.show()
    }
    
    class func isNetwork() -> Bool {
        return Reachability()?.connection != .none
    }
    
    class func convertDictionaryToJSONString(dictionary: [String: Any]) -> String {
        var jsonData = Data()
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        } catch {
            print("Error: Not able to convert from server params data to JSON")
        }
        let resultString = String(data: jsonData, encoding: String.Encoding.utf8)!
        
        return resultString
    }
    
    class func serverRequestConstructPayloadFor(params: [String: Any]) -> String {
        
        var payload: String
        var jsonData = Data()
        do {
            jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        } catch {
            print("Error: Not able to convert from server params data to JSON")
        }
        let resultString = String(data: jsonData, encoding: String.Encoding.utf8)!
        
        let characterset = CharacterSet(charactersIn: "!*'\"();:@&=+$,/?%#[]{}% ").inverted
        payload = resultString.addingPercentEncoding(withAllowedCharacters: characterset)!
        payload = "data=".appending(payload)
        
        return payload
    }
    
    class func parseJSONToArrayOfDictionary(inputString: String) -> [[String: Any]]? {
        if let data = inputString.data(using: String.Encoding.utf8) {
            do {
                let result = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String: Any]]
                return result
            } catch {
                print("Error in JSON Parsing")
            }
        }
        return nil
    }
    
    class func parseJSONToDictionary(inputString: String) -> [String: Any]? {
        if let data = inputString.data(using: String.Encoding.utf8) {
            do {
                let result = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String: Any]
                return result
            } catch {
                print("Error in JSON Parsing")
            }
        }
        return nil
    }
    
    class func serverRequestAddCommonData(params: inout [String: Any]) -> [String: Any] {
        
        params["app_secure_key"] = "b2ff398f8db492c19ef89b548b04889c"
        params["client_app_ver"] = Constants.CLIENT_APP_VER
        params["client_os"] = "i"
        params["client_os_ver"] = UIDevice.current.systemVersion
        params["app_type"] = "rm"
        params["api_ver"] = "2"
        params["user_secure_key"] = Defaults[.APIUserSecureKey]
        let ivUserID = Defaults[.APIIVUserIDKey]
        params["iv_user_id"] = (ivUserID == 0) ? nil : ivUserID
        
        return params
    }

    class func deleteUserProfile() {
        Constants.appDelegate.coreDataStack.deleteAllRecordsForEntity(entity: Constants.EntityName.PROFILE)
        Constants.appDelegate._userProfile = nil
    }
    
    class func isValidImageforServerUpload(pathExtension: CFString) -> Bool {
        var isvalid: Bool = false
        let imageUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeRetainedValue()
        
        if (UTTypeConformsTo(imageUTI!, kUTTypeJPEG)) {
            isvalid = true
        } else if (UTTypeConformsTo(imageUTI!, kUTTypePNG)) {
            isvalid = true
        } else if(UTTypeConformsTo(imageUTI!, kUTTypeHEVC as CFString)) {
            isvalid = true
        } else {
            isvalid = false
        }
       // CFRelease(imageUTI)
        
        return isvalid
    }
    
    class func unlinkForNumber(number: String, completionHandler:@escaping (Bool) -> Void) {
        let predicate = NSPredicate(format: "contactID == %@", number)
        let userContact = Constants.appDelegate.userProfile?.userContacts?.filtered(using: predicate).first as! UserContact
        var params: [String: Any] = ["cmd": Constants.ApiCommands.MANAGE_USER_CONTACT,
                                     "contact": number,
                                     "contact_type": "p",
                                     "operation": "d",
                                     "set_as_primary": false]

        if userContact.isReachMeHomeActive ||
            userContact.isReachMeIntlActive ||
            userContact.isReachMeVoiceMailActive {
            let alert = UIAlertController(style: .alert, title: "Unlink number from account?", message: "If you are unlinking the number from account, we will deactivate ReachMe For this number.")
            alert.addAction(title: "Cancel")
            alert.addAction(title: "Continue", handler: { _ in
                guard RMUtility.isNetwork() else {
                    RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                    return
                }
                
                ANLoader.showLoading("", disableUI: true)
                ServiceRequest.shared.startRequestForManageUserContact(withManagedInfo: &params) { (responseDics, success) in
                    guard success else { return }
                    completionHandler(success)
                    RMUtility.showAlert(withMessage: "Number has been deleted successfully")
                }
            })
            alert.show()

        } else {
            
            guard RMUtility.isNetwork() else {
                RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                return
            }
            
            let alert = UIAlertController(style: .alert, title: """
                Confirm Delete
                +\(number)
                """, message: "You are about to delete this number from your account, are you sure?")
            alert.addAction(title: "Cancel")
            alert.addAction(title: "Confirm", handler: { _ in
                guard RMUtility.isNetwork() else {
                    RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                    return
                }
                
                ANLoader.showLoading("", disableUI: true)
                ServiceRequest.shared.startRequestForManageUserContact(withManagedInfo: &params) { (responseDics, success) in
                    guard success else { return }
                    completionHandler(success)
                    RMUtility.showAlert(withMessage: "Number has been deleted successfully")
                }
            })
            alert.show()
        }
    }
    
    class func handleHelpSupportAction(withHelpText helptext: String?) {
        
        let predicate = NSPredicate(format: "supportType == %@", "Help")
        if let supportHelp = Constants.appDelegate.userProfile?.supportContacts?.filtered(using: predicate).first as? SupportContact {
            guard RMUtility.isNetwork() else {
                RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                return
            }
            print("\(supportHelp)")
            //TODO: Chart VC  BaseConversationScreen_4.0_ios7Master
            
        } else {
            RMUtility.showAlert(withMessage: "NO_SUPPORT_LIST".localized)
        }
    }
    
    class func showdDashboard() {
        let tabBarVC = UIStoryboard.dashboard().instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
        Constants.appDelegate.window?.rootViewController = tabBarVC
    }
    
    class func translatePrural(forKey key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }
    
    class func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            
            guard granted else {
                let alert = UIAlertController(style: .alert, title: "Turn On Notifications", message: "To receive Voicemail and Missed call instantly, Notifications must be enabled for ReachMe app. Tap Settings to turn on Notifications.")
                alert.addAction(title: "Cancel")
                alert.addAction(title: "Settings", handler: { _ in
                    UIApplication.shared.open(URL(string: "App-Prefs:root=Notifications")!, options: [:], completionHandler: nil)
                })
                alert.show()
                return
            }
            
            let viewAction = UNNotificationAction(identifier: "testView",
                                                  title: "Go To Call Detail",
                                                  options: [.foreground])
            
            let newsCategory = UNNotificationCategory(identifier: "ivMsg",
                                                      actions: [viewAction],
                                                      intentIdentifiers: [],
                                                      options: [])
            UNUserNotificationCenter.current().setNotificationCategories([newsCategory])
            
            RMUtility.getNotificationSettings()
        }
    }
    
    class func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    class func convertUTCNumberToDateString(number: Int64) -> String {
        let value = Double(number) / 1000
        let date = Date.init(timeIntervalSince1970: value)
        let timeSinceDate = Date().timeIntervalSince(date)
        let minutesSinceDate = timeSinceDate / 86400

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        
        if timeSinceDate < 86400 {
            dateFormatter.timeStyle = .short
        } else if minutesSinceDate <= 7 {
            dateFormatter.dateFormat = "EEEE"
        } else {
            dateFormatter.dateStyle = .short
        }
        
        return dateFormatter.string(from: date)
    }
    
    class func getPayloadForMQTT() -> Data {
        var params: [String: Any] = ["cmd": Constants.ApiCommands.APP_STATUS,
                                     "status": (UIApplication.shared.applicationState == .background) ? "bg" : "fg",
                                     "last_msg_id": Defaults[.APIFetchAfterMsgID] as Any]
        params = RMUtility.serverRequestAddCommonData(params: &params)
        
        var jsonData = Data()
        do {
            jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        } catch {
            print("Error: Not able to convert Dictionary to Data for MQTT Payload")
        }
        return jsonData
    }
    
    class func getImageData(asset: PHAsset) -> Data? {
        var returnData: Data?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            if let data = data {
                returnData = data
            }
        }
        return returnData
    }
    
    class func getDateFromYearMonthDay(year: Int, month: Int, day: Int) -> Date? {
        var dateComp = DateComponents()
        dateComp.year = year
        dateComp.month = month
        dateComp.day = day
        
        let gregorian = NSCalendar(identifier: .gregorian)
        let date = gregorian?.date(from: dateComp)
        return date
    }
    
    class func getDOBStringFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.string(from: date)
    }
    
    class func getProfileforConext(context: NSManagedObjectContext) -> Profile? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
        do {
            let results = try context.fetch(fetchRequest)
            guard let profileList = results as? [Profile] else { return nil }
            return profileList.first
        } catch let error as NSError {
            print("CoreData - Fetch failed: \(error.localizedDescription)")
        }
        return nil
    }
}

extension Reactive where Base: UIButton {
    var RxEnabled: Binder<Bool> {
        return Binder(base) { button, enabled in
            button.alpha = enabled ? 1.0 : 0.7
            button.isEnabled = enabled ? true : false
        }
    }
}
