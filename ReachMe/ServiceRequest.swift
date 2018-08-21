//
//  ServiceRequest.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/23/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyUserDefaults
import PhoneNumberKit
import CountryPickerView
import UserNotifications
import CoreData
import SwiftyJSON

open class ServiceRequest: NSObject {
    
    public static let shared = ServiceRequest()
    private let coreDataStack = Constants.appDelegate.coreDataStack
        
    var mqttSession: MQTTSession?
    
    func connectMQTT() {
        let clientID = String(format: "iv/pn/device%012ld", (Constants.appDelegate.userProfile?.mqttSettings?.mqttDeviceID)!)
        self.mqttSession = MQTTSession(host: Constants.URL_MQTT_SERVER,
                                  port: 8883,
                                  clientID: clientID,
                                  cleanSession: true,
                                  keepAlive: 60,
                                  useSSL: true)
        self.mqttSession?.delegate = self
    
        self.mqttSession?.connect {
            guard $0 else { print("Error Occurred During MQTT Connection \($1)"); return }
            
            self.mqttSession?.subscribe(to: clientID, delivering: .atLeastOnce) {
                guard $0 else { print("Error Occurred During MQTT Subscribe \($1)"); return }
                
                let payload = RMUtility.getPayloadForMQTT()
                self.mqttSession?.publish(payload, in: (Constants.appDelegate.userProfile?.mqttSettings?.chatTopic)!, delivering: .atLeastOnce, retain: false, completion: {
                    guard $0 else { print("Error Occurred During MQTT Connect Publish \($1)"); return }
                })
            }
        }
    }
    
    func disConnectMQTT() {
        let payload = RMUtility.getPayloadForMQTT()
        mqttSession?.publish(payload, in: (Constants.appDelegate.userProfile?.mqttSettings?.chatTopic)!, delivering: .atLeastOnce, retain: false, completion: {

            self.mqttSession?.disconnect()
            guard $0 else { print("Error Occurred During MQTT Disconnect Publish \($1)"); return }
        })
    }

    func parseCommonResponseforLoginProcess(responseDics: [String: JSON]) {
        Defaults[.APIUserSecureKey] = responseDics[DefaultsKeys.APIUserSecureKey._key]?.stringValue
        Defaults[.APIIVUserIDKey] = (responseDics[DefaultsKeys.APIIVUserIDKey._key]?.intValue)!

        coreDataStack.performBackgroundTask(inContext: { (context, saveBlock) in
            let userProfile = RMUtility.getProfileforConext(context: context)
            userProfile?.volumeMode = .Speaker
            userProfile?.fbConnectURL = responseDics["fb_connect_url"]?.stringValue
            userProfile?.isFBConnected = (responseDics["fb_connected"]?.boolValue)!
            userProfile?.twConnectURL = responseDics["tw_connect_url"]?.stringValue
            userProfile?.isTWConnected = (responseDics["tw_connected"]?.boolValue)!
            // The context is saved at the end of this block, no need to call the `saveContext` method.
        })
    }
    
    func handleserviceError(response: DataResponse<Any>) -> [String: JSON]? {
        guard response.result.isSuccess else {
            ANLoader.hide()
            RMUtility.showAlert(withMessage: (response.result.error?.localizedDescription)!)
            return nil
        }
        
        guard let responseDics = JSON(response.result.value!).dictionary else { return nil }
        guard responseDics["status"]?.stringValue != "error" else {
            ANLoader.hide()
            RMUtility.showAlert(withMessage: (responseDics["error_reason"]?.stringValue)!, title: "Error")
            return nil
        }
        
        return responseDics
    }
    
    func handleFetchMessagesResponse(responseDics: [String: JSON]) {
        Defaults[.APIFetchAfterMsgID] = responseDics["last_fetched_msg_id"]?.int32Value
        
        self.coreDataStack.performBackgroundTask(inContext: { (context, saveBlock) in
            let userProfile = RMUtility.getProfileforConext(context: context)!
            
            for fetchedMessage in (responseDics["msgs"]?.arrayValue)! {
                
                //If message exists with same ID, skip it
                let predicate = NSPredicate(format: "messageID == %ld", fetchedMessage["msg_id"].int64Value)
                if userProfile.messages?.filtered(using: predicate).first as? Message != nil {
                    continue
                }
                
                //New Message
                let message = Message(context: context)
                message.content = fetchedMessage["msg_content"].stringValue
                message.contentType = fetchedMessage["msg_content_type"].stringValue
                message.flow = fetchedMessage["msg_flow"].stringValue
                message.fromPhoneNumber = fetchedMessage["from_phone_num"].stringValue
                message.guide = fetchedMessage["guid"].stringValue
                message.misscallReason = fetchedMessage["misscall_reason"].stringValue
                message.senderName = fetchedMessage["sender_id"].stringValue
                message.sourceAppType = fetchedMessage["source_app_type"].stringValue
                message.subtype = fetchedMessage["msg_subtype"].stringValue
                message.type = fetchedMessage["type"].stringValue
                message.mediaFormat = fetchedMessage["media_format"].stringValue
                message.date = fetchedMessage["msg_dt"].int64Value
                message.fromIVUserID = fetchedMessage["from_iv_user_id"].int64Value
                message.linkedMsgID = fetchedMessage["linked_msg_id"].int64Value
                message.messageID = fetchedMessage["msg_id"].int64Value
                message.readCount = fetchedMessage["msg_read_cnt"].int16Value
                message.downloadCount = fetchedMessage["msg_download_cnt"].int16Value
                message.isBase64 = fetchedMessage["is_msg_base64"].boolValue
                
                for messageContact in fetchedMessage["contact_ids"].arrayValue {
                    if messageContact["contact_id"].stringValue == message.fromPhoneNumber {
                        message.fromUserType = messageContact["type"].stringValue
                    } else {
                        message.receivePhoneNumber = messageContact["contact_id"].stringValue
                    }
                }
                
                userProfile.addToMessages(message)
            }
            if let error = saveBlock(true) {
                print("Coredata merge failed from writer context to default context. \(error.localizedDescription)")
            }
        })
    }
}

// MARK: - JOIN_USER API
extension ServiceRequest {
    
