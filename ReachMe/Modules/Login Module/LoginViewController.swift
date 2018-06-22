//
//  LoginViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/17/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import CountryPickerView
import RxSwift
import RxCocoa
import PhoneNumberKit
import CoreTelephony
import SwiftyUserDefaults
import CoreData

enum AutheticationType {
    case authTypeOTP
    case authTypePassword
    case authTypeMultiuser
    case error
}

class LoginViewController: UIViewController {

    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var selectedCountryButton: UIButton!
    @IBOutlet weak var countryCodeLabel: UILabel!
    @IBOutlet weak var countryFlag: UIImageView!
    @IBOutlet weak var termsOfUseLabel: UILabel!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    let countryPicker = CountryPickerView()
    private let disposeBag = DisposeBag()
    @IBOutlet weak var numberTextField: PhoneNumberTextField!
    private let coreDataStack = Constants.appDelegate.coreDataStack

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup
        setupCountry()
        setupTextChangeHandling()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        RMUtility.deleteUserProfile()
        Defaults.removeAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Actions
    @IBAction func onLinkGestureClicked(_ sender: UITapGestureRecognizer) {
        
        let text = (termsOfUseLabel.text)!
        let termsRange = (text as NSString).range(of: "Terms of Use")
        if sender.didTapAttributedTextInLabel(label: termsOfUseLabel, inRange: termsRange) {
            guard RMUtility.isNetwork() else {
                RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                return
            }
            
            performSegue(withIdentifier: Constants.Segues.TERMS_CONDITIONS, sender: nil)
        }
    }
    
