//
//  LinphoneManager.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 5/29/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation

var answerCall: Bool = false

struct theLinphone {
    static var lc: OpaquePointer?
    static var lct: LinphoneCoreVTable?
    static var manager: LinphoneManager?
}

let registrationStateChanged: LinphoneCoreRegistrationStateChangedCb  = {
    (lc: Optional<OpaquePointer>, proxyConfig: Optional<OpaquePointer>, state: _LinphoneRegistrationState, message: Optional<UnsafePointer<Int8>>) in

    switch state {
    case LinphoneRegistrationNone: /**<Initial state for registrations */
        NSLog("LinphoneRegistrationNone")

    case LinphoneRegistrationProgress:
        NSLog("LinphoneRegistrationProgress")

    case LinphoneRegistrationOk:
        NSLog("LinphoneRegistrationOk")

    case LinphoneRegistrationCleared:
        NSLog("LinphoneRegistrationCleared")

    case LinphoneRegistrationFailed:
        NSLog("LinphoneRegistrationFailed")

    default:
        NSLog("Unkown registration state")
    }
    } as LinphoneCoreRegistrationStateChangedCb

let callStateChanged: LinphoneCoreCallStateChangedCb = {
    (lc: Optional<OpaquePointer>, call: Optional<OpaquePointer>, callSate: LinphoneCallState, message: Optional<UnsafePointer<Int8>>) in

    switch callSate {
    case LinphoneCallIncomingReceived: /**<This is a new incoming call */
        NSLog("callStateChanged: LinphoneCallIncomingReceived")
        if answerCall {
            ms_usleep(3 * 1000 * 1000) // Wait 3 seconds to pickup
            linphone_core_accept_call(lc, call)
        }

    case LinphoneCallStreamsRunning: /**<The media streams are established and running*/
        NSLog("callStateChanged: LinphoneCallStreamsRunning")

    case LinphoneCallError: /**<The call encountered an error*/
        NSLog("callStateChanged: LinphoneCallError")

    default:
        NSLog("Default call state")
    }
}

class LinphoneManager {

    public static let shared = LinphoneManager()
    static var iterateTimer: Timer?
    let voipSetting = AppDelegate.shared.userProfile?.voipSettings

    init() {
        theLinphone.lct = LinphoneCoreVTable()

        // Enable debug log to stdout
        linphone_core_set_log_file(nil)
        linphone_core_set_log_level(ORTP_DEBUG)

        // Load config
        let configFilename = documentFile("linphonerc222")
        let factoryConfigFilename = UIDevice.current.userInterfaceIdiom == .pad ? bundleFile("linphonerc~ipad") : bundleFile("linphonerc-factory")

        let configFilenamePtr: UnsafePointer<Int8> = configFilename.cString(using: String.Encoding.utf8.rawValue)!
        let factoryConfigFilenamePtr: UnsafePointer<Int8> = factoryConfigFilename.cString(using: String.Encoding.utf8.rawValue)!
        let lpConfig = linphone_config_new_with_factory(configFilenamePtr, factoryConfigFilenamePtr)

        // Set Callback
        theLinphone.lct?.registration_state_changed = registrationStateChanged
        theLinphone.lct?.call_state_changed = callStateChanged

        theLinphone.lc = linphone_core_new_with_config(&theLinphone.lct!, lpConfig, nil)

        // Set ring asset
        let ringbackPath = URL(fileURLWithPath: Bundle.main.bundlePath).appendingPathComponent("/ringback.wav").absoluteString
        linphone_core_set_ringback(theLinphone.lc, ringbackPath)

        let localRing = URL(fileURLWithPath: Bundle.main.bundlePath).appendingPathComponent("/notes_of_the_optimistic.caf").absoluteString
        linphone_core_set_ring(theLinphone.lc, localRing)
        
        let holdRing = URL(fileURLWithPath: Bundle.main.bundlePath).appendingPathComponent("/hold.mkv").absoluteString
        linphone_core_set_play_file(theLinphone.lc, holdRing)

        //TODO:- Confirm with below lines wheather required or not
        /*linphone_core_set_root_ca(theLinphoneCore, [LinphoneManager bundleFile:@"rootca.pem"].UTF8String);
        linphone_core_set_user_certificates_path(theLinphoneCore, [LinphoneManager cacheDirectory].UTF8String);*/
        
        registerAccount()

        setTimer()
    }

