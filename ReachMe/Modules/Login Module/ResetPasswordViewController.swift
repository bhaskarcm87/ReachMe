//
//  ResetPasswordViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/2/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alertift
import Alamofire
import SwiftyUserDefaults

enum ValidationResult {
    case passLenthMismathc
    case confirmNotMatch
    case ok
    
    var value: String {
        switch self {
        case .passLenthMismathc:
            return "ALERT_PWD".localized
        case .confirmNotMatch:
            return "PWD_NOT_MATCH".localized
        default:
            return ""
        }
    }
    
    var isValid: Bool {
        switch self {
        case .ok:
            return true
        default:
            return false
        }
    }
}

class ResetPasswordViewController: UIViewController {
    
    @IBOutlet weak var mobileNumberLabel: UILabel!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    private let disposeBag = DisposeBag()
    var userProfile: Profile? = CoreDataModel.sharedInstance().getUserProfle()

    override func viewDidLoad() {
        super.viewDidLoad()

        mobileNumberLabel.text = userProfile?.mobileNumberFormated
        setupTextChangeHandling()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Custom Methods
    private func setupTextChangeHandling() {
        //New field
        passwordTextField.setValue(UIColor.white, forKeyPath: "_placeholderLabel.textColor")
        passwordTextField.rx.controlEvent(.editingDidBegin)
            .subscribe { [weak self] _ in
                UIView.animate(withDuration: 0.2) {
                    self?.logoTopConstraint.constant = -20
                    self?.view.layoutIfNeeded()
                }
            }.disposed(by: disposeBag)
        let newPassText =  passwordTextField.rx.text.skip(7)
            .throttle(0.3, scheduler: MainScheduler.instance)
            .map {
                self.validateNewPassField(text: $0!)
        }

        //Confirm Field
        confirmPasswordTextField.setValue(UIColor.white, forKeyPath: "_placeholderLabel.textColor")
        confirmPasswordTextField.rx.controlEvent(.editingDidBegin)
            .subscribe { [weak self] _ in
                UIView.animate(withDuration: 0.2) {
                    self?.logoTopConstraint.constant = -20
                    self?.view.layoutIfNeeded()
                }
            }.disposed(by: disposeBag)
        let confirmPassText =  confirmPasswordTextField.rx.text.skip(7)
            .throttle(0.3, scheduler: MainScheduler.instance)
            .map {
                self.validateConfirmPassField(text: $0!)
        }
        
        //Continue Button enable handle
        var continueEnabled: Observable<Bool>
        continueEnabled = Observable.combineLatest(newPassText, confirmPassText) { newpass, confrimpass in
                newpass.isValid &&
                confrimpass.isValid &&
                self.passwordTextField.text! == self.confirmPasswordTextField.text!
            }.distinctUntilChanged()

        continueEnabled.bind(to: continueButton.rx.RxEnabled)
            .disposed(by: disposeBag)
    }
    
    func validateNewPassField(text: String) -> ValidationResult {
        if text.count < Constants.PASSWORD_MIN_LENGTH || text.count > Constants.PASSWORD_MAX_LENGTH {
            return .passLenthMismathc
        } else if let confirmtext = passwordTextField.text, !confirmtext.isEmpty, confirmtext != text {
            return .confirmNotMatch
        } else {
            return .ok
        }
    }
    
    func validateConfirmPassField(text: String) -> ValidationResult {
        if text.count < Constants.PASSWORD_MIN_LENGTH || text.count > Constants.PASSWORD_MAX_LENGTH {
            return .passLenthMismathc
        } else if text != confirmPasswordTextField.text {
            return .confirmNotMatch
        } else {
            return .ok
        }
    }
    
    // MARK: - Actions
    @IBAction func onContinueClicked(_ sender: UIButton) {
        
        ANLoader.showLoading("", disableUI: true)
        var params: [String: Any] = ["cmd": Constants.ApiCommands.UPDATE_PROFILE_INFO,
                                     "pwd": confirmPasswordTextField.text!]
        ServiceRequest.shared().startRequestForUpdateProfileInfo(withProfileInfo: &params) { (success) in
            guard success else { return }

            ServiceRequest.shared().startRequestForSignIn(passWord: self.confirmPasswordTextField.text!) { (success) in
                ANLoader.hide()
                guard success else { return }

                self.performSegue(withIdentifier: Constants.Segues.CARRIERLIST, sender: self)
            }
        }
    }
    
    @IBAction func didPressOnView(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.2) {
            self.logoTopConstraint.constant = 20
            self.view.layoutIfNeeded()
            self.view.endEditing(true)
        }
    }
}