    func startRequestForJoinUser(completionHandler:@escaping (AutheticationType, String?) -> Void) {
        
        var params = JSON(["phone_num": (Constants.appDelegate.userProfile?.userID)!,
                                     "phone_num_edited": true,
                                     "opr_info_edited": true,
                                     "device_id": Constants.DEVICE_UUID,
                                     "sim_country_iso": (Constants.appDelegate.userProfile?.countryISOCode)!,
                                     "sim_opr_mcc_mnc": Constants.appDelegate.userProfile?.simMCCMNCNumber ?? "na", //If not available pass "na" as per API Doc
                                     "cmd": Constants.ApiCommands.JOIN_USER,
                                     "sim_serial_num": ""])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)
        
        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Join User", qos: .background)) { (response) in
                
                guard response.result.isSuccess else {
                    RMUtility.deleteUserProfile()
                    completionHandler(.error, (response.result.error?.localizedDescription)!)
                    return
                }
                
                guard let responseDics = JSON(response.result.value!).dictionary else { return }
                guard responseDics["status"]?.stringValue != "error" else {
                    RMUtility.deleteUserProfile()
                    completionHandler(.error, responseDics["error_reason"]?.stringValue)
                    return
                }
                
                Defaults[.APIIsRMNewUser] = (responseDics[DefaultsKeys.APIIsRMNewUser._key]?.bool)!

                switch responseDics["action"]?.stringValue {
                case "pwd_set":
                    completionHandler(.authTypePassword, nil)
                    
                case "otp_sent":
                    Defaults[.APIRegSecureKey] = responseDics[DefaultsKeys.APIRegSecureKey._key]?.stringValue
                    Defaults[.APIPnsAppIdKey] = responseDics[DefaultsKeys.APIPnsAppIdKey._key]?.stringValue
                    Defaults[.APIDocURLKey] = responseDics[DefaultsKeys.APIDocURLKey._key]?.stringValue
                    
                    completionHandler(.authTypeOTP, nil)
                    
                case "set_primary_pwd":
                    let alert = UIAlertController(style: .alert, title: "Multi Login", message: """
                                                You are already logged into your account on different device
                                                Please set password on your first device
                                                Go to Settings -> Account -> Set Password
                                                """)
                    alert.addAction(title: "OK", handler: { _ in
                        //TODO: Handle Multiple Login
                        completionHandler(.authTypeMultiuser, nil)
                    })
                    alert.show()
                    
                default:
                    break
                }
        }
    }
}

// MARK: - VERIFY_USER API
extension ServiceRequest {
    
    func startRequestForVerifyUser(otpString: String, completionHandler:@escaping (Bool) -> Void) {
        
        var params = JSON([DefaultsKey<Any>.APIRegSecureKey._key: Defaults[.APIRegSecureKey]!,
                                    "pin": otpString,
                                    "cmd": Constants.ApiCommands.VERIFY_USER,
                                    DefaultsKey<Any>.APICloudeSecureKey._key: Defaults[.APICloudeSecureKey] as Any])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Verify User", qos: .background)) { (response) in

                //Handle Error
                guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else { return }

                //Handle response Data
                ServiceRequest.shared.parseCommonResponseforLoginProcess(responseDics: responseDics)

                ServiceRequest.shared.startRequestForGetProfileInfo(completionHandler: { (success) in
                    guard success else { return }
                    ServiceRequest.shared.startRequestForFetchSettings(completionHandler: { (success) in
                        guard success else { return }

                        completionHandler(true)
                    })
                })
        }
    }
}

// MARK: - SIGNIN API
extension ServiceRequest {
    
    func startRequestForSignIn(passWord: String, completionHandler:@escaping (Bool) -> Void) {
        
        var params = JSON(["login_id": (Constants.appDelegate.userProfile?.userID)!,
                                    "pwd": passWord,
                                    "cmd": Constants.ApiCommands.SIGNIN,
                                    "device_id": Constants.DEVICE_UUID,
                                    "sim_country_iso": (Constants.appDelegate.userProfile?.simISOCode)!,
                                    "sim_opr_mcc_mnc": (Constants.appDelegate.userProfile?.simMCCMNCNumber)!])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "SignIn", qos: .background)) { (response) in

                //Handle Error
                guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else { return }

                //Handle response Data
                ServiceRequest.shared.parseCommonResponseforLoginProcess(responseDics: responseDics)

                Defaults[.APIPnsAppIdKey] = responseDics[DefaultsKeys.APIPnsAppIdKey._key]?.stringValue
                Defaults[.APIDocURLKey] = responseDics[DefaultsKeys.APIDocURLKey._key]?.stringValue

                self.coreDataStack.performBackgroundTask(inContext: { (context, saveBlock) in
                    let userProfile = RMUtility.getProfileforConext(context: context)
                    userProfile?.userName = responseDics["screen_name"]?.stringValue
                    userProfile?.password = passWord
                })
                            
                ServiceRequest.shared.startRequestForGetProfileInfo(completionHandler: { (success) in
                    guard success else { return }
                    ServiceRequest.shared.startRequestForFetchSettings(completionHandler: { (success) in
                        guard success else { return }
                        
                        completionHandler(true)
                    })
                })
        }
    }
}

// MARK: - GET_PROFILE_INFO API
extension ServiceRequest {
    
