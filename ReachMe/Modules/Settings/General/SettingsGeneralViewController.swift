//
//  SettingsGeneralViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/19/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Alertift

class SettingsGeneralViewController: UITableViewController {

    var userProfile: Profile? {
        get {
            return CoreDataModel.sharedInstance().getUserProfle()!
        }
    }
    @IBOutlet weak var passwordSetLabel: UILabel!
    @IBOutlet weak var passwordHindLabel: UILabel!
    @IBOutlet weak var ringtoneSetLabel: UILabel!
    var errorMessage: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ringtoneSetLabel.text =  Defaults[.isRingtoneSet] ? "iPhone" : "ReachMe"

        //If password not set
        guard let pass = userProfile?.password, !pass.isEmpty else {
            passwordSetLabel.text = "Set Password"
            passwordHindLabel.text = "Set"
            return
        }
        
        //If password already set
        var timeSienceLastChanged = "Not changed"
        if let lastChangedPasswordTime = userProfile?.passwordSetTime {
            timeSienceLastChanged = (Date().offset(from: lastChangedPasswordTime))
        }
        passwordSetLabel.text = "Last changed: \(timeSienceLastChanged)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

// MARK: - TableView Delegate
extension SettingsGeneralViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath {
        //Change Password
        case IndexPath(row: 0, section: 0):
            let oldPassTextField = UITextField(frame: .zero)
            let newPassTextField = UITextField(frame: .zero)
            let confirmPassTextField = UITextField(frame: .zero)
            
            let alert = UIAlertController(style: .alert, title: "\(passwordHindLabel.text!) Password")
            alert.set(message: self.errorMessage, font: .systemFont(ofSize: 14), color: .red)
            alert.addAction(title: "Cancel", style: .default)
            alert.addAction(title: "Confirm", style: .default, isEnabled: false) { (alertAction) in
                print("old = \(oldPassTextField.text!)")
                print("new = \(newPassTextField.text!)")
                print("confirm = \(confirmPassTextField.text!)")
                
                guard RMUtility.isNetwork() else {
                    RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                    return
                }
                
                ANLoader.showLoading("", disableUI: true)
                var params: [String: Any] = ["cmd": Constants.ApiCommands.UPDATE_PROFILE_INFO,
                                             "pwd": newPassTextField.text!]
                ServiceRequest.shared().startRequestForUpdateProfileInfo(withProfileInfo: &params) { (success) in
                    ANLoader.hide()
                    guard success else {
                        //Not sure to show again chage password alert on failure
                      /*  DispatchQueue.main.async {
                            self.tableView((self.tableView)!, didSelectRowAt: IndexPath(row: 0, section: 0))
                        }*/
                        return
                    }
                    
                    RMUtility.showAlert(withMessage: "PWD_CHANGED".localized)
                    self.userProfile?.password = newPassTextField.text
                    self.userProfile?.passwordSetTime = Date()
                    CoreDataModel.sharedInstance().saveContext()
                    self.passwordSetLabel.text = "Last changed: Just now"
                }
            }
            
            alert.addChangePasswordController(oldPassTextField: oldPassTextField, newPassTextField: newPassTextField, confirmPassTextField: confirmPassTextField, alert: alert)
            alert.show {
                if let pass = self.userProfile?.password, !pass.isEmpty {
                    oldPassTextField.becomeFirstResponder()
                } else {
                    newPassTextField.becomeFirstResponder()
                }
            }
            
        //Ringtone
        case IndexPath(row: 1, section: 0):
            let ringToneVC = SingleSelectionTableViewController(with: .ringTone)
            ringToneVC.delegate = self
            navigationController?.pushViewController(ringToneVC, animated: true)
            
        //Logout
        case IndexPath(row: 0, section: 1):
            Alertift.alert(title: "Logout?",
                           message: "You will no longer receive data calls for numbers linked in the account. Are you sure you want to log out?")
                .action(.default("Cancel"))
                .action(.default("OK")) { (action, count, nil) in

                    ANLoader.showLoading("", disableUI: true)
                    ServiceRequest.shared().startRequestForSignOut(completionHandler: { (success) in
                        let loginVC = UIViewController.loginViewController()
                        self.navigationController?.viewControllers.insert(loginVC, at: 0)

                        ANLoader.hide()
                        guard success else { return }

                        Defaults[.IsLoggedInKey] = false
                        ServiceRequest.shared().disConnectMQTT()
                        self.performSegue(withIdentifier: Constants.UnwindSegues.LOGIN, sender: nil)
                    })
                }.show()
            
        default:
            break
        }
    }
}

// MARK: - SingleSelectionDelegate
extension SettingsGeneralViewController: SingleSelectionDelegate {
    func onSelection(_ selectionType: SelectionType) {
        switch selectionType {
        case .ringTone:
            ringtoneSetLabel.text =  Defaults[.isRingtoneSet] ? "iPhone" : "ReachMe"
            
        case .notificationTone:
            break
        }
    }
}
