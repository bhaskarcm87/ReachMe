//
//  SettingsViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/16/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import Alertift
import StoreKit

class SettingsViewController: UITableViewController {

    lazy var storeProductViewController: SKStoreProductViewController = {
        $0.delegate = self
        return $0
    }(SKStoreProductViewController())
    private let coreDataStack = Constants.appDelegate.coreDataStack
    var tableCellArray = [[Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        constructtableCells()
    
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)

        ServiceRequest.shared().startRequestForGetProfileInfo(completionHandler: { (success) in
            guard success else { return }
            ServiceRequest.shared().startRequestForFetchSettings(completionHandler: { (success) in
                guard success else { return }
                self.constructtableCells()
                self.tableView.reloadData()
            })
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            self.constructtableCells()
            self.tableView.reloadData()
        }
    }

    func constructtableCells() {
        tableCellArray.removeAll()
        
        //Profile
        let profileCell = tableView.dequeueReusableCell(withIdentifier: SettingsProfileCell.identifier) as! SettingsProfileCell
        tableCellArray.append([profileCell])
        
        //PrimaryNumber
        let primaryNumberCell = tableView.dequeueReusableCell(withIdentifier: SettingsPrimaryNumberCell.identifier) as! SettingsPrimaryNumberCell
        tableCellArray.append([primaryNumberCell])
        
        //LinkedNumber
        let linkedNumbersCell = tableView.dequeueReusableCell(withIdentifier: "SettingsLinkedNumbersCell")
        linkedNumbersCell?.tag = 1 // Close state
        let numberCount = NSMutableAttributedString(string: "\(((Constants.appDelegate.userProfile?.userContacts?.count)! - 1))")
        let combination = NSMutableAttributedString()
        combination.append(numberCount)
        let extraString = NSMutableAttributedString(string: "------------------------")//To create space temporary adding few charachters
        extraString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: 24))
        combination.append(extraString)
        linkedNumbersCell?.detailTextLabel?.attributedText = combination
        linkedNumbersCell?.textLabel?.text = "Linked Numbers"
        tableCellArray.append([linkedNumbersCell as Any])
        
        //Last Section
        var lastSectionArray = [Any]()
        //Voicemail
        let voiceMailCell = tableView.dequeueReusableCell(withIdentifier: "SettingsVoicemailCell")
        voiceMailCell?.textLabel?.text = "Voicemail Greetings"
        voiceMailCell?.detailTextLabel?.text = "Welcome messages"
        lastSectionArray.append(voiceMailCell as Any)

        //Email Notification
        let emailNotificationCell = tableView.dequeueReusableCell(withIdentifier: "SettingsEmailNotfiCell")
        emailNotificationCell?.textLabel?.text = "Email Notifications"
        emailNotificationCell?.detailTextLabel?.text = "Receive Voicemail & Missed Call Alerts"
        lastSectionArray.append(emailNotificationCell as Any)
        //Redeem
        let redeemCell = tableView.dequeueReusableCell(withIdentifier: "SettingsRedeemCell")
        redeemCell?.textLabel?.text = "Redeem Code"
        redeemCell?.detailTextLabel?.text = "Invite codes, Promo codes"
        lastSectionArray.append(redeemCell as Any)
        //General
        let generalCell = tableView.dequeueReusableCell(withIdentifier: "SettingsGeneralCell")
        generalCell?.textLabel?.text = "General"
        generalCell?.detailTextLabel?.text = "Password & Ringtone"
        lastSectionArray.append(generalCell as Any)
        //Carrier Logo Support
        if Constants.appDelegate.userProfile?.primaryContact?.selectedCarrier?.logoSupportURL != nil {
            let carrierSupportCell = tableView.dequeueReusableCell(withIdentifier: SettingsCarrierLogoSupportCell.identifier) as! SettingsCarrierLogoSupportCell
            carrierSupportCell.titleLabel.customFontTextStyle = "Body"
            lastSectionArray.append(carrierSupportCell)
        }
        