    func startRequestForGetProfileInfo(completionHandler:@escaping (Bool) -> Void) {
            
        var params = JSON(["cmd": Constants.ApiCommands.GET_PROFILE_INFO])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Profile Info", qos: .background)) { (response) in

                //Handle Error
                guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else { return }

                self.coreDataStack.performBackgroundTask(inContext: { (context, saveBlock) in
                    let userProfile = RMUtility.getProfileforConext(context: context)!
                    
                    //Handle response Data
                    userProfile.thumbnailPicURL = responseDics["thumbnail_profile_pic_uri"]?.stringValue
                    userProfile.city = responseDics["city"]?.stringValue
                    userProfile.emailID = responseDics["email"]?.stringValue
                    userProfile.gender = responseDics["gender"]?.stringValue
                    userProfile.profilePicURL = responseDics["profile_pic_path"]?.stringValue
                    userProfile.userName = responseDics["screen_name"]?.stringValue
                    userProfile.state = responseDics["state"]?.stringValue
                    userProfile.twPostEnabled = (responseDics["tw_post_enabled"]?.boolValue)!
                    userProfile.fbPostEnabled = (responseDics["fb_post_enabled"]?.boolValue)!
                    userProfile.inviteSMSText = responseDics["invite_sms_text"]?.stringValue
                    
                    if let dateOfBirth = responseDics["date_of_birth"]?.dictionaryValue {
                        if let year = dateOfBirth["year"]?.intValue, let month = dateOfBirth["month"]?.intValue, let dayOfMonth = dateOfBirth["dayOfMonth"]?.intValue {
                            if let date = RMUtility.getDateFromYearMonthDay(year: year, month: month+1, day: dayOfMonth) {
                                userProfile.birthday = date
                            }
                        }
                    }
                    
                    //greeting_name
                    if let greetingNameJsonString = responseDics["greeting_name"]?.stringValue, !greetingNameJsonString.isEmpty {
                        let greetingNameDic = JSON(parseJSON: greetingNameJsonString)
                        userProfile.greetingNameUri = greetingNameDic["uri"].stringValue
                        userProfile.greetingNameDuration = greetingNameDic["duration"].int32Value
                    }
                    
                    //greeting_welcome
                    if let greetinWelcomeJsonString = responseDics["greeting_welcome"]?.stringValue, !greetinWelcomeJsonString.isEmpty {
                        let greetingWelcomeDic = JSON(parseJSON: greetinWelcomeJsonString)
                        userProfile.greetingWelcomeUri = greetingWelcomeDic["uri"].stringValue
                        userProfile.greetingWelcomeDuration = greetingWelcomeDic["duration"].int32Value
                    }
                    
                    //Email Notifications voicemail email time_zone vsms_enabled mc_enabled
                    if let emailNotificationsString = responseDics["voicemail"]?.stringValue, !emailNotificationsString.isEmpty {
                        let emailNotificationDic = JSON(parseJSON: emailNotificationsString)
                        userProfile.vEmail = emailNotificationDic["email"].stringValue
                        userProfile.timeZone = emailNotificationDic["time_zone"].stringValue
                        userProfile.vsmsEnabled = emailNotificationDic["vsms_enabled"].boolValue
                        userProfile.mcEnabled = emailNotificationDic["mc_enabled"].boolValue
                    }

                    //Custom Settings
                    var phoneDetailsDic: [String: JSON]?
                    if let customSettingsJsonString = responseDics["custom_settings"]?.stringValue, !customSettingsJsonString.isEmpty {
                        
                        let customSettings = JSON(parseJSON: customSettingsJsonString)
                        
                        for customSetting in customSettings.arrayValue {
                            if customSetting["recording_time"].exists() {
                                userProfile.recordingTime = customSetting["recording_time"].stringValue
                            } else if customSetting["storage_location"].exists() {
                                userProfile.storageLocation = customSetting["storage_location"].stringValue
                            } else if customSetting["default_record_mode"].exists() {
                                userProfile.recordMode = customSetting["default_record_mode"].stringValue
                            } else if customSetting["ph_dtls"].exists() {
                                phoneDetailsDic = JSON(parseJSON: customSetting["ph_dtls"].stringValue).dictionaryValue
                            }
                        }
                    }

                    //Update UserContacts
                    for userContact in (responseDics["user_contacts"]?.arrayValue)! {
                        //Check for existing Contact, if not present, then create new one
                        var updatedUserContact: UserContact
                        let predicate = NSPredicate(format: "contactID == %@", userContact["contact_id"].stringValue)
                        if let foundUserContact = userProfile.userContacts?.filtered(using: predicate).first as? UserContact {
                            updatedUserContact = foundUserContact
                        } else {
                            updatedUserContact = UserContact(context: context)
                            userProfile.addToUserContacts(updatedUserContact)
                        }
                        
                        updatedUserContact.contactType = userContact["contact_type"].stringValue
                        updatedUserContact.contactID = userContact["contact_id"].stringValue
                        updatedUserContact.countryCode = userContact["country_code"].stringValue
                        updatedUserContact.isPrimary = userContact["is_primary"].boolValue
                        updatedUserContact.bloggerID = userContact["blogger_id"].int64Value
                        
                        //Phone Details
                        if let phoneDetail = phoneDetailsDic?[updatedUserContact.contactID!]?.dictionaryValue {
                            updatedUserContact.titleName = phoneDetail["title_nm"]?.stringValue
                            updatedUserContact.imageName = phoneDetail["img_nm"]?.stringValue
                        }
                        
                        //Format Number
                        if updatedUserContact.countryImageData == nil {
                            do {
                                let number = try PhoneNumberKit().parse(updatedUserContact.contactID!)
                                let formatedNumber = PhoneNumberKit().format(number, toType: .international)
                                updatedUserContact.formatedNumber = formatedNumber
                                
                                if let regionCode = PhoneNumberKit().getRegionCode(of: number) {
                                    DispatchQueue.main.sync(execute: {
                                        let country =  (CountryPickerView()).countries.filter({ $0.code == regionCode })
                                        updatedUserContact.countryName = country.first?.name
                                        updatedUserContact.countryImageData = country.first?.countryImageData!
                                    })
                                }
                            } catch { print("PhonenumberKit parser error") }
                        }
                        
                        //If this is primary number request for carrier list
                        if updatedUserContact.isPrimary {
                            userProfile.primaryContact = updatedUserContact
                        }
                        
                        if let error = saveBlock(true) {
                            print("Coredata save error. \(error.localizedDescription)")
                        }
                    }
                }, andInMainThread: {
                    if Constants.appDelegate.userProfile?.primaryContact?.carriers == nil || Constants.appDelegate.userProfile?.primaryContact?.carriers?.count == 0 {
                        ServiceRequest.shared.startRequestForListOfCarriers(forUserContact: (Constants.appDelegate.userProfile?.primaryContact!)!, completionHandler: { (success) in
                            guard success else { return }
                        })
                    }
                    completionHandler(true)
                })
                            
        }
    }
}

// MARK: - LIST_CARRIERS API
extension ServiceRequest {
    
