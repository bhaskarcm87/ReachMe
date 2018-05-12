//
//  ChangePasswordViewController.swift
//  MyTest
//
//  Created by Sachin Kumar Patra on 1/24/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

@objc extension UIAlertController {
    func addChangePasswordController (oldPassTextField: UITextField, newPassTextField: UITextField, confirmPassTextField: UITextField, alert: UIAlertController) {
        let vc = ChangePasswordViewController(oldPassTextField: oldPassTextField, newPassTextField: newPassTextField, confirmPassTextField: confirmPassTextField, alert: alert)
        set(viewController: vc)
        view.backgroundColor = UIColor(red: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
        view.layer.cornerRadius = 12
    }
}

class ChangePasswordViewController: UITableViewController {
    
    let oldPassTextField: UITextField!
    let newPassTextField: UITextField!
    let confirmPassTextField: UITextField!
    let alert: UIAlertController!
    var isOldPassValidated = false
    var isNewPassValidated = false
    var isConfirmPassValidated = false
    
    // MARK: - Initializers
    init(oldPassTextField: UITextField, newPassTextField: UITextField, confirmPassTextField: UITextField, alert: UIAlertController) {
        self.oldPassTextField = oldPassTextField
        self.newPassTextField = newPassTextField
        self.confirmPassTextField = confirmPassTextField
        self.alert = alert

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.isScrollEnabled = false
        
        configureTextFileds()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Custom Methods
    func configureTextFileds() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: UIScreen.main.bounds.height / 4.5))
        headerView.addSubview(oldPassTextField)
        headerView.addSubview(newPassTextField)
        headerView.addSubview(confirmPassTextField)
        
        oldPassTextField.translatesAutoresizingMaskIntoConstraints = false
        headerView.addConstraint(NSLayoutConstraint(item: oldPassTextField, attribute: .top, relatedBy: .equal, toItem: headerView, attribute: .top, multiplier: 1, constant: 0))
        if let pass = Constants.appDelegate.userProfile?.password, !pass.isEmpty {
            headerView.addConstraint(NSLayoutConstraint(item: oldPassTextField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30))
            preferredContentSize.height = 163
        } else {
            headerView.addConstraint(NSLayoutConstraint(item: oldPassTextField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0))
            isOldPassValidated = true
            preferredContentSize.height = 123

        }
        headerView.addConstraint(NSLayoutConstraint(item: oldPassTextField, attribute: .leading, relatedBy: .equal, toItem: headerView, attribute: .leading, multiplier: 1, constant: 17))
        headerView.addConstraint(NSLayoutConstraint(item: oldPassTextField, attribute: .trailing, relatedBy: .equal, toItem: headerView, attribute: .trailing, multiplier: 1, constant: -17))
        
        //Old TextField
        oldPassTextField.placeholder = "Enter old password"
        oldPassTextField.borderStyle = UITextBorderStyle.line
        oldPassTextField.layer.borderColor = UIColor.lightGray.cgColor
        oldPassTextField.layer.borderWidth = 1.0
        oldPassTextField.font = UIFont(name: "systemFont", size: 14)
        oldPassTextField.backgroundColor = UIColor.clear
        oldPassTextField.clearButtonMode = .whileEditing
        oldPassTextField.autocapitalizationType = .none
        oldPassTextField.isSecureTextEntry = true
        oldPassTextField.clearsOnBeginEditing = true
        oldPassTextField.returnKeyType = .done
        oldPassTextField.delegate = self
        
        //New TextField
        newPassTextField.translatesAutoresizingMaskIntoConstraints = false
        headerView.addConstraint(NSLayoutConstraint(item: newPassTextField, attribute: .top, relatedBy: .equal, toItem: oldPassTextField, attribute: .bottom, multiplier: 1, constant: 20))
        headerView.addConstraint(NSLayoutConstraint(item: newPassTextField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30))
        headerView.addConstraint(NSLayoutConstraint(item: newPassTextField, attribute: .leading, relatedBy: .equal, toItem: headerView, attribute: .leading, multiplier: 1, constant: 17))
        headerView.addConstraint(NSLayoutConstraint(item: newPassTextField, attribute: .trailing, relatedBy: .equal, toItem: headerView, attribute: .trailing, multiplier: 1, constant: -17))
        newPassTextField.placeholder = "Enter new password"
        newPassTextField.borderStyle = UITextBorderStyle.line
        newPassTextField.layer.borderColor = UIColor.lightGray.cgColor
        newPassTextField.layer.borderWidth = 1.0
        newPassTextField.font = UIFont(name: "systemFont", size: 14)
        newPassTextField.backgroundColor = UIColor.clear
        newPassTextField.autocapitalizationType = .none
        newPassTextField.isSecureTextEntry = true
        newPassTextField.clearsOnBeginEditing = true
        newPassTextField.returnKeyType = .done
        newPassTextField.delegate = self
        
