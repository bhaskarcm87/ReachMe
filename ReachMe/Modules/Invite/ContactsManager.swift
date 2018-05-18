//
//  ContactsManager.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 5/16/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import Contacts
import ContactsUI
import CoreData
import PhoneNumberKit

public class ContactsManager {
    
    public static var contactStore  = CNContactStore()
    
    class func requestForAccess(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch authorizationStatus {
        case .authorized:
            completionHandler(true)
            
        case .denied, .notDetermined:
            self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(access)
                } else {
                    if authorizationStatus == CNAuthorizationStatus.denied {
                        let alert = UIAlertController(style: .alert, title: "Contacts Permission", message: "CONTACT_ACCESS_WARNING".localized)
                        alert.addAction(title: "Cancel", style: .destructive)
                        alert.addAction(title: "Settings", handler: { _ in
                            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        })
                        alert.show()
                    }
                }
            })
            
        default:
            completionHandler(false)
        }
    }

    public class func fetchContacts(completionHandler: @escaping (_ success: Bool) -> Swift.Void) {
        DispatchQueue.global(qos: .userInitiated).async(execute: {
            let contactFetchRequest = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
            var contactList = [CNContact]()
            do {
                try self.contactStore.enumerateContacts(with: contactFetchRequest, usingBlock: { (contact, stop) -> Void in
                    if contact.phoneNumbers.count > 0 || contact.emailAddresses.count > 0 {
                        contactList.append(contact)
                    }
                })
            } catch let error as NSError {
                print("Error in Fetch Contacts: \(error.localizedDescription)")
                completionHandler(false)
            }
            
            Constants.appDelegate.coreDataStack.performBackgroundTask(inContext: { (context, saveBlock) in
                let userProfile = RMUtility.getProfileforConext(context: context)!
                
                for contact in contactList {
                    let deviceContact = NSEntityDescription.insertNewObject(forEntityName: Constants.EntityName.DEVICECONTACT, into: context) as! DeviceContact
                    deviceContact.contactName = contact.givenName + " \(contact.familyName)"
                    deviceContact.contactId = contact.identifier
                    if contact.imageDataAvailable {
                        deviceContact.contactPicData = contact.imageData
                    }
                    
                    for phoneLabel: CNLabeledValue in contact.phoneNumbers {
                        let CNNumber  = phoneLabel.value
                        //let countryCode = CNNumber.value(forKey: "countryCode") as! String
                        let phoneNumber = NSEntityDescription.insertNewObject(forEntityName: Constants.EntityName.PHONENUMBER, into: context) as! PhoneNumber

                        let mobileNumber = CNNumber.value(forKey: "digits") as! String
                        let number = try! PhoneNumberKit().parse(mobileNumber)
                        phoneNumber.number = mobileNumber
                        phoneNumber.displayFormatNumber = CNNumber.value(forKey: "stringValue") as? String
                        phoneNumber.syncFormatNumber = "\((PhoneNumberKit().format(number, toType: .e164)).dropFirst())"
                        phoneNumber.labelType = phoneLabel.label?.trim()
                        deviceContact.addToPhones(phoneNumber)
                    }
                    
                    for emailLabel: CNLabeledValue in contact.emailAddresses {
                        let emailaddress = NSEntityDescription.insertNewObject(forEntityName: Constants.EntityName.EMAILADDRESS, into: context) as! EmailAddress
                        emailaddress.emailID = String(emailLabel.value)
                        emailaddress.labelType = emailLabel.label?.trim()
                        deviceContact.addToEmails(emailaddress)
                    }
                    
                    userProfile.addToDeviceContacts(deviceContact)
                    
                    if let error = saveBlock(true) {
                        print("Contact Sync: - Coredata merge failed from writer context to default context. \(error.localizedDescription)")
                    }
                }
                
            }, andInMainThread: {
                completionHandler(true)
            })
        })
    }
    
    class func syncAllContactsWithServer(completionHandler: @escaping (_ success: Bool) -> Swift.Void) {
        Constants.appDelegate.coreDataStack.perform(inContext: { (context) in
            let fetchRequest: NSFetchRequest<PhoneNumber> = PhoneNumber.fetchRequest()
            let phoneNumbers = try! context.fetch(fetchRequest)
            var startIndex = 0, endIndex = 500
            if endIndex > phoneNumbers.count {
                endIndex = phoneNumbers.count
            }
            var isLastLoop = false
            while (phoneNumbers.count >= endIndex) {
                var contactList = [String]()
                for i in startIndex..<endIndex {
                    contactList.append(phoneNumbers[i].syncFormatNumber!)
                }
                
                ServiceRequest.shared.startRequestForEnquireIVUsers(contactList: contactList, completionHandler: { (responseDics, success) in
                    guard success else { return }
                    
                    if let contactIDs = responseDics!["iv_contact_ids"] as? [[String: Any]] {
                        for contactID in contactIDs {
                            let filteredNumber = phoneNumbers.filter({ (phoneNumber: PhoneNumber) -> Bool in
                                return phoneNumber.syncFormatNumber! == contactID["contact_id"] as! String
                            }).first!
                            filteredNumber.ivUserId = contactID["iv_user_id"] as! Int64
                            filteredNumber.parent?.isIV = true
                            filteredNumber.parent?.ivPicURL = contactID["pic_uri"] as? String
                            if let displayName = contactID["display_name"] as? String {
                                let numbersRange = displayName.rangeOfCharacter(from: .decimalDigits)
                                if numbersRange == nil {
                                    filteredNumber.parent?.contactName = displayName
                                }
                            }
                        }
                    }
                    
                    _ = context.saveToParentsAndWait()
                })

                if isLastLoop {
                    break
                }
                startIndex = endIndex
                endIndex += 500
                if endIndex > phoneNumbers.count {
                    endIndex = phoneNumbers.count
                    isLastLoop = true
                }
            }

        }, andInMainThread: {
            completionHandler(true)
        })
    }
}
