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

    var errorMessage: String = ""
    private let coreDataStack = Constants.appDelegate.coreDataStack

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }
    }
}

// MARK: - TableView Delegate
extension SettingsGeneralViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            let passChangeCell = tableView.dequeueReusableCell(withIdentifier: GeneralPassTableCell.identifier) as! GeneralPassTableCell
            return passChangeCell
        case IndexPath(row: 1, section: 0):
            let ringtoneCell = tableView.dequeueReusableCell(withIdentifier: GeneralRingtoneTableCell.identifier) as! GeneralRingtoneTableCell
            return ringtoneCell
        case IndexPath(row: 0, section: 1):
            let logoutCell = tableView.dequeueReusableCell(withIdentifier: "GeneralLogoutTableCell")
            return logoutCell!
        default:
            break
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath {
        //Change Password
        case IndexPath(row: 0, section: 0):
            let oldPassTextField = UITextField(frame: .zero)
            let newPassTextField = UITextField(frame: .zero)
            let confirmPassTextField = UITextField(frame: .zero)
            let cell = tableView.cellForRow(at: indexPath) as! GeneralPassTableCell

            let alert = UIAlertController(style: .alert, title: "\(cell.passwordHindLabel.text!) Password")
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
                    Constants.appDelegate.userProfile?.password = newPassTextField.text
                    Constants.appDelegate.userProfile?.passwordSetTime = Date()
                    self.coreDataStack.saveContexts()
                    cell.passwordSetLabel.text = "Last changed: Just now"
                }
            }
            
            alert.addChangePasswordController(oldPassTextField: oldPassTextField, newPassTextField: newPassTextField, confirmPassTextField: confirmPassTextField, alert: alert)
            alert.show {
                if let pass = Constants.appDelegate.userProfile?.password, !pass.isEmpty {
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

                        Defaults[.IsLoggedIn] = false
                        ServiceRequest.shared().disConnectMQTT()
                        self.performSegue(withIdentifier: Constants.UnwindSegues.LOGIN, sender: nil)
                    })
                }.show()
            
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

// MARK: - SingleSelectionDelegate
extension SettingsGeneralViewController: SingleSelectionDelegate {
    func onSelection(_ selectionType: SelectionType) {
        tableView.reloadData()
    }
}

// MARK: - TableCells
class GeneralPassTableCell: UITableViewCell {
    
    @IBOutlet weak var passwordSetLabel: UILabel!
    @IBOutlet weak var passwordHindLabel: UILabel!
    static let identifier = String(describing: GeneralPassTableCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateCell()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        updateCell()
    }
    
    func updateCell() {
        //If password not set
        guard let pass = Constants.appDelegate.userProfile?.password, !pass.isEmpty else {
            passwordSetLabel.text = "Set Password"
            passwordHindLabel.text = "Set"
            return
        }
        
        //If password already set
        var timeSienceLastChanged = "Not changed"
        if let lastChangedPasswordTime = Constants.appDelegate.userProfile?.passwordSetTime {
            timeSienceLastChanged = (Date().offset(from: lastChangedPasswordTime))
        }
        passwordSetLabel.text = "Last changed: \(timeSienceLastChanged)"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class GeneralRingtoneTableCell: UITableViewCell {
    
    @IBOutlet weak var ringtoneSetLabel: UILabel!
    static let identifier = String(describing: GeneralRingtoneTableCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateCell()
    }
        
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        updateCell()
    }
    
    func updateCell() {
        ringtoneSetLabel.text =  Defaults[.isRingtoneSet] ? "iPhone" : "ReachMe"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