        //Confirm TextField
        confirmPassTextField.translatesAutoresizingMaskIntoConstraints = false
        headerView.addConstraint(NSLayoutConstraint(item: confirmPassTextField, attribute: .top, relatedBy: .equal, toItem: newPassTextField, attribute: .bottom, multiplier: 1, constant: 20))
        headerView.addConstraint(NSLayoutConstraint(item: confirmPassTextField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30))
        headerView.addConstraint(NSLayoutConstraint(item: confirmPassTextField, attribute: .leading, relatedBy: .equal, toItem: headerView, attribute: .leading, multiplier: 1, constant: 17))
        headerView.addConstraint(NSLayoutConstraint(item: confirmPassTextField, attribute: .trailing, relatedBy: .equal, toItem: headerView, attribute: .trailing, multiplier: 1, constant: -17))
        confirmPassTextField.placeholder = "Enter new password again"
        confirmPassTextField.borderStyle = UITextBorderStyle.line
        confirmPassTextField.layer.borderColor = UIColor.lightGray.cgColor
        confirmPassTextField.layer.borderWidth = 1.0
        confirmPassTextField.font = UIFont(name: "systemFont", size: 14)
        confirmPassTextField.backgroundColor = UIColor.clear
        confirmPassTextField.autocapitalizationType = .none
        confirmPassTextField.isSecureTextEntry = true
        confirmPassTextField.clearsOnBeginEditing = true
        confirmPassTextField.returnKeyType = .done
        confirmPassTextField.delegate = self

        tableView.tableHeaderView = headerView
    }
    
}

// MARK: - TextField Delegate
extension ChangePasswordViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        alert.actions.last?.isEnabled = false
        
        switch textField {
        case oldPassTextField:
            isOldPassValidated = false
        case newPassTextField:
            isNewPassValidated = false
            confirmPassTextField.text = ""
        case confirmPassTextField:
            isConfirmPassValidated = false
        default:
            break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case oldPassTextField:
            guard let oldPass = textField.text, !oldPass.isEmpty else {
                alert.set(message: "OLD_PASS".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                return
            }
            if oldPass != Constants.appDelegate.userProfile?.password {
                alert.set(message: "OLD_PWD_NOT_MATCHED".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                oldPassTextField.text = ""
            } else {
                isOldPassValidated = true
                alert.set(message: "", font: .systemFont(ofSize: 14), color: UIColor.red)
            }
            
        case newPassTextField:
            guard let newPass = textField.text, !newPass.isEmpty else {
                alert.set(message: "NEW_PASS".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                return
            }
            if newPass.count < Constants.PASSWORD_MIN_LENGTH {
                alert.set(message: "ALERT_PWD".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
            } else if newPass.count > Constants.PASSWORD_MAX_LENGTH {
                alert.set(message: "PWD_MAX_LIMIT".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
            } else {
                isNewPassValidated = true
                alert.set(message: "", font: .systemFont(ofSize: 14), color: UIColor.red)
            }
            
        case confirmPassTextField:
            guard let confirmPass = textField.text, !confirmPass.isEmpty else {
                alert.set(message: "NEW_PASS_AGAIN".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                return
            }
            if newPassTextField.text != confirmPass {
                alert.set(message: "PWD_NOT_MATCH".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                newPassTextField.text = ""
                confirmPassTextField.text = ""
            } else {
                isConfirmPassValidated = true
                alert.set(message: "", font: .systemFont(ofSize: 14), color: UIColor.red)
            }

        default:
            break
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if range.location == 0, string == " " { //Block leading space
            return false
        }
        
        if let replaceStart = textField.position(from: textField.beginningOfDocument, offset: range.location),
            let replaceEnd = textField.position(from: replaceStart, offset: range.length),
            let textRange = textField.textRange(from: replaceStart, to: replaceEnd) {
            textField.replace(textRange, withText: string)
        }
        
        switch textField {
        case oldPassTextField:
            if isNewPassValidated, isConfirmPassValidated {
                guard let oldPassLength = oldPassTextField.text?.count,
                    let storedPassLength = Constants.appDelegate.userProfile?.password?.count else {
                        return false
                }
                
                if oldPassTextField.text! == Constants.appDelegate.userProfile?.password {
                    alert.actions.last?.isEnabled = true
                    alert.set(message: "".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                } else if oldPassLength > storedPassLength ||
                    (oldPassLength == storedPassLength && oldPassTextField.text! != Constants.appDelegate.userProfile?.password) {
                    alert.actions.last?.isEnabled = false
                    alert.set(message: "OLD_PWD_NOT_MATCHED".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                } else {
                    alert.actions.last?.isEnabled = false
                }
            }
        case newPassTextField:
            if isOldPassValidated, isConfirmPassValidated {
                if newPassTextField.text! == confirmPassTextField.text! {
                    alert.actions.last?.isEnabled = true
                    alert.set(message: "".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                }
            }
        case confirmPassTextField:
            if isOldPassValidated, isNewPassValidated {
                guard let confirmPassLength = confirmPassTextField.text?.count,
                    let newPassLength = newPassTextField.text?.count else {
                        return false
                }
                
                if confirmPassTextField.text! == newPassTextField.text! {
                    alert.actions.last?.isEnabled = true
                    alert.set(message: "".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                } else if confirmPassLength > newPassLength ||
                    (confirmPassLength == newPassLength && confirmPassTextField.text! != newPassTextField.text!) {
                    alert.actions.last?.isEnabled = false
                    alert.set(message: "PWD_NOT_MATCH".localized, font: .systemFont(ofSize: 14), color: UIColor.red)
                } else {
                    alert.actions.last?.isEnabled = false
                }
            }
            
        default:
            break
        }
        
        return false
    }
}