    func startRequestForListOfCarriers(forUserContact contact: UserContact, completionHandler:@escaping (Bool) -> Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.LIST_CARRIERS,
                                     "country_code": contact.countryCode!,
                                     "fetch_voicemails_info": true])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Carrier List", qos: .background)) { (response) in

                //Handle Error
                guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else { return }

                self.coreDataStack.performBackgroundTask(inContext: { (context, saveBlock) in
                    let userProfile = RMUtility.getProfileforConext(context: context)!
                    
                    //Handle Resonse
                    let predicate = NSPredicate(format: "contactID contains[c] %@", contact.contactID!)
                    //Filter exact userContact from profile for which carrierList to be update
                    let userContact = userProfile.userContacts?.filtered(using: predicate).first as! UserContact
                    
                    //Update New Carriers
                    for remoteCarrier in (responseDics["country_list"]?.arrayValue)! {
                        
                        let updatedCarrier = Carrier(context: context)
                        updatedCarrier.carrierName = remoteCarrier["carrier_name"].stringValue
                        updatedCarrier.vsmsNodeID = remoteCarrier["vsms_node_id"].int16Value
                        updatedCarrier.countryCode = remoteCarrier["country_code"].stringValue
                        updatedCarrier.networkID = remoteCarrier["network_id"].stringValue
                        updatedCarrier.networkName = remoteCarrier["network_name"].stringValue
                        updatedCarrier.ussdString = remoteCarrier["ussd_string"].stringValue
                        
                        if remoteCarrier["ussd_string"].exists() {
                            let ussdValues = JSON(parseJSON: remoteCarrier["ussd_string"].stringValue)
                            updatedCarrier.reachMeIntl = ussdValues["rm_intl"].boolValue
                            updatedCarrier.reachMeHome = ussdValues["rm_home"].boolValue
                            updatedCarrier.reachMeVoiceMail = ussdValues["rm_vm"].boolValue
                            updatedCarrier.actiUNCF = ussdValues["acti_uncf"].stringValue
                            updatedCarrier.deactiUNCF = ussdValues["deacti_uncf"].stringValue
                            updatedCarrier.actiAll = ussdValues["acti_all"].stringValue
                            updatedCarrier.deactiBoth = ussdValues["deacti_both"].stringValue
                            updatedCarrier.actiCNF = ussdValues["acti_cnf"].stringValue
                            updatedCarrier.deactiCNF = ussdValues["acti_uncf"].stringValue
                            updatedCarrier.additionalActiInfo = ussdValues["add_acti_info"].stringValue
                            updatedCarrier.isHLREnabled = ussdValues["is_hlr_callfwd_enabled"].boolValue
                            updatedCarrier.isVOIPEnabled = ussdValues["voip_enabled"].boolValue
                            
                            if updatedCarrier.reachMeIntl || updatedCarrier.reachMeHome || updatedCarrier.reachMeVoiceMail {
                                updatedCarrier.isReachMeSupport = true
                            }
                            if !updatedCarrier.reachMeIntl && !updatedCarrier.reachMeHome && !updatedCarrier.reachMeVoiceMail {
                                updatedCarrier.networkName = "Not supported"
                            }
                        }
                        
                        for (key, value) in remoteCarrier["carrier_info"].dictionaryValue {
                            switch key {
                            case "logo_home_url":
                                updatedCarrier.logoHomeURL = value.stringValue
                            case "logo_support_url":
                                updatedCarrier.logoSupportURL = value.stringValue
                            case "logo_theme_color":
                                updatedCarrier.logoThemeColor = value.stringValue
                            case "logo":
                                updatedCarrier.logoURL = value.stringValue
                            case "in_app_promo":
                                value.arrayValue.forEach({ (inAppPromoDisc) in
                                    // inAppPromoDisc["show_image"] as! Bool
                                    updatedCarrier.inAppPromoImageURL = inAppPromoDisc["image_url"].stringValue
                                })
                                
                            default:
                                break
                            }
                        }
                        
                        userContact.addToCarriers(updatedCarrier)
                    }
                }, andInMainThread: {
                    completionHandler(true)
                })
        }
    }
}

// MARK: - FETCH_SETTINGS API
extension ServiceRequest {
    
