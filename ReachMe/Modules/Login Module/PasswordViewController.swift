//
//  PasswordViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/19/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire
import SwiftyUserDefaults

class PasswordViewController: UIViewController {

    @IBOutlet weak var mobileNumberLabel: UILabel!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mobileNumberLabel.text = Constants.appDelegate.userProfile?.mobileNumberFormated
        setupTextChangeHandling()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Custom Methods
    private func setupTextChangeHandling() {
        passwordTextField.setValue(UIColor.white, forKeyPath: "_placeholderLabel.textColor")
        passwordTextField.rx.controlEvent(.editingDidBegin)
            .subscribe { [weak self] _ in
                UIView.animate(withDuration: 0.2) {
                    self?.logoTopConstraint.constant = -20
                    self?.view.layoutIfNeeded()
                }
            }.disposed(by: disposeBag)
        
        let passwordText = passwordTextField.rx.text
            .map {
                self.validatePasswordField(text: $0!)
        }
        passwordText.bind(to: continueButton.rx.RxEnabled)
            .disposed(by: disposeBag)
    }
    
    func validatePasswordField(text: String) -> Bool {
        let trimmedString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        passwordTextField.text = trimmedString
        if (trimmedString.count >= Constants.PASSWORD_MIN_LENGTH),
            (trimmedString.count <= Constants.PASSWORD_MAX_LENGTH) {
            return true
        }
        
        return false
    }

    // MARK: - Button Actions
    @IBAction func didPressOnView(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.2) {
                self.logoTopConstraint.constant = 20
                self.view.layoutIfNeeded()
                self.view.endEditing(true)
        }
    }
    
    @IBAction func onForgotPasswordClicked(_ sender: UIButton) {
    }
    
    @IBAction func onContinueClicked(_ sender: UIButton) {
        guard RMUtility.isNetwork() else {
            RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
            return
        }

        ANLoader.showLoading("", disableUI: true)
        ServiceRequest.shared.startRequestForSignIn(passWord: passwordTextField.text!) { (success) in
            ANLoader.hide()
            guard success else { return }
            
            RMUtility.registerForPushNotifications()
            AppDelegate.shared.registerVOIPPush()

            DispatchQueue.main.async(execute: {
                if Defaults[.APIIsRMNewUser] {
                    Defaults[.IsCarrierSelection] = true
                    self.performSegue(withIdentifier: Constants.Segues.CARRIERLIST, sender: self)
                } else {
                    Defaults[.IsLoggedIn] = true
                    ServiceRequest.shared.connectMQTT()
                    RMUtility.showdDashboard()
                }
            })
        }
    }
    
    @IBAction func onCancelClicked(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
 
    // MARK: - Unwind Action
    @IBAction func unwindToPasswordViewControllre(segue: UIStoryboardSegue) {}

}