        //Version
        let versionCell = tableView.dequeueReusableCell(withIdentifier: "SettingsVersionCell")
        versionCell?.textLabel?.text = "ReachMe \(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!) (\(Bundle.main.infoDictionary!["CFBundleVersion"]!))"
        let appID = Bundle.main.infoDictionary!["CFBundleIdentifier"]!
        let ituneURL = URL(string: "http://itunes.apple.com/lookup?bundleId=\(appID)")!
        do {
            let data = try Data.init(contentsOf: ituneURL)
            let result = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String: Any]
            if (result["resultCount"] as! Int) == 1 {
                let appstoreVersion = ((result["results"] as! [Any]).first as! [String: Any])["version"] as! String
                let currentVersion = "\(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!).\(Bundle.main.infoDictionary!["CFBundleVersion"]!)"
                if appstoreVersion == currentVersion {
                    versionCell?.accessoryView = nil
                }
            }
        } catch { print("Generic parser error") }

        lastSectionArray.append(versionCell as Any)
        tableCellArray.append(lastSectionArray)

    }
    
    //Button Actions
    @IBAction func onUpdateButtonClicked(_ sender: UIButton) {
       // guard let url = URL(string: "https://itunes.apple.com/us/app/instavoice-reachme/id1345352747?mt=8") else { return }
       // UIApplication.shared.open(url, options: [:], completionHandler: nil)
        
        ANLoader.showLoading(" ", disableUI: true)
        let parametersDict = [SKStoreProductParameterITunesItemIdentifier: 1345352747]
        storeProductViewController.loadProduct(withParameters: parametersDict, completionBlock: { (status: Bool, error: Error?) -> Void in
            ANLoader.hide()
            if status {
                self.present(self.storeProductViewController, animated: true, completion: nil)
            } else {
                if let error = error {
                    RMUtility.showAlert(withMessage: error.localizedDescription)
            }}})
    }
    
    // MARK: - Segue Actions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let userContact = sender as? UserContact, segue.identifier == Constants.Segues.ACTIVATE_REACHME {
            let destVC = segue.destination as! ActivateReachMeViewController
            destVC.userContact = userContact
        }
    }
    
}