    func startRequestForFetchSettings(completionHandler:@escaping (Bool) -> Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.FETCH_SETTINGS,
                                     "fetch_voicemails_info": true])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Fetch Settings", qos: .background)) { (response) in

                //Handle Error
                guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else { return }

                //Handle response Data
                self.coreDataStack.deleteAllRecordsForEntity(entity: Constants.EntityName.SUPPORT_CONTACT)
                self.coreDataStack.performBackgroundTask(inContext: { (context, saveBlock) in
                    let userProfile = RMUtility.getProfileforConext(context: context)!
                    
                    let supportContactJsonString = responseDics["iv_support_contact_ids"]?.stringValue
                    let contactIDs = JSON(parseJSON: supportContactJsonString!)
                    for (index, contactID) in contactIDs.arrayValue.enumerated() {
                        
                        let supportContact = SupportContact(context: context)
                        supportContact.userID = contactID["iv_user_id"].stringValue
                        supportContact.phone = contactID["phone"].stringValue
                        supportContact.profilePicURL = contactID["profile_pic_uri"].stringValue
                        supportContact.thumbnailPicURL = contactID["thumbnail_profile_pic_uri"].stringValue
                        supportContact.isShowIVUser = contactID["show_as_iv_user"].boolValue
                        
                        switch index {
                        case 0:
                            supportContact.supportType = contactID["support_catg"].stringValue
                            supportContact.supportID = contactID["support_catg_id"].stringValue
                            supportContact.isSendEmail = contactID["support_send_email"].boolValue
                            supportContact.isSendIV = contactID["support_send_iv"].boolValue
                            supportContact.isSendSMS = contactID["support_send_sms"].boolValue
                        case 1:
                            supportContact.supportType = contactID["feedback_catg"].stringValue
                            supportContact.supportID = contactID["feedback_catg_id"].stringValue
                            supportContact.isSendEmail = contactID["feedback_send_email"].boolValue
                            supportContact.isSendIV = contactID["feedback_send_iv"].boolValue
                            supportContact.isSendSMS = contactID["feedback_send_sms"].boolValue
                        default:
                            break
                        }
                        
                        userProfile.addToSupportContacts(supportContact)
                    }
                    
                    //Custom Settings
                    let customSettingsJsonString = responseDics["custom_settings"]?.stringValue
                    let customSettings = JSON(parseJSON: customSettingsJsonString!)
                    for customSetting in customSettings.arrayValue {
                        
                        let carrier = JSON(parseJSON: customSetting["carrier"].stringValue)
                        
                        (userProfile.userContacts?.allObjects as? [UserContact])?.forEach({ userContact in
                            
                            if carrier[userContact.contactID!].exists() {
                                let carrierInfo = carrier[userContact.contactID!].dictionaryValue
                                if let international = carrierInfo["rm_intl_acti"]?.boolValue {
                                    userContact.isReachMeIntlActive = international
                                }
                                if let home = carrierInfo["rm_home_acti"]?.boolValue {
                                    userContact.isReachMeHomeActive = home
                                }
                                if let voiceMail = carrierInfo["vm_acti"]?.boolValue {
                                    userContact.isReachMeVoiceMailActive = voiceMail
                                }
                                
                                //Search carrier from carrier list with math of carrier info
                                if let carrierFound = (userProfile.primaryContact?.carriers?.allObjects as? [Carrier])?.filter({
                                    if let vsmsID = carrierInfo["vsms_id"]?.int16Value {
                                        if $0.networkID == carrierInfo["network_id"]?.stringValue &&
                                            $0.countryCode == carrierInfo["country_cd"]?.stringValue &&
                                            $0.vsmsNodeID == vsmsID {
                                            return true
                                        }
                                    }
                                    return false
                                }), carrierFound.count > 0 {
                                    userContact.selectedCarrier = carrierFound.first
                                } else {
                                    if userContact.selectedCarrier == nil {
                                        userContact.selectedCarrier = Carrier(context: context)
                                    }
                                    if let vsms = carrierInfo["vsms_id"]?.int16Value {
                                        userContact.selectedCarrier?.vsmsNodeID = vsms
                                    }
                                    userContact.selectedCarrier?.countryCode = carrierInfo["country_cd"]?.stringValue
                                    userContact.selectedCarrier?.networkID = carrierInfo["network_id"]?.stringValue
                                    userContact.selectedCarrier?.networkName = "Select Your Carrier"
                                }
                            }
                        })
                    }

                    //Voicemail Info
                    if let voiceMailInfo = responseDics["voicemails_info"]?.arrayValue {
                        for voiceMail in voiceMailInfo {
                            let predicate = NSPredicate(format: "contactID contains[c] %@", voiceMail["phone"].stringValue)
                            let userContact = userProfile.userContacts?.filtered(using: predicate).first as! UserContact
                            
                            if userContact.voiceMailInfo == nil {
                                userContact.voiceMailInfo = VoiceMail(context: context)
                            }
                            
                            userContact.voiceMailInfo?.phoneNumber = voiceMail["phone"].stringValue
                            userContact.voiceMailInfo?.carrierCountryCode = voiceMail["carrier_country_code"].stringValue
                            userContact.voiceMailInfo?.kvSMSKey = voiceMail["kvsms_key"].stringValue
                            userContact.voiceMailInfo?.networkId = voiceMail["network_id"].stringValue
                            userContact.voiceMailInfo?.countryVoicemailSupport = voiceMail["country_voicemail_support"].boolValue
                            if voiceMail["enabled"].exists() {
                                userContact.voiceMailInfo?.isVoiceMailEnabled = Bool(truncating: voiceMail["enabled"].int16Value as NSNumber)
                            }
                            userContact.voiceMailInfo?.availableVocieMailCount = voiceMail["avs_cnt"].int16Value
                            userContact.voiceMailInfo?.missedCallCount = voiceMail["mca_cnt"].int16Value
                            userContact.voiceMailInfo?.realVocieMailCount = voiceMail["real_avs_cnt"].int16Value
                            userContact.voiceMailInfo?.realMissedCallCount = voiceMail["real_mca_cnt"].int16Value
                            userContact.voiceMailInfo?.latestMessageCount = voiceMail["new_msg_cnt"].int16Value
                            userContact.voiceMailInfo?.oldMessageCount = voiceMail["old_msg_cnt"].int16Value
                            userContact.voiceMailInfo?.lastVoiceMailCountTimeStamp = voiceMail["avs_timestamp"].int64Value
                            userContact.voiceMailInfo?.lastMissedCallTimeStamp = voiceMail["mca_timestamp"].int64Value
                            userContact.voiceMailInfo?.vSMSNodeId = voiceMail["vsms_node_id"].int16Value
                            
                            if voiceMail["ussd_string"].exists() {
                                let ussdValues = JSON(parseJSON: voiceMail["ussd_string"].stringValue)
                                userContact.voiceMailInfo?.actiUNCF = ussdValues["acti_uncf"].stringValue
                                userContact.voiceMailInfo?.deactiUNCF = ussdValues["deacti_uncf"].stringValue
                                userContact.voiceMailInfo?.actiAll = ussdValues["acti_all"].stringValue
                                userContact.voiceMailInfo?.deactiBoth = ussdValues["deacti_both"].stringValue
                                userContact.voiceMailInfo?.actiCNF = ussdValues["acti_cnf"].stringValue
                                userContact.voiceMailInfo?.deactiCNF = ussdValues["acti_uncf"].stringValue
                                userContact.voiceMailInfo?.additionalActiInfo = ussdValues["add_acti_info"].stringValue
                                userContact.voiceMailInfo?.isHLREnabled = ussdValues["is_hlr_callfwd_enabled"].boolValue
                                userContact.voiceMailInfo?.isVOIPEnabled = ussdValues["voip_enabled"].boolValue
                                userContact.voiceMailInfo?.rmHome = ussdValues["rm_home"].boolValue
                                userContact.voiceMailInfo?.rmIntl = ussdValues["rm_intl"].boolValue
                                userContact.voiceMailInfo?.rmVM = ussdValues["rm_vm"].boolValue
                            }
                            
                            if !(userContact.voiceMailInfo?.countryVoicemailSupport)! {
                                userContact.selectedCarrier?.networkName = "Not supported"
                            }
                        }
                    }
                    
                    //MQTTSettings
                    if userProfile.mqttSettings == nil {
                        userProfile.mqttSettings = MQTT(context: context)
                    }
                    userProfile.mqttSettings?.chatTopic = responseDics["chat_topic"]?.stringValue
                    userProfile.mqttSettings?.chatUser = responseDics["chat_user"]?.stringValue
                    userProfile.mqttSettings?.chatPassword = responseDics["chat_password"]?.stringValue
                    userProfile.mqttSettings?.chatHostname = responseDics["chat_hostname"]?.stringValue
                    userProfile.mqttSettings?.chatPortSSL = responseDics["chat_port_ssl"]?.stringValue
                    userProfile.mqttSettings?.mqttHostname = responseDics["mqtt_hostname"]?.stringValue
                    userProfile.mqttSettings?.mqttPassword = responseDics["mqtt_password"]?.stringValue
                    userProfile.mqttSettings?.mqttUser = responseDics["mqtt_user"]?.stringValue
                    userProfile.mqttSettings?.mqttPortSSL = responseDics["mqtt_port_ssl"]?.stringValue
                    userProfile.mqttSettings?.mqttDeviceID = (responseDics["iv_user_device_id"]?.int32Value)!
                    
                    //VOIP Info
                    if let voipInfo = responseDics["voip_info"]?.dictionaryValue {
                        if userProfile.voipSettings == nil {
                            userProfile.voipSettings = VOIP(context: context)
                        }
                        userProfile.voipSettings?.login = voipInfo["login"]?.stringValue
                        userProfile.voipSettings?.password = voipInfo["pwd"]?.stringValue
                        userProfile.voipSettings?.ipAddress = voipInfo["ip"]?.stringValue
                        if let port = voipInfo["port"]?.int16Value {
                            userProfile.voipSettings?.port = port
                        }
                    }
                    
                }, andInMainThread: {
                    completionHandler(true)
                })
        }
    }
}

