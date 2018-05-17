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

    public class func fetchContacts( completionHandler: @escaping (_ success: Bool) -> Swift.Void) {
        DispatchQueue.global(qos: .userInitiated).async(execute: {
            let contactFetchRequest = CNContactFetchRequest(keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
            
            Constants.appDelegate.coreDataStack.performBatchTask(inContext: { (context, saveBlock) in
                let userProfile = RMUtility.getProfileforConext(context: context)!
                do {
                    try self.contactStore.enumerateContacts(with: contactFetchRequest, usingBlock: { (contact, stop) -> Void in
                        var phoneNumbers = [ContactPhone]()
                        var emailAddresses = [String]()
                        if contact.phoneNumbers.count > 0 || contact.emailAddresses.count > 0 {
                            
                            let deviceContact = NSEntityDescription.insertNewObject(forEntityName: Constants.EntityName.DEVICECONTACT, into: context) as! DeviceContact
                            deviceContact.firstName = contact.givenName
                            deviceContact.lastName = contact.familyName
                            deviceContact.contactId = contact.identifier
                            if contact.imageDataAvailable {
                                deviceContact.contactPicData = contact.imageData
                            }
                            
                            for phoneLabel: CNLabeledValue in contact.phoneNumbers {
                                let CNNumber  = phoneLabel.value
                                //let countryCode = CNNumber.value(forKey: "countryCode") as! String
                                let mobileNumber = CNNumber.value(forKey: "digits") as! String
                                let number = try! PhoneNumberKit().parse(mobileNumber)
                                let formatedNumber = PhoneNumberKit().format(number, toType: .international)
                                let contactPhone = ContactPhone.init(phoneNumber: mobileNumber, formatedNumber: formatedNumber, type: phoneLabel.label?.trim())

                                phoneNumbers.append(contactPhone)
                            }
                            deviceContact.phones = phoneNumbers
                            
                            for emailLabel: CNLabeledValue in contact.emailAddresses {
                                emailAddresses.append(String(emailLabel.value))
                                deviceContact.isEmailType = true
                            }
                            deviceContact.emails = emailAddresses
                            
                            userProfile.addToDeviceContacts(deviceContact)
                        }
                    })
                    
                } catch let error as NSError {
                    print("Error in Fetch Contacts: \(error.localizedDescription)")
                    completionHandler(false)
                }

                if let error = saveBlock() {
                    print("Contact Sync: - Coredata merge failed from writer context to default context. \(error.localizedDescription)")
                }
                
            }, andInMainThread: {
                completionHandler(true)
            })
        })
    }
}

public class ContactPhone: NSObject, NSCoding {
    
    var phoneNumber: String?
    var formatedNumber: String?
    var type: String?
    
    enum Key: String {
        case phoneNumber
        case formatedNumber
        case type
    }
    init(phoneNumber: String?, formatedNumber: String?, type: String?) {
        self.phoneNumber = phoneNumber
        self.formatedNumber = formatedNumber
        self.type = type
    }
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(phoneNumber, forKey: Key.phoneNumber.rawValue)
        aCoder.encode(formatedNumber, forKey: Key.formatedNumber.rawValue)
        aCoder.encode(type, forKey: Key.type.rawValue)
    }
    convenience required public init?(coder aDecoder: NSCoder) {
        let phoneNumber = aDecoder.decodeObject(forKey: Key.phoneNumber.rawValue) as? String
        let formatedNumber = aDecoder.decodeObject(forKey: Key.formatedNumber.rawValue) as? String
        let type = aDecoder.decodeObject(forKey: Key.type.rawValue) as? String
        self.init(phoneNumber: phoneNumber, formatedNumber: formatedNumber, type: type)
    }
}