// MARK: - TableView Delegate & Datasource
extension SettingsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableCellArray.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableCellArray[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableCellArray[indexPath.section][indexPath.row] as! UITableViewCell
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                
        let tableCell = tableView.cellForRow(at: indexPath)
        guard tableCell?.tag != 0 else { return }

        if tableCell?.tag == 1 {
            tableCell?.tag = 2 // Expand state
            (tableCell?.accessoryView as! UIImageView).image = #imageLiteral(resourceName: "settings_up_arrow")

            let newLinkCell = tableView.dequeueReusableCell(withIdentifier: "SettingsLinkNewCell")
            newLinkCell?.textLabel?.text = "Link New"
            
            guard let contactCount = Constants.appDelegate.userProfile?.userContacts?.count, contactCount > 1  else {
                tableCellArray[2].append(newLinkCell as Any)
                tableView.insertRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
                return
            }
            
            let changePrimaryCell = tableView.dequeueReusableCell(withIdentifier: "SettingsChangePrimaryCell")
            tableCellArray.insert([changePrimaryCell as Any], at: 2)
            tableView.insertSections(IndexSet(integer: 2), with: .fade)
            
            var numberRowCount = 1
            (Constants.appDelegate.userProfile?.userContacts?.allObjects as? [UserContact])?.forEach({ userContact in
                if !userContact.isPrimary {
                    let numberCell = tableView.dequeueReusableCell(withIdentifier: "SettingsSecondaryNumberCell")
                    numberCell?.textLabel?.text = userContact.formatedNumber
                    numberCell?.detailTextLabel?.text = userContact.selectedCarrier?.networkName
                    if let countryImage = UIImage(data: userContact.countryImageData!) {
                        numberCell?.imageView?.image = countryImage
                    }
                    tableCellArray[3].append(numberCell as Any)
                    tableView.insertRows(at: [IndexPath(row: numberRowCount, section: 3)], with: .fade)
                    numberRowCount += 1
                }
            })
            
            tableCellArray[3].append(newLinkCell as Any)
            tableView.insertRows(at: [IndexPath(row: numberRowCount, section: 3)], with: .fade)
            
        } else if tableCell?.tag == 2 {
            tableCell?.tag = 1 // Close state
            (tableCell?.accessoryView as! UIImageView).image = #imageLiteral(resourceName: "down_arrow_settings")

            guard let contactCount = Constants.appDelegate.userProfile?.userContacts?.count, contactCount > 1  else {
                tableCellArray[2].remove(at: 1)//Remove New Link if no secendary numbers
                tableView.deleteRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
                return
            }
            ////
            //Remove Lined number section rows except first one
            var indepathList = [IndexPath]()
            let linkedSectionrowCount = tableCellArray[3].count
            for index in 1..<linkedSectionrowCount {
                indepathList.append(IndexPath(row: index, section: 3))
                tableCellArray[3].removeLast()
            }
            tableView.deleteRows(at: indepathList, with: .fade)
            
            //Remove Change Primary
            tableCellArray.remove(at: 2)
            tableView.deleteSections(IndexSet(integer: 2), with: .fade)
            
        } else if tableCell?.tag == 3 {//Change Primary Number
            
            DispatchQueue.main.async { //Using main queue otherwise Actionsheet showing in delay
                let alertFit = Alertift.actionSheet(title: "Change Primary Number", message: "Primary Number is your USER ID to access ReachMe on all your devices. ")
                    .action(.default("\((Constants.appDelegate.userProfile?.primaryContact?.formatedNumber)!)"))
                alertFit.alertController.setTitleFont(font: .boldSystemFont(ofSize: 18))
                
                (Constants.appDelegate.userProfile?.userContacts?.allObjects as? [UserContact])?.forEach({ userContact in
                    if !userContact.isPrimary {
                        _ = alertFit.action(.default("\((userContact.formatedNumber)!)")) { action, index in
                            
                            guard RMUtility.isNetwork() else {
                                RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                                return
                            }
                            
                            var params: [String: Any] = ["cmd": Constants.ApiCommands.MANAGE_USER_CONTACT,
                                                         "contact": userContact.contactID!,
                                                         "contact_type": "p",
                                                         "operation": "u",
                                                         "set_as_primary": true]
                            
                            ANLoader.showLoading("", disableUI: true)
                            ServiceRequest.shared().startRequestForManageUserContact(withManagedInfo: &params) { (responseDics, success) in
                                ANLoader.hide()
                                guard success else { return }
                                
                                //Change existing primary contact to false
                                for contact in (Constants.appDelegate.userProfile?.userContacts?.allObjects as? [UserContact])! where contact.isPrimary == true {
                                        contact.isPrimary = false
                                        break
                                }
                                
                                //Update selected Contact to true
                                userContact.isPrimary = true
                                Constants.appDelegate.userProfile?.primaryContact = userContact
                                
                                self.coreDataStack.saveContexts()
                                
                                DispatchQueue.main.async {
                                    //Close expanding state of tableview
                                    self.tableView.selectRow(at: IndexPath(row: 0, section: 3), animated: true, scrollPosition: .none)
                                    self.tableView.delegate?.tableView!(self.tableView, didSelectRowAt: IndexPath(row: 0, section: 3))
                                    
                                    RMUtility.showAlert(withMessage: "Setting Saved")
                                    
                                    //Reload view
                                    self.tableCellArray.removeAll()
                                    self.constructtableCells()
                                    self.tableView.reloadData()
                                }
                                
                            }
                        }
                    }
                })
                for (index, action) in alertFit.alertController.actions.enumerated() {
                    if index == 0 {
                        action.setValue(true, forKey: "checked")
                    } else {
                        action.setValue(UIColor.black, forKey: "titleTextColor")
                    }
                }
                _ = alertFit.action(.cancel("Cancel"))
                alertFit.show()
            }
            
        } else if tableCell?.tag == 4 {//Link New
            guard let contactCounts = Constants.appDelegate.userProfile?.userContacts?.count, contactCounts <= 11 else {
                RMUtility.showAlert(withMessage: "Limit Exceeded! Only 10 verified numbers can be linked to account")
                return
            }
            
            guard RMUtility.isNetwork() else {
                RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                return
            }
            
        } else if tableCell?.tag == 5 { //Secondary Number
            let predicate = NSPredicate(format: "formatedNumber == %@", (tableCell?.textLabel?.text)!)
            let userContact = Constants.appDelegate.userProfile?.userContacts?.filtered(using: predicate).first as! UserContact
            if  userContact.selectedCarrier == nil && (userContact.voiceMailInfo?.countryVoicemailSupport)! {
                performSegue(withIdentifier: Constants.Segues.CARRIERLIST, sender: nil)
                return
            }
            performSegue(withIdentifier: Constants.Segues.ACTIVATE_REACHME, sender: userContact)
            
        } else if tableCell?.tag == 6 { //Primary Number
            performSegue(withIdentifier: Constants.Segues.ACTIVATE_REACHME, sender: nil)
            
        } else if tableCell?.tag == 7 { //Carrier Support
            guard let url = URL(string: "\((Constants.appDelegate.userProfile?.primaryContact?.selectedCarrier?.logoSupportURL)!)") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
 
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "PRIMARY NUMBER"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return "Primary Number is your USER ID to access ReachMe on all your devices."
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

}

extension SettingsViewController: SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
