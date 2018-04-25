//
//  ActivateReachMeViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/25/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import Alertift
import SwiftyUserDefaults

class ActivateReachMeViewController: UITableViewController {
    
    var userProfile: Profile? {
        get {
            return CoreDataModel.sharedInstance().getUserProfle()!
        }
    }
    
    var userContact: UserContact!
    var tableCellArray = [Any]()
    var missedCallcount = "0"
    var voicemailCount = "0"
    var incomingCallCount = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Defaults[.IsOnBoarding] {
            navigationItem.setHidesBackButton(true, animated: false)
        }
        
        //let predicate = NSPredicate(format: "isPrimary == %@", NSNumber(value: true))
        // userContact = userProfile?.userContacts?.filtered(using: predicate).first as! UserContact
        if userContact == nil {
            userContact = userProfile?.primaryContact!
        }
        
        if !Defaults[.IsOnBoarding] &&
            (userContact.isReachMeHomeActive || userContact.isReachMeIntlActive || userContact.isReachMeVoiceMailActive) {
            getUsageSummary()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableCellArray.removeAll()
        constructtableCells()
        tableView.reloadData()
    }
    
    func constructtableCells() {
        
        //Title
        if !Defaults[.IsOnBoarding] &&
            (userContact.isReachMeHomeActive || userContact.isReachMeIntlActive || userContact.isReachMeVoiceMailActive) {
            let usageSummaryCell = tableView.dequeueReusableCell(withIdentifier: ActivateReachMeUsageSummaryCell.identifier) as! ActivateReachMeUsageSummaryCell
            if let countryImage = UIImage(data: userContact.countryImageData!) {
                usageSummaryCell.countryImageView.image = countryImage
            }
            usageSummaryCell.numberLabel.text = userContact.formatedNumber
            usageSummaryCell.countryNameLabel.text = userProfile?.countryName
            usageSummaryCell.networkNameLabel.text = "\((userContact.selectedCarrier?.networkName)!)   "
            usageSummaryCell.incomingCallsCountLabel.text = incomingCallCount
            usageSummaryCell.missedCallsCountLabel.text = missedCallcount
            usageSummaryCell.voicemailsCountLabel.text = voicemailCount
            tableCellArray.append(usageSummaryCell)
            
        } else {
            let titleCell = tableView.dequeueReusableCell(withIdentifier: ActivateReachMeTitleCell.identifier) as! ActivateReachMeTitleCell
            if let countryImage = UIImage(data: userContact.countryImageData!) {
                titleCell.countryImageView.image = countryImage
            }
            
            if let titleName = userContact.titleName {
                titleCell.numberLabel.text = titleName
                titleCell.countryNameLabel.text = userContact.formatedNumber
            } else {
                titleCell.numberLabel.text = userContact.formatedNumber
                titleCell.countryNameLabel.text = userProfile?.countryName
            }
            titleCell.networkNameLabel.text = "\((userContact.selectedCarrier?.networkName)!)   "
            tableCellArray.append(titleCell)
        }
        
        if let isReachMeSupport = userContact.selectedCarrier?.isReachMeSupport, isReachMeSupport == true {
            
            let selectModeCell = tableView.dequeueReusableCell(withIdentifier: "ActivateReachMeSelectModeCell")
            tableCellArray.append(selectModeCell as Any)
            
            //ReachMe Intl
            if ((userContact.voiceMailInfo?.rmIntl)! && (userContact.voiceMailInfo?.rmHome)!) {
                
                let reachMeIntlCell = tableView.dequeueReusableCell(withIdentifier: ActivateReachMeIntlCell.identifier) as! ActivateReachMeIntlCell
                
                if userContact.isReachMeIntlActive {
                    reachMeIntlCell.statusLabel.text = "Active"
                    reachMeIntlCell.statusLabel.isHidden = false
                    reachMeIntlCell.statusLabel.backgroundColor = UIColor(red: 0, green: 151, blue: 137)
                } else {
                    reachMeIntlCell.statusLabel.text = "Activate"
                    reachMeIntlCell.statusLabel.backgroundColor = UIColor.ReachMeColor()
                }
                
                if userContact.isReachMeHomeActive {
                    reachMeIntlCell.statusLabel.isHidden = true
                }
                
                tableCellArray.append(reachMeIntlCell)
            }
            
            //ReachMe Home
            if ((userContact.voiceMailInfo?.rmIntl)! && (userContact.voiceMailInfo?.rmHome)!) {
                
                let reachMeHomeCell = tableView.dequeueReusableCell(withIdentifier: ActivateReachMeHomeCell.identifier) as! ActivateReachMeHomeCell
                
                if userContact.isReachMeHomeActive {
                    reachMeHomeCell.statusLabel.text = "Active"
                    reachMeHomeCell.statusLabel.isHidden = false
                    reachMeHomeCell.statusLabel.backgroundColor = UIColor(red: 0, green: 151, blue: 137)
                } else {
                    reachMeHomeCell.statusLabel.text = "Activate"
                    reachMeHomeCell.statusLabel.backgroundColor = UIColor.ReachMeColor()
                }
                
                if userContact.isReachMeIntlActive {
                    reachMeHomeCell.statusLabel.isHidden = true
                }
                tableCellArray.append(reachMeHomeCell)
            }
            
            //Info
            let infoCell = tableView.dequeueReusableCell(withIdentifier: ActivateReachMeInfoCell.identifier) as! ActivateReachMeInfoCell
            tableCellArray.append(infoCell)
            
            //Request Support
            if Defaults[.IsOnBoarding] {
                let requestSupportCell = tableView.dequeueReusableCell(withIdentifier: ActivateReachMeRequestSupportCell.identifier) as! ActivateReachMeRequestSupportCell
                requestSupportCell.button.addTarget(self, action: #selector(onRequestSupportClicked(sender:)), for: .touchUpInside)
                tableCellArray.append(requestSupportCell)
            }
            
        } else {//ReachMe not supporting
            //Error
            let reachMeErrorCell = tableView.dequeueReusableCell(withIdentifier: ActivateReachMeErrorCell.identifier) as! ActivateReachMeErrorCell
            if (userContact.voiceMailInfo?.countryVoicemailSupport)! {
                reachMeErrorCell.titleLabel.text = "InstaVoice ReachMe is not available with \(userContact.selectedCarrier?.networkName ?? "Current Network") at present."
                reachMeErrorCell.descriptionLabel.text = "We are working hard to make it available for every carrier in the world, you can help us prioritise \(userContact.selectedCarrier?.networkName ?? "Current Network") by requesting support below."
            } else {
                reachMeErrorCell.titleLabel.text = "InstaVoice ReachMe is not available with \(userContact.countryCode!) Country at present."
                reachMeErrorCell.descriptionLabel.text = "We are working hard to make it available for every carrier in the world, you can help us prioritise \(userContact.countryCode!) Country by requesting support below."
            }
            tableCellArray.append(reachMeErrorCell)
            
            //Finish button
            if Defaults[.IsOnBoarding] {
                let finishCell = tableView.dequeueReusableCell(withIdentifier: ActivateReachMeFinishCell.identifier) as! ActivateReachMeFinishCell
                tableCellArray.append(finishCell)
            }
            
        }
        
        //Unlink Number
        if !userContact.isPrimary {
            let unlinkCell = tableView.dequeueReusableCell(withIdentifier: ActivateReachMeUnlinkNumberCell.identifier) as! ActivateReachMeUnlinkNumberCell
            unlinkCell.button.addTarget(self, action: #selector(onUnlinkClicked(sender:)), for: .touchUpInside)
            tableCellArray.append(unlinkCell)
        }
    }
    
    func getUsageSummary() {
        guard RMUtility.isNetwork() else {
            RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
            return
        }
        
        ANLoader.showLoading("", disableUI: true)
        ServiceRequest.shared().startRequestForUsageSummary(forPhoneNumber: userContact.contactID!) { (responseDisc, success) in
            ANLoader.hide()
            guard success else { return }
            
            if let summary = responseDisc?["summary"] as? [[String: Any]], summary.count > 0 {
                var selectedSummary: [String: Any]!
                if summary.first!["msg_flow"] as! String == "r" {
                    selectedSummary = summary.first!
                } else if summary.count > 1 {
                    selectedSummary = summary[1]
                }
                
                self.missedCallcount = "\(selectedSummary["mca_count"]!)"
                self.voicemailCount = "\(selectedSummary["vsms_count"]!)"
                self.incomingCallCount = "\(selectedSummary["reachme_count"]!)"
                self.tableCellArray.removeAll()
                self.constructtableCells()
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Button Actions
    @IBAction func onHelpClicked(_ sender: UIButton) {
        RMUtility.handleHelpSupportAction(withHelpText: nil)
    }
    
    @objc func onUnlinkClicked(sender: UIButton) {
        RMUtility.unlinkForNumber(number: userContact.contactID!) { (success) in
            guard success else { return }
            
            //Delete from local DB
            ANLoader.hide()
            CoreDataModel.sharedInstance().deleteRecord(self.userContact)
            CoreDataModel.sharedInstance().saveContext()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func onRequestSupportClicked(sender: UIButton) {
        RMUtility.handleHelpSupportAction(withHelpText: nil)
    }
    
    // MARK: - Segue Actions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let reachMeType = sender as? RMUtility.ReachMeType {
            
            if segue.identifier == Constants.Segues.HOWTO_ACTIVAE_REACHME {
                let destVC = segue.destination as! HowToActivateReachMeViewController
                destVC.userContact = userContact
                destVC.reachMeType = reachMeType
                
            } else if segue.identifier == Constants.Segues.ACTIVATED {
                let destVC = segue.destination as! ActivatedReachMeViewController
                destVC.userContact = userContact
                destVC.reachMeType = reachMeType
            }
            
        } else if segue.identifier == Constants.Segues.EDIT_DETAILS {
            let destVC = segue.destination as! EditNumberViewController
            destVC.userContact = userContact
        }
        
    }
    
    // MARK: - Unwind Action
    @IBAction func unwindToActivateReachMeControllre(segue: UIStoryboardSegue) {}
    
}

// MARK: - TableView Delegate & Datasource
extension ActivateReachMeViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableCellArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableCellArray[indexPath.row] as! UITableViewCell
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (indexPath.row == 3) && userContact.isReachMeIntlActive {
            
            Alertift.alert(title: "Are you back to \(userContact.countryName!)",
                message: "If you switch to ReachMe Home when you are outside the home country, International roaming charges will be applicable. Do you want to continue?")
                .action(.default("Cancel"))
                .action(.default("Continue")) { (action, count, nil) in
                    self.performSegue(withIdentifier: Constants.Segues.HOWTO_ACTIVAE_REACHME, sender: RMUtility.ReachMeType.home)
                }.show()
            return
        }
        
        let homeCell = tableView.cellForRow(at: indexPath) as? ActivateReachMeHomeCell
        let intlCell = tableView.cellForRow(at: indexPath) as? ActivateReachMeIntlCell
        let voiceMailCell = tableView.cellForRow(at: indexPath) as? ActivateReachMeVoiceMailCell
        
        guard ((homeCell != nil) || (intlCell != nil) || (voiceMailCell != nil)) else {
            return
        }
        
        if homeCell?.statusLabel.text == "Active" || intlCell?.statusLabel.text == "Active" || voiceMailCell?.statusLabel.text == "Active" {
            if userContact.isReachMeHomeActive {
                performSegue(withIdentifier: Constants.Segues.ACTIVATED, sender: RMUtility.ReachMeType.home)
            } else if userContact.isReachMeIntlActive {
                performSegue(withIdentifier: Constants.Segues.ACTIVATED, sender: RMUtility.ReachMeType.international)
            } else {
                performSegue(withIdentifier: Constants.Segues.ACTIVATED, sender: RMUtility.ReachMeType.voicemail)
            }
        } else {
            if (homeCell != nil) {
                performSegue(withIdentifier: Constants.Segues.HOWTO_ACTIVAE_REACHME, sender: RMUtility.ReachMeType.home)
            } else if (intlCell != nil) {
                performSegue(withIdentifier: Constants.Segues.HOWTO_ACTIVAE_REACHME, sender: RMUtility.ReachMeType.international)
            } else {
                performSegue(withIdentifier: Constants.Segues.HOWTO_ACTIVAE_REACHME, sender: RMUtility.ReachMeType.voicemail)
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
}
