//
//  OTPViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/18/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import CountdownLabel
import Alertift
import SwiftyUserDefaults

enum OTPType {
    case Forgot
    case Register
    case ManageUserContact
}

class OTPViewController: UIViewController {

    @IBOutlet weak var timerLabel: CountdownLabel!
    @IBOutlet weak var callmeLabel: UILabel!
    @IBOutlet weak var validateButton: UIButton!
    @IBOutlet weak var OTPView: VPMOTPView!
    var otpType: OTPType = .Register /*Default*/
    var otpString: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupOTPView()
        setupCounter()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupCounter() {
        timerLabel.setCountDownTime(minutes: 10)
        timerLabel.timeFormat = "mm:ss"
        timerLabel.animationType = .Evaporate
        timerLabel.countdownDelegate = self
        timerLabel.start()
    }
    
    func setupOTPView() {
        OTPView.otpFieldDisplayType = .square
        OTPView.otpFieldSeparatorSpace = 0
        OTPView.otpFieldSize = 70
        OTPView.otpFieldBorderWidth = 0.5
        OTPView.otpFieldDefaultBorderColor = .lightGray
        OTPView.otpFieldEnteredBorderColor = .lightGray
        OTPView.delegate = self
        OTPView.initalizeUI()
    }

    // MARK: - Actions
    @IBAction func onLabelTapGesture(_ sender: UITapGestureRecognizer) {
        guard !timerLabel.isCounting else { return }
        
        let text = (callmeLabel.text)!
        let callmeRange = (text as NSString).range(of: "Call Me")
        if sender.didTapAttributedTextInLabel(label: callmeLabel, inRange: callmeRange) {
            
            Alertift.alert(title: """
                                     Confirm mobile number
                                     \(Constants.appDelegate.userProfile?.mobileNumberFormated! ?? "")
                                  """,
                           message: "You will receive a call with the validation code. Is the number OK, or would you like to change it?")
                .action(.destructive("Change")) { (action, count, nil) in
                    self.navigationController?.popViewController(animated: true)
                }
                .action(.default("Ok")) { (action, count, nil) in
                    guard RMUtility.isNetwork() else {
                        RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                        return
                    }
                    
                    ANLoader.showLoading("", disableUI: true)
                    ServiceRequest.shared.startRequestForGenerateVerificationCode(completionHandler: { (success) in
                        ANLoader.hide()
                        guard success else { return }

                        self.setupCounter()
                        RMUtility.showAlert(withMessage: "VALIDATION_CALL".localized)

                    })
                    
            }.show()
        }
    }
    
    @IBAction func onValidateClicked(_ sender: UIButton) {
        guard RMUtility.isNetwork() else {
            RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
            return
        }
        
        ANLoader.showLoading("", disableUI: true)
        
        switch otpType {
        case .Register:
            ServiceRequest.shared.startRequestForVerifyUser(otpString: otpString!, completionHandler: { (success) in
                guard success else { return }
                ANLoader.hide()
                
                if Defaults[.APIIsRMNewUser] {
                    Defaults[.IsCarrierSelection] = true
                    self.performSegue(withIdentifier: Constants.Segues.CARRIERLIST, sender: self)
                } else {
                    Defaults[.IsLoggedIn] = true
                    ServiceRequest.shared.connectMQTT()
                    RMUtility.showdDashboard()
                }
            })
            
        case .Forgot:
            ServiceRequest.shared.startRequestForVerifyPassword(otpString: otpString!, completionHandler: { (success) in
                guard success else { return }
                ANLoader.hide()
                self.performSegue(withIdentifier: Constants.Segues.RESET_PASSWORD, sender: self)
            })
            
        case .ManageUserContact:
            print("temp")
        }
    }
    
}

// MARK: - VPMOTPViewDelegate
extension OTPViewController: VPMOTPViewDelegate {
    func shouldBecomeFirstResponderForOTP(otpFieldIndex index: Int) -> Bool {
        return true
    }
    
    func hasEnteredAllOTP(hasEntered: Bool) {
        validateButton.alpha = hasEntered ? 1.0 : 0.7
        validateButton.isEnabled = hasEntered ? true : false
        otpString = hasEntered ? "" : nil
    }
    
    func enteredOTP(otpString: String) {
        self.otpString = otpString
    }
}

// MARK: - CountdownDelegate
extension OTPViewController: CountdownLabelDelegate {
    func countdownFinished() {
        let attributedString = NSMutableAttributedString(string: callmeLabel.text!)
        attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.white, range: NSRange(location:42, length:7))
        callmeLabel.attributedText = attributedString
    }
    
    func countdownStarted() {
        let attributedString = NSMutableAttributedString(string: callmeLabel.text!)
        attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.darkGray, range: NSRange(location:42, length:7))
        callmeLabel.attributedText = attributedString
    }
}