    @IBAction func didPressOnView(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.2) {
            self.containerBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
            self.view.endEditing(true)
        }
    }
    
    @IBAction func onSignInClicked(_ sender: UIButton) {
        
        let alert = UIAlertController(style: .alert, title: "Confirm mobile number", message: """
                                    Is this OK,
                                    or would you like to change it?
                                """)
        alert.addAction(title: "Cancel", style: .destructive)
        alert.addAction(title: "Confirm", handler: { _ in
            self.view.endEditing(true)
            guard RMUtility.isNetwork() else {
                RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                return
            }
            
            ANLoader.showLoading("", disableUI: true)
            self.coreDataStack.performAndWait(inContext: { (context) in
                let userProfile = Profile(context: context)
                userProfile.countryName = self.countryPicker.selectedCountry.name
                userProfile.countryCode = self.countryPicker.selectedCountry.code
                if let stateSearchCode = self.countryPicker.selectedCountry.stateSearchCode {
                    userProfile.countryPhoneCode = stateSearchCode
                } else {
                    userProfile.countryPhoneCode = self.countryPicker.selectedCountry.phoneCode
                }
                userProfile.mobileNumber = self.numberTextField.nationalNumber
                userProfile.countryISOCode = String(self.countryPicker.selectedCountry.phoneCode.dropFirst())
                userProfile.userID = String(describing: userProfile.countryISOCode!) + String(describing: userProfile.mobileNumber!)
                userProfile.mobileNumberFormated = self.countryPicker.selectedCountry.phoneCode  + " " + self.numberTextField.text!
                if let countryImageData = UIImagePNGRepresentation(self.countryPicker.selectedCountry.flag) {
                    userProfile.countryImageData = countryImageData
                }
                
                let networkInfo = CTTelephonyNetworkInfo()
                if let carrier = networkInfo.subscriberCellularProvider {
                    userProfile.simCarrierName = carrier.carrierName
                    userProfile.simMCCNumber = carrier.mobileCountryCode
                    userProfile.simMNCNumber = carrier.mobileNetworkCode
                    userProfile.simISOCode = carrier.isoCountryCode
                    userProfile.simMCCMNCNumber = carrier.mobileCountryCode! + carrier.mobileNetworkCode!
                }
            })
            
            ServiceRequest.shared.startRequestForJoinUser(completionHandler: { (response, errorMessage) in
                ANLoader.hide()
                DispatchQueue.main.async(execute: {
                    switch response as AutheticationType {
                    case .authTypeOTP:
                        self.performSegue(withIdentifier: Constants.Segues.OTP, sender: self)
                        
                    case .authTypePassword:
                        self.performSegue(withIdentifier: Constants.Segues.PASSWORD, sender: self)
                        
                    case .authTypeMultiuser:
                        break
                        
                    case .error:
                        RMUtility.showAlert(withMessage: errorMessage!)
                    }
                })
            })
        })
        alert.show()
    }
    
    @IBAction func onSelectCountryClicked(_ sender: UIButton) {
        countryPicker.showCountriesList(from: self)
        didPressOnView(UITapGestureRecognizer())
    }
    
    // MARK: - Custom Methods
    private func setupCountry() {
        
        countryPicker.delegate = self
        countryPicker.dataSource = self
        countryFlag.image = countryPicker.selectedCountry.flag
        countryCodeLabel.text = countryPicker.selectedCountry.phoneCode
        selectedCountryButton.setTitle(countryPicker.selectedCountry.name, for: .normal)
    }
    
    private func setupTextChangeHandling() {
        
        numberTextField.setValue(UIColor.white, forKeyPath: "_placeholderLabel.textColor")
        numberTextField.defaultRegion = countryPicker.selectedCountry.code
        
        numberTextField.rx.controlEvent(.editingDidBegin)
            .subscribe { [weak self] _ in
                UIView.animate(withDuration: 0.2) {
                    self?.containerBottomConstraint.constant = -160
                    self?.view.layoutIfNeeded()
                }
            }.disposed(by: disposeBag)
        
        let numberText = numberTextField.rx.text.skip(11)
            .map {
                self.validateNumberField(text: $0!)
        }
        numberText.bind(to: signInButton.rx.RxEnabled)
            .disposed(by: disposeBag)
    }

    func validateNumberField(text: String) -> Bool {
        return numberTextField.isValidNumber
    }
    
    // MARK: - Segue Action
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segues.TERMS_CONDITIONS {
            let destVC = segue.destination as! WebViewController
            destVC.title = "Terms & Conditions"
            destVC.urlString = "https://getreachme.instavoice.com/terms"
        }
    }
    
    // MARK: - Unwind Action
    @IBAction func unwindToLoginViewControllre(segue: UIStoryboardSegue) {}

}

// MARK: - CountryPicker Delegate & Datasource
extension LoginViewController: CountryPickerViewDelegate {
    
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        numberTextField.text = nil
        numberTextField.defaultRegion = country.code
        countryFlag.image = country.flag
        countryCodeLabel.text = country.phoneCode
        selectedCountryButton.setTitle(country.name, for: .normal)
    }
}

extension LoginViewController: CountryPickerViewDataSource {
    
    func preferredCountries(in countryPickerView: CountryPickerView) -> [Country]? {
        var countries = [Country]()
        ["NG", "US", "IN", "GH", "CN"].forEach { code in
            if let country = countryPickerView.getCountryByCode(code) {
                countries.append(country)
            }
        }
        return countries
    }

    func showOnlyPreferredSection(in countryPickerView: CountryPickerView) -> Bool? {
        return false
    }

    func closeButtonNavigationItem(in countryPickerView: CountryPickerView) -> UIBarButtonItem? {
        return nil
    }

    func showPhoneCodeInList(in countryPickerView: CountryPickerView) -> Bool? {
        return true
    }

    func sectionTitleForPreferredCountries(in countryPickerView: CountryPickerView) -> String? {
        return "Preferred Countries"
    }

    func navigationTitle(in countryPickerView: CountryPickerView) -> String? {
        return "Select a Country"
    }

    func searchBarPosition(in countryPickerView: CountryPickerView) -> SearchBarPosition {
        return .tableViewHeader
    }

}