// MARK: - GENERATE_VERIFICATION_CODE API
extension ServiceRequest {
    
    func startRequestForGenerateVerificationCode(completionHandler:@escaping (Bool) -> Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.GENERATE_VERIFICATION_CODE,
                                     "sim_opr_mcc_mnc": (Constants.appDelegate.userProfile?.simMCCMNCNumber)!,
                                     "reg_secure_key": Defaults[.APIRegSecureKey] as Any,
                                     "send_pin_by": "obd"])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON { (response) in

                            if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                return
                            }

                //Handle response Data
                completionHandler(true)
        }
    }
}

// MARK: - UPDATE_SETTINGS API
extension ServiceRequest {
    
    func startRequestForUpdateSettings(completionHandler:@escaping (Bool) -> Void) {
        
            var carrierDetailsDict = [String: Any]()
            var phoneDetailsDict = [String: Any]()
            (Constants.appDelegate.userProfile?.userContacts?.allObjects as? [UserContact])?.forEach({ userContact in
                let carrierDetails: [String: Any] = ["country_cd": userContact.selectedCarrier?.countryCode as Any,
                                                     "network_id": userContact.selectedCarrier?.networkID as Any,
                                                     "vsms_id": userContact.selectedCarrier?.vsmsNodeID as Any,
                                                     "rm_intl_acti": userContact.isReachMeIntlActive as Any,
                                                     "rm_home_acti": userContact.isReachMeHomeActive as Any,
                                                     "vm_acti": userContact.isReachMeVoiceMailActive as Any]
                carrierDetailsDict[userContact.contactID!] = carrierDetails

                let phoneDetails: [String: Any] = ["img_nm": userContact.imageName as Any,
                                                   "title_nm": userContact.titleName as Any]
                phoneDetailsDict[userContact.contactID!] = phoneDetails
            })

            let carrierDetailsJsonData = try! JSONSerialization.data(withJSONObject: carrierDetailsDict, options: [])
            let carrierDetailsJsonString = String(data: carrierDetailsJsonData, encoding: .utf8)!

            let phoneDetailsJsonData = try! JSONSerialization.data(withJSONObject: phoneDetailsDict, options: [])
            let phoneDetailsJsonString = String(data: phoneDetailsJsonData, encoding: .utf8)!

            let updatedSettingsInfo: [[String: Any]] =
                [["storage_location": Constants.appDelegate.userProfile?.storageLocation as Any],
                 ["default_record_mode": Constants.appDelegate.userProfile?.recordMode as Any],
                 ["recording_time": Constants.appDelegate.userProfile?.recordingTime as Any],
                 ["carrier": carrierDetailsJsonString],
                 ["ph_dtls": phoneDetailsJsonString]]
            var params = JSON(["cmd": Constants.ApiCommands.UPDATE_SETTINGS,
                                         "custom_settings": updatedSettingsInfo,
                                         "fb_post_enabled": (Constants.appDelegate.userProfile?.fbPostEnabled)!,
                                         "tw_post_enabled": (Constants.appDelegate.userProfile?.twPostEnabled)!])
            params = RMUtility.serverRequestAddCommonData(params: params)
            let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

            Alamofire.request(Constants.URL_SERVER,
                              method: .post,
                              encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Update Settings", qos: .background)) { (response) in

                                if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                    completionHandler(false)
                                    return
                                }

                                //No Response Data coming for local update
                                completionHandler(true)

            }
        }
}

// MARK: - GENERATE_PASSWORD API
extension ServiceRequest {
    
    func startRequestForGeneratePassword(completionHandler:@escaping (Bool) -> Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.GENERATE_PASSWORD,
                                     "login_id": (Constants.appDelegate.userProfile?.userID)!])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Genearate Password", qos: .background)) { (response) in

                            if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                completionHandler(false)
                                return
                            }

                //No Response Data coming for local update
                completionHandler(true)
        }
    }
}

// MARK: - VERIFY_PASSWORD API
extension ServiceRequest {
    
    func startRequestForVerifyPassword(otpString: String, completionHandler:@escaping (Bool) -> Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.VERIFY_PASSWORD,
                                     "pwd": otpString,
                                     "login_id": (Constants.appDelegate.userProfile?.userID)!,
                                     "device_id": Constants.DEVICE_UUID])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Verify Password", qos: .background)) { (response) in
                //Handle Error
                guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else {
                    completionHandler(false)
                    return
                }

                //Handle response Data
                ServiceRequest.shared.parseCommonResponseforLoginProcess(responseDics: responseDics)

                completionHandler(true)
        }
    }
}

// MARK: - UPDATE_PROFILE_INFO API
extension ServiceRequest {
    
    func startRequestForUpdateProfileInfo(withProfileInfo profileInfo: JSON, completionHandler:@escaping (Bool) -> Void) {
        
        let params = RMUtility.serverRequestAddCommonData(params: profileInfo)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Update Profile Info", qos: .background)) { (response) in

                            if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                completionHandler(false)
                                return
                            }

                //No Response Data coming for local update
                completionHandler(true)
        }
    }
}

// MARK: - MANAGE_USER_CONTACT API
extension ServiceRequest {
    
