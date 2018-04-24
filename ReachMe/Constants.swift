//
//  Constants.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/17/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class Constants: NSObject {
    @objc static let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate

    //Segue ID's
    struct Segues {
        static let LOGIN = "showLoginSegueID"
        static let PASSWORD = "showPasswordSegueID"
        static let OTP = "showOTPSegueID"
        static let CARRIERLIST = "showCarrierListSeugeID"
        static let ACTIVATE_REACHME = "showActivateReachMeSegueID"
        static let RESET_PASSWORD = "showRestetPasswordSegueID"
        static let HOWTO_ACTIVAE_REACHME = "showHowToActivateReachMeSegueID"
        static let ACTIVATION_REACHME = "showActivationReachMeSegueID"
        static let ACTIVATION_AGAIN = "showActivationAgainSegueID"
        static let ACTIVATION_SWITCHTO = "switchToActivationSegueID"
        static let ACTIVATION_DEACTIVATE = "showDeactivationSegueID"
        static let ACTIVATED = "showActivatedReachMeSegueID"
        static let EDIT_DETAILS = "showEditDetailsSegueID"
        static let FREQUENTLY_ASKED = "showFrequentlyAskedSegueID"
        static let TERMS_CONDITIONS = "showTermsConditionsSegueID"
        static let PRIVACY_POLICY = "showPrivacyPolicySegueID"
    }
    
    
    //Unwind Segue ID's
    struct UnwindSegues {
        static let ACTIVATE_REACHME = "unwindToActivateReachMeControllreWithSegue"
        static let LOGIN = "unwindToLoginViewControllreSegue"
    }
    
    
    //API Events
    struct ApiCommands {
        static let JOIN_USER = "join_user"
        static let VERIFY_USER = "verify_user"
        static let SIGNIN = "sign_in"
        static let GET_PROFILE_INFO = "get_profile_info"
        static let FETCH_USER_CONTACTS = "fetch_user_contacts"
        static let FETCH_SETTINGS = "fetch_settings"
        static let LIST_CARRIERS = "list_carriers"
        static let GENERATE_VERIFICATION_CODE = "generate_veri_code"
        static let UPDATE_SETTINGS = "update_settings"
        static let GENERATE_PASSWORD = "generate_pwd"
        static let VERIFY_PASSWORD = "verify_pwd"
        static let UPDATE_PROFILE_INFO = "update_profile_info"
        static let UPLOAD_PIC = "upload_pic"
        static let MANAGE_USER_CONTACT = "manage_user_contact"
        static let VOICEMAIL_SETTING = "voicemail_setting"
        static let USAGE_SUMMARY = "rm_call_summ"
        static let SIGN_OUT = "sign_out"
        static let SET_DEVICEINFO = "set_device_info"
        static let FETCH_MESSAGES = "fetch_msgs"
        static let DELETE_MESSAGE = "delete_msg"
        static let READ_MESSAGES = "read_msgs"
        static let APP_STATUS = "app_status"
    }
    

    //Server
    #if DEBUG
        static let URL_SERVER = "https://stagingchannels.instavoice.com/iv"
        static let URL_MQTT_SERVER = "pn-staging14.instavoice.com"
    #else
        static let URL_SERVER = "https://blogs.instavoice.com/iv"
        static let URL_MQTT_SERVER = "pn.instavoice.com"
    #endif
    
    //Others
    static let PASSWORD_MIN_LENGTH = 6
    static let PASSWORD_MAX_LENGTH = 25
    static let CLIENT_APP_VER = "iv.05.01.001"
    static let DEVICE_UUID = String(describing: "rm" + (UIDevice.current.identifierForVendor?.uuidString)!)

}

extension DefaultsKeys {
    static let APIRegSecureKey = DefaultsKey<String?>("reg_secure_key")
    static let APIPnsAppIdKey = DefaultsKey<String?>("pns_app_id")
    static let APIDocURLKey = DefaultsKey<String?>("docs_url")
    static let APIUserSecureKey = DefaultsKey<String?>("user_secure_key")
    static let APICloudeSecureKey = DefaultsKey<String?>("cloud_secure_key")
    static let APIIVUserIDKey = DefaultsKey<Int>("iv_user_id")
    static let APIIsRMNewUser = DefaultsKey<Bool>("new_rm_user")
    static let APIFetchAfterMsgID = DefaultsKey<Any?>("fetch_after_msgs_id")

    
    static let IsLoggedInKey = DefaultsKey<Bool>("isLoggedIn")
    static let IsOnBoarding = DefaultsKey<Bool>("isOnboarding")
    static let IsCarrierSelection = DefaultsKey<Bool>("IsCarrierSelection")
    static let IsPersonalisation = DefaultsKey<Bool>("IsPersonalisation")
    static let isRingtoneSet = DefaultsKey<Bool>("ringtoneSet")
    static let needSetDeviceInfo = DefaultsKey<Bool>("setDeviceInfo")

}