    fileprivate func bundleFile(_ file: NSString) -> NSString {
        return Bundle.main.path(forResource: file.deletingPathExtension, ofType: file.pathExtension)! as NSString
    }

    fileprivate func documentFile(_ file: NSString) -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)

        let documentsPath: NSString = paths[0] as NSString
        return documentsPath.appendingPathComponent(file as String) as NSString
    }
    
    fileprivate func normalizePhoneAddress(_ address: String) -> Optional<OpaquePointer> {
        
        let linPhoneAddress: Optional<OpaquePointer>
        let cfg = linphone_core_get_default_proxy_config(theLinphone.lc)
        
        let normvalue: String
        if linphone_proxy_config_is_phone_number(cfg, address) as UInt8 == 1 {
            normvalue = String(cString: linphone_proxy_config_normalize_phone_number(cfg, address))
        } else {
            normvalue = address
        }
        
        linPhoneAddress = linphone_proxy_config_normalize_sip_uri(cfg, normvalue)

        if let phoneAddress = linPhoneAddress {
            if ((cfg != nil) && ((linphone_proxy_config_get_dial_escape_plus(cfg) as UInt8) == 1)),
                linphone_proxy_config_is_phone_number(cfg, normvalue) as UInt8 == 1 {
                linphone_address_set_username(phoneAddress, normvalue)

            } else if linphone_proxy_config_is_phone_number(cfg, address) as UInt8 == 1 {
                linphone_address_set_username(phoneAddress, address)
            }
        }
        
        return linPhoneAddress
    }

    func makeCall(for address: String) {
        guard linphone_core_is_network_reachable(theLinphone.lc) as UInt8 == 0 else {
            RMUtility.showAlert(withMessage: "Network Error", title: "There is no network connection available, enable WIFI or WWAN prior to place a call")
            return
        }
        
        guard AppDelegate.shared.callManager.calls.count == 0 else {
            RMUtility.showAlert(withMessage: "Cannot make call", title: "Please terminate GSM call first.")
            return
        }
        
        guard let linPhoneAddress = normalizePhoneAddress(address) else {
            RMUtility.showAlert(withMessage: "Invalid SIP address",
                                title: """
                                          Either configure a SIP proxy server from settings prior to place a
                                          call or use a valid SIP address (I.E sip:john@example.net)
                                       """)

            return
        }
        
        
        
        if linphone_core_get_calls_nb(theLinphone.lc) < 1 {
            print("Start Call")
        }
        
        if linPhoneAddress != nil {
            linphone_address_destroy(linPhoneAddress)
        }
    }
    
    fileprivate func registerAccount() {
        
        let identity = "sip:" + (voipSetting?.login)! + "@" + (voipSetting?.ipAddress)! + ":" + String(describing: (voipSetting?.port)!)
        let proxy_cfg = linphone_proxy_config_new()
        guard let sipAddr = linphone_address_new(identity) else {
            NSLog("\(identity) not a valid sip uri, must be like sip:toto@sip.linphone.org")
            return
        }

        //linphone_proxy_config_set_identity_address(proxy_cfg, sipAddr)
        
        let info=linphone_auth_info_new(linphone_address_get_username(sipAddr), nil, (voipSetting?.login)!, nil, nil, nil) /*create authentication structure from identity*/
        linphone_core_add_auth_info(theLinphone.lc, info) /*add authentication info to LinphoneCore*/
        
        // configure proxy entries
        linphone_proxy_config_set_identity(proxy_cfg, identity) /*set identity with user name and domain*/
        let server_addr = String(cString: linphone_address_get_domain(sipAddr)) /*extract domain address from identity*/
        linphone_address_destroy(sipAddr) /*release resource*/
        
        linphone_proxy_config_set_server_addr(proxy_cfg, server_addr) /* we assume domain = proxy server address*/
        linphone_proxy_config_enable_register(proxy_cfg, 1) /* activate registration for this proxy config*/
        linphone_core_add_proxy_config(theLinphone.lc, proxy_cfg) /*add proxy config to linphone core*/
        linphone_core_set_default_proxy_config(theLinphone.lc, proxy_cfg) /*set to default proxy*/

    }
    
    //
    // This is the start point to know how linphone library works.
    //
    func demo() {
            makeCall()
        // autoPickImcomingCall()
        //idle()
    }

    func makeCall() {
        let calleeAccount = "0702552520"

        guard let _ = setIdentify() else {
            print("no identity")
            return
        }
        linphone_core_invite(theLinphone.lc, calleeAccount)
        setTimer()
        //        shutdown()
    }

    func receiveCall() {
        guard let proxyConfig = setIdentify() else {
            print("no identity")
            return
        }
        register(proxyConfig)
        setTimer()
        //        shutdown()
    }

    func idle() {
        guard let proxyConfig = setIdentify() else {
            print("no identity")
            return
        }
        register(proxyConfig)
        setTimer()
        //        shutdown()
    }

    func setIdentify() -> OpaquePointer? {

        // Reference: http://www.linphone.org/docs/liblinphone/group__registration__tutorials.html

        let path = Bundle.main.path(forResource: "Secret", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
        let account = dict?.object(forKey: "account") as! String
        let password = dict?.object(forKey: "password") as! String
        let domain = dict?.object(forKey: "domain") as! String

        let identity = "sip:" + account + "@" + domain

        /*create proxy config*/
        let proxy_cfg = linphone_proxy_config_new()

        /*parse identity*/
        let from = linphone_address_new(identity)

        if from == nil {
            NSLog("\(identity) not a valid sip uri, must be like sip:toto@sip.linphone.org")
            return nil
        }

        let info=linphone_auth_info_new(linphone_address_get_username(from), nil, password, nil, nil, nil) /*create authentication structure from identity*/
        linphone_core_add_auth_info(theLinphone.lc, info) /*add authentication info to LinphoneCore*/

        // configure proxy entries
        linphone_proxy_config_set_identity(proxy_cfg, identity) /*set identity with user name and domain*/
        let server_addr = String(cString: linphone_address_get_domain(from)) /*extract domain address from identity*/

        linphone_address_destroy(from) /*release resource*/

        linphone_proxy_config_set_server_addr(proxy_cfg, server_addr) /* we assume domain = proxy server address*/
        linphone_proxy_config_enable_register(proxy_cfg, 0) /* activate registration for this proxy config*/
        linphone_core_add_proxy_config(theLinphone.lc, proxy_cfg) /*add proxy config to linphone core*/
        linphone_core_set_default_proxy_config(theLinphone.lc, proxy_cfg) /*set to default proxy*/

        return proxy_cfg!
    }

    func register(_ proxy_cfg: OpaquePointer) {
        linphone_proxy_config_enable_register(proxy_cfg, 1) /* activate registration for this proxy config*/
    }

    func shutdown() {
        NSLog("Shutdown..")

        let proxy_cfg = linphone_core_get_default_proxy_config(theLinphone.lc) /* get default proxy config*/
        linphone_proxy_config_edit(proxy_cfg) /*start editing proxy configuration*/
        linphone_proxy_config_enable_register(proxy_cfg, 0) /*de-activate registration for this proxy config*/
        linphone_proxy_config_done(proxy_cfg) /*initiate REGISTER with expire = 0*/
        while linphone_proxy_config_get_state(proxy_cfg) !=  LinphoneRegistrationCleared {
            linphone_core_iterate(theLinphone.lc) /*to make sure we receive call backs before shutting down*/
            ms_usleep(50000)
        }

        linphone_core_destroy(theLinphone.lc)
    }

    @objc func iterate() {
        if let lc = theLinphone.lc {
            linphone_core_iterate(lc) /* first iterate initiates registration */
        }
    }

    fileprivate func setTimer() {
        LinphoneManager.iterateTimer = Timer.scheduledTimer(
            timeInterval: 0.02, target: self, selector: #selector(iterate), userInfo: nil, repeats: true)
    }
}