    func startRequestForManageUserContact(withManagedInfo managedInfo: JSON, completionHandler:@escaping ([String: Any]?, Bool) -> Void) {
        
        let params = RMUtility.serverRequestAddCommonData(params: managedInfo)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Manage User Contact", qos: .background)) { (response) in

                //Handle Error
                guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else { return }

                //Handle response Data
                completionHandler(responseDics, true)
        }
    }
}

// MARK: - VOICEMAIL_SETTING API
extension ServiceRequest {
    
    func startRequestForVoicemailSetting(withVoicemailInfo voicemailInfo: JSON, completionHandler:@escaping (Bool) -> Void) {
        
        let params = RMUtility.serverRequestAddCommonData(params: voicemailInfo)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Fetch Voicemail Settings", qos: .background)) { (response) in

                response.result.isSuccess ? completionHandler(true) : completionHandler(false)
        }
    }
}

// MARK: - Download Profile Pic
extension ServiceRequest {
    
    func startRequestForDownloadProfilePic(completionHandler:@escaping (Data) -> Void) {
        
        _ =  Alamofire.request((Constants.appDelegate.userProfile?.profilePicURL)!)
            .validate { request, response, imageData in
                self.coreDataStack.performBackgroundTask(inContext: { (context, saveBlock) in
                    let userProfile = RMUtility.getProfileforConext(context: context)!
                    userProfile.profilePicData = imageData
                })
                completionHandler(imageData!)
                return .success
        }
    }
}

// MARK: - Download ImaGE
extension ServiceRequest {
    
    func startRequestForDownloadImage(forURL downloadURL: String, completionHandler:@escaping (Data) -> Void) {
        
        _ =  Alamofire.request(downloadURL)
            .validate { request, response, imageData in
                completionHandler(imageData!)
                return .success
        }
    }
}

// MARK: - USAGE_SUMMARY API
extension ServiceRequest {
    
    func startRequestForUsageSummary(forPhoneNumber number: String, completionHandler:@escaping ([String: Any]?, Bool) -> Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.USAGE_SUMMARY,
                                     "phone": number])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON { (response) in

                //Handle Error
                guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else {
                    completionHandler(nil, false)
                    return
                }

                //Handle response Data
                completionHandler(responseDics, true)
        }
    }
}

// MARK: - SIGNOUT API
extension ServiceRequest {
    
    func startRequestForSignOut(completionHandler:@escaping (Bool) -> Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.SIGN_OUT])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)
        
        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON { (response) in
                
                            if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                completionHandler(false)
                                return
                            }
                
                //Handle response Data
                completionHandler(true)
        }
    }
}

// MARK: - SET_DEVICEINFO API
extension ServiceRequest {
    
    func startRequestForSetDeviceInfo(deviceToken: String?, voipToken: String?, completionHandler: (() -> Swift.Void)? = nil) {
        
        var params = JSON(["cmd": Constants.ApiCommands.SET_DEVICEINFO])
        if let dvToken = deviceToken {
            params["cloud_secure_key"].string = dvToken
        }
        if let vpToken = voipToken {
            params["voip_cloud_secure_key"].string = vpToken
        }
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)
        
        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Set Device Info", qos: .background)) { (response) in
                
                            if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                return
                            }
                
                            if let dvToken = deviceToken {
                                Defaults[.APICloudeSecureKey] = dvToken
                            }
                            if let vpToken = voipToken {
                                Defaults[.APIVoipSecureKey] = vpToken
                            }

                completionHandler?()
        }
    }
}

// MARK: - FETCH_MESSAGES API
extension ServiceRequest {
    func startRequestForFetchMessages(completionHandler: ((Bool) -> Swift.Void)?) {
        
            let afterMsgID = (Defaults[.APIFetchAfterMsgID] == nil) ? 0 : Defaults[.APIFetchAfterMsgID] as! Int64
            var params = JSON(["cmd": Constants.ApiCommands.FETCH_MESSAGES,
                                         DefaultsKey<Any>.APIFetchAfterMsgID._key: afterMsgID,
                                         "fetch_max_rows": 1000,
                                         "fetch_opponent_contactids": true])
            params = RMUtility.serverRequestAddCommonData(params: params)
            let payload = RMUtility.serverRequestConstructPayloadFor(params: params)
            
            Alamofire.request(Constants.URL_SERVER,
                              method: .post,
                              encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Fetch Message", qos: .background)) { (response) in
                                
                                guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else {
                                    completionHandler?(false)
                                    return
                                }
                                
                                ServiceRequest.shared.handleFetchMessagesResponse(responseDics: responseDics)
                                
                                completionHandler?(true)
            }
        }
}

// MARK: - DELETE_MESSAGE API
extension ServiceRequest {
    func startRequestForDeleteMessage(message: Message, completionHandler: ((Bool) -> Swift.Void)?) {
        
        var params = JSON(["cmd": Constants.ApiCommands.DELETE_MESSAGE,
                                     "msg_id": message.messageID,
                                     "type": message.type!])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)
        
        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Delete Message", qos: .background)) { (response) in
                
                            if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                DispatchQueue.main.async { completionHandler?(false) }
                                return
                            }
                            
                completionHandler?(true)
        }
    }
}

// MARK: - READ_MESSAGE API
extension ServiceRequest {
    func startRequestForReadMessages(messages: [Message], completionHandler: ((Bool) -> Swift.Void)?) {
        
        var params = JSON(["cmd": Constants.ApiCommands.READ_MESSAGES,
                                     "msg_ids": messages.map {$0.messageID},
                                     "msg_ids_type": (messages.first?.fromUserType)!])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Read Message", qos: .background)) { (response) in

                            if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                completionHandler?(false)
                                return
                            }

                completionHandler?(true)
        }
    }
}

// MARK: - STATES_LIST API
extension ServiceRequest {
    
    func startRequestForStatesList(forCountryCode countryCode: String, completionHandler:@escaping ([String: Any]?, Bool) -> Swift.Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.STATE_LIST,
                                     "country_code": countryCode])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)

        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "States List", qos: .background)) { (response) in

                            //Handle Error
                            guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else {
                                completionHandler(nil, false)
                                return
                            }

                            //Handle response Data
                            completionHandler(responseDics, true)
        }
    }
}

// MARK: - UPLOAD_PIC API
extension ServiceRequest {
    
