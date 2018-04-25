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

    var storeProductViewController = SKStoreProductViewController()
    var tableCellArray = [[Any]]()
    var userProfile: Profile? {
        get {
            return CoreDataModel.sharedInstance().getUserProfle()!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        storeProductViewController.delegate = self

        let headerCell = tableView.dequeueReusableCell(withIdentifier: SettingsProfileHeaderCell.identifier) as! SettingsProfileHeaderCell
        tableView.tableHeaderView = headerCell
        
        constructtableCells()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        } else {
            // Fallback on earlier versions
        }
        
        ServiceRequest.shared().startRequestForGetProfileInfo(completionHandler: { (success) in
            guard success else { return }
            ServiceRequest.shared().startRequestForFetchSettings(completionHandler: { (success) in
                guard success else { return }
                CoreDataModel.sharedInstance().saveContext()
                self.constructtableCells()
                self.tableView.reloadData()
            })
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
   
    func constructtableCells() {
        tableCellArray.removeAll()
        
        //Profile
        let editProfileCell = tableView.dequeueReusableCell(withIdentifier: "SettingsProfileEditCell")
        editProfileCell?.detailTextLabel?.text = userProfile?.primaryContact?.countryName
        tableCellArray.append([editProfileCell as Any])

//        let profileCell = tableView.dequeueReusableCell(withIdentifier: SettingsProfileCell.identifier) as! SettingsProfileCell
//        tableCellArray.append([profileCell])
        
        //PrimaryNumber
        let primaryNumberCell = tableView.dequeueReusableCell(withIdentifier: SettingsPrimaryNumberCell.identifier) as! SettingsPrimaryNumberCell
        if let countryImage = UIImage(data: (userProfile?.primaryContact?.countryImageData)!) {
            primaryNumberCell.countryImageView.image = countryImage
        }
        primaryNumberCell.titleLabel.text = userProfile?.primaryContact?.formatedNumber
        primaryNumberCell.subtitleLabel.text = userProfile?.primaryContact?.selectedCarrier?.networkName
        tableCellArray.append([primaryNumberCell])
        
        //LinkedNumber
        let linkedNumbersCell = tableView.dequeueReusableCell(withIdentifier: "SettingsLinkedNumbersCell")
        let numberCount = NSMutableAttributedString(string: "\(((userProfile?.userContacts?.count)! - 1))")
        let combination = NSMutableAttributedString()
        combination.append(numberCount)
        let extraString = NSMutableAttributedString(string: "------------------------")//To create space temporary adding few charachters
        extraString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: 24))
        combination.append(extraString)
        linkedNumbersCell?.detailTextLabel?.attributedText = combination
        tableCellArray.append([linkedNumbersCell as Any])
        
        //Last Section
        var lastSectionArray = [Any]()
        //Voicemail
        let voiceMailCell = tableView.dequeueReusableCell(withIdentifier: "SettingsVoicemailCell")
        lastSectionArray.append(voiceMailCell as Any)
        //Email Notification
        let emailNotificationCell = tableView.dequeueReusableCell(withIdentifier: "SettingsEmailNotfiCell")
        lastSectionArray.append(emailNotificationCell as Any)
        //Redeem
        let redeemCell = tableView.dequeueReusableCell(withIdentifier: "SettingsRedeemCell")
        lastSectionArray.append(redeemCell as Any)
        //General
        let generalCell = tableView.dequeueReusableCell(withIdentifier: "SettingsGeneralCell")
        lastSectionArray.append(generalCell as Any)
        //Carrier Logo Support
        if userProfile?.primaryContact?.selectedCarrier?.logoSupportURL != nil {
            let carrierSupportCell = tableView.dequeueReusableCell(withIdentifier: SettingsCarrierLogoSupportCell.identifier) as! SettingsCarrierLogoSupportCell
            carrierSupportCell.titleLabel.text = "\((userProfile?.primaryContact?.selectedCarrier?.networkName)!) Carrier Support"
            lastSectionArray.append(carrierSupportCell)
        }
        
        //Version
        let versionCell = tableView.dequeueReusableCell(withIdentifier: "SettingsVersionCell")
        versionCell?.textLabel?.text = "ReachMe \(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!) (\(Bundle.main.infoDictionary!["CFBundleVersion"]!))"
        //let appID = Bundle.main.infoDictionary!["CFBundleIdentifier"]! NOTE: Unblock this after all done
        let appID = "com.kirusa.ReachMe"
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
        
        let parametersDict = [SKStoreProductParameterITunesItemIdentifier: 1345352747]
        storeProductViewController.loadProduct(withParameters: parametersDict, completionBlock: { (status: Bool, error: Error?) -> Void in
            if status {
                self.present(self.storeProductViewController, animated: true, completion: nil)
            } else {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
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
            
            guard let contactCount = userProfile?.userContacts?.count, contactCount > 1  else {
                tableCellArray[2].append(newLinkCell as Any)
                tableView.insertRows(at: [IndexPath.init(row: 1, section: 2)], with: .fade)
                return
            }
            
            let changePrimaryCell = tableView.dequeueReusableCell(withIdentifier: "SettingsChangePrimaryCell")
            tableCellArray.insert([changePrimaryCell as Any], at: 2)
            tableView.insertSections(IndexSet(integer: 2), with: .fade)
            
            var numberRowCount = 1
            (userProfile?.userContacts?.allObjects as? [UserContact])?.forEach({ userContact in
                if !userContact.isPrimary {
                    let numberCell = tableView.dequeueReusableCell(withIdentifier: "SettingsSecondaryNumberCell")
                    numberCell?.textLabel?.text = userContact.formatedNumber
                    numberCell?.detailTextLabel?.text = userContact.selectedCarrier?.networkName
                    if let countryImage = UIImage(data: userContact.countryImageData!) {
                        numberCell?.imageView?.image = countryImage
                    }
                    tableCellArray[3].append(numberCell as Any)
                    tableView.insertRows(at: [IndexPath.init(row: numberRowCount, section: 3)], with: .fade)
                    numberRowCount += 1
                }
            })
            
            tableCellArray[3].append(newLinkCell as Any)
            tableView.insertRows(at: [IndexPath.init(row: numberRowCount, section: 3)], with: .fade)
            
        } else if tableCell?.tag == 2 {
            tableCell?.tag = 1 // Close state
            (tableCell?.accessoryView as! UIImageView).image = #imageLiteral(resourceName: "down_arrow_settings")

            guard let contactCount = userProfile?.userContacts?.count, contactCount > 1  else {
                tableCellArray[2].remove(at: 1)//Remove New Link if no secendary numbers
                tableView.deleteRows(at: [IndexPath.init(row: 1, section: 2)], with: .fade)
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
                    .action(.default("\((self.userProfile?.primaryContact?.formatedNumber)!)"))
                alertFit.alertController.setTitleFont(font: .boldSystemFont(ofSize: 18))
                
                (self.userProfile?.userContacts?.allObjects as? [UserContact])?.forEach({ userContact in
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
                                for contact in (self.userProfile?.userContacts?.allObjects as? [UserContact])! where contact.isPrimary == true {
                                        contact.isPrimary = false
                                        break
                                }
                                
                                //Update selected Contact to true
                                userContact.isPrimary = true
                                self.userProfile?.primaryContact = userContact
                                
                                CoreDataModel.sharedInstance().saveContext()
                                
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
            guard let contactCounts = userProfile?.userContacts?.count, contactCounts <= 11 else {
                RMUtility.showAlert(withMessage: "Limit Exceeded! Only 10 verified numbers can be linked to account")
                return
            }
            
            guard RMUtility.isNetwork() else {
                RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                return
            }
            
        } else if tableCell?.tag == 5 { //Secondary Number
            let predicate = NSPredicate(format: "formatedNumber == %@", (tableCell?.textLabel?.text)!)
            let userContact = userProfile?.userContacts?.filtered(using: predicate).first as! UserContact
            if  userContact.selectedCarrier == nil && (userContact.voiceMailInfo?.countryVoicemailSupport)! {
                performSegue(withIdentifier: Constants.Segues.CARRIERLIST, sender: nil)
                return
            }
            performSegue(withIdentifier: Constants.Segues.ACTIVATE_REACHME, sender: userContact)
            
        } else if tableCell?.tag == 6 { //Primary Number
            performSegue(withIdentifier: Constants.Segues.ACTIVATE_REACHME, sender: nil)
            
        } else if tableCell?.tag == 7 { //Carrier Support
            guard let url = URL(string: "\((userProfile?.primaryContact?.selectedCarrier?.logoSupportURL)!)") else { return }
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
}

extension SettingsViewController: SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