    func startRequestForUploadProfilePic(picData: Data, completionHandler:@escaping (Bool) -> Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.UPLOAD_PIC,
                                     "file_name": (Constants.appDelegate.userProfile?.userID)!,
                                     "file_type": "png"])
        params = RMUtility.serverRequestAddCommonData(params: params)
        //let requestJSON = RMUtility.convertDictionaryToJSONString(dictionary: params)
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(picData,
                                     withName: (Constants.appDelegate.userProfile?.userID)!,
                                     fileName: (Constants.appDelegate.userProfile?.userID)!,
                                     mimeType: "")
        }, usingThreshold: UInt64.init(),
          to: Constants.URL_SERVER,
          method: .post,
          headers: ["data": params.rawString()!],
          encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    if response.result.isSuccess {
                        completionHandler(true)
                    } else {
                        completionHandler(false)
                    }
                    //debugPrint(response)
                }
            case .failure(let encodingError):
                print(encodingError)
                completionHandler(false)
            }
        })
    }
}

// MARK: - ENQUIRE_IV_USERS API
extension ServiceRequest {
    
    func startRequestForEnquireIVUsers(contactList: [String], completionHandler:@escaping ([String: Any]?, Bool) -> Swift.Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.ENQUIRE_IV_USERS,
                                     "contact_ids": contactList,
                                     "fetch_pic_uri_type": 1])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)
        
        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Enquire IV Users", qos: .background)) { (response) in
                            
                            //Handle Error
                            guard let responseDics = ServiceRequest.shared.handleserviceError(response: response) else {
                                completionHandler(nil, false)
                                return
                            }

                            completionHandler(responseDics, true)
        }
    }
}

// MARK: - FRIEND INVITE API
extension ServiceRequest {
    
    func startRequestForInviteFriend(inviteList: [[String: String]], completionHandler:@escaping (Bool) -> Swift.Void) {
        
        var params = JSON(["cmd": Constants.ApiCommands.SEND_TEXT,
                                     "contact_ids": inviteList,
                                     "msg_type": "t",
                                     "type": "inv",
                                     "fetch_msgs": false,
                                     "msg_text": "Hello",
                                     "guid": "\(UUID().uuidString)-\(Constants.DEVICE_UUID)"])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)
        
        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON { (response) in
                            
                            //Handle Error
                            if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                completionHandler(false)
                                return
                            }
                            
                            completionHandler(true)
        }
    }
}
// MARK: - FETCH_USER_CONTACTS API
extension ServiceRequest { //NOTE: As i observs, all the response parameters of this API are present in "Get Proafile Info" API, since we are saving profile info response so this is no need
    
    func startRequestForFetchUserContacts() {
        
        var params = JSON(["cmd": Constants.ApiCommands.FETCH_USER_CONTACTS,
                                    "IV_USER_ID": Defaults[.APIIVUserIDKey],
                                    "device_id": Constants.DEVICE_UUID,
                                    "user_secure_key": Defaults[.APIUserSecureKey] as Any])
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)
        
        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON { (response) in
                
                            if ServiceRequest.shared.handleserviceError(response: response) == nil {
                                return
                            }

        }
    }
}

open class ServiceRequestBackground: NSObject {
    override init() { }
    
    func startRequestForFetchMessages(completionHandler:@escaping (Bool) -> Void) {
        
        let afterMsgID = (Defaults[.APIFetchAfterMsgID] == nil) ? 0 : Defaults[.APIFetchAfterMsgID] as! Int64
        var params = JSON(["cmd": Constants.ApiCommands.FETCH_MESSAGES,
                                     DefaultsKey<Any>.APIFetchAfterMsgID._key: afterMsgID,
                                     "status": "bg",
                                     "fetch_max_rows": 500])  //Check latter for param "fetch_opponent_contactids"
        params = RMUtility.serverRequestAddCommonData(params: params)
        let payload = RMUtility.serverRequestConstructPayloadFor(params: params)
        
        Alamofire.request(Constants.URL_SERVER,
                          method: .post,
                          encoding: payload).validate().responseJSON(queue: DispatchQueue(label: "Fetch Message Background", qos: .background)) { (response) in
                
                guard response.result.isSuccess else {completionHandler(false); return }
                
                guard let responseDics = JSON(response.result.value!).dictionary else {completionHandler(false); return }
                guard responseDics["status"]?.stringValue != "error" else {completionHandler(false); return }
                
                ServiceRequest.shared.handleFetchMessagesResponse(responseDics: responseDics)
                completionHandler(true)
        }
    }
}

// MARK: - MQTTSessionDelegate
extension ServiceRequest: MQTTSessionDelegate {
    
    public func mqttDidReceive(message data: Data, in topic: String, from session: MQTTSession) {
        ServiceRequest.shared.startRequestForFetchMessages(completionHandler: nil)
        
        //Parse Data to show Local Notification
        var result: [String: Any]!
        do {
            result = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String: Any]
        } catch { print("Error in JSON Parsing of MQTT Received Data") }
        
        var subtitle: String!
        if let apnsInfo = result["aps"] as? [String: Any] {
            subtitle = (apnsInfo["alert"] as! [String: Any])["body"] as! String
            
        } else if let message = (result["msgs"] as? [[String: Any]])?.first, (message["msg_flow"] as! String) == "r" {
            
            let senderName = (message["sender_id"] as? String) != nil ? (message["sender_id"] as! String) : message["from_phone_num"] as! String
            if let contentType = message["msg_content_type"] as? String {
                if contentType == "t" {
                    if let messageType = message["type"] as? String, messageType == "mc" {
                        if let messageSubType = message["msg_subtype"] as? String, messageSubType == "ring" {
                            subtitle = "\(senderName): Ring Missed Call"
                        } else {
                            subtitle = "\(senderName): Missed Call"
                        }
                    } else {
                        subtitle = "\(senderName): \(message["msg_content"] as! String)"
                    }
                } else if contentType == "a" {
                    subtitle = "\(senderName): Voice Message"
                } else if contentType == "i" {
                    subtitle = "\(senderName): Image"
                }
            }
        }
        
        if subtitle != nil {
            let content = UNMutableNotificationContent()
            content.title = "ReachMe"
            // content.subtitle = subtitle
            content.body = subtitle
            content.sound = UNNotificationSound(named: "InstavoiceNotificationTone")
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest(identifier: "MQTTLocalNotificationIdentifier", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
        
    }
    
    public func mqttDidDisconnect(session: MQTTSession) {
        
    }
    
    public func mqttSocketErrorOccurred(session: MQTTSession) {
        print("MQTT Socket Error Occurred")
    }
    
}
