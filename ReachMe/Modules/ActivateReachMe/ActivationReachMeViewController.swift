//
//  ActivationReachMeViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/12/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Alertift

enum ActivationType: String {
    case activate = "activate"
    case deactivate = "deactivate"
}

class ActivationReachMeViewController: UITableViewController {
    
    var reachMeType: RMUtility.ReachMeType!
    var userContact: UserContact!
    var activationType: ActivationType!
    var dialCodeArray: [String]!
    var tableCellArray = [Any]()
    var infoceCellDetailLabel: UILabel!
    var helpText: String!
    private let coreDataStack = Constants.appDelegate.coreDataStack

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var dialCode: String!
        switch activationType {
        case .activate:
            if reachMeType == RMUtility.ReachMeType.international {
                dialCode = userContact.voiceMailInfo!.actiUNCF
            } else if userContact.isReachMeIntlActive {
                dialCode = userContact.voiceMailInfo!.deactiUNCF
            } else {
                dialCode = userContact.voiceMailInfo!.actiCNF
            }
            
        case .deactivate:
            dialCode = (reachMeType == RMUtility.ReachMeType.international) ? userContact.voiceMailInfo!.deactiBoth : userContact.voiceMailInfo!.deactiCNF
        default:
            break
        }
        dialCodeArray = dialCode.components(separatedBy: ";")
        
        helpText = "I'm having problems in \(activationType.rawValue) ReachMe Service. My carrier is \((userContact.selectedCarrier?.networkName)!) and the \(activationType.rawValue) number is \(dialCode.replacingOccurrences(of: ";", with: "\n")))"
        
        constructtableCells()
        
        //Handle Dial Confirmation
        if activationType == ActivationType.activate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                
                let alert = UIAlertController(style: .alert, title: "Did You dial the code below?")
                alert.set(message: "\n \(dialCode.replacingOccurrences(of: ";", with: "\n"))", font: .systemFont(ofSize: 20), color: UIColor.ReachMeColor())
                alert.addAction(title: "NO", style: .default)
                alert.addAction(title: "YES", style: .default) { (alertAction) in
                    
                    var alertTitle: String!
                    var alertMessage: String!
                    if dialCode.contains("#") {
                        alertTitle = "Did you see a positive response after dialing?"
                        alertMessage = "When you dial the code which is a USSD command, your carrier sends a response that pops up after the code is successfully dialed. It usually says “Successful”, “Active”, or “Activated”, indicating that command was successful."
                    } else {
                        alertTitle = "Did you hear a positive response after dialing?"
                        alertMessage = "When you dial the call forwarding number, You will hear a positive confirmation that says “Successful”, “Active”, or “Activated”, indicating that command was successful."
                    }
                    
                    let alert = UIAlertController(style: .alert, title: alertTitle)
                    alert.set(message: alertMessage, font: .systemFont(ofSize: 13), color: UIColor.init(red: 3, green: 3, blue: 3))
                    alert.addAction(title: "NO", style: .default) { (alertAction) in
                        
                        //handle failurecase
                        let alert = UIAlertController(style: .alert, title: "Contact Support")
                        alert.set(message: "\n We believe there may be some issues with forwarding your calls to ReachMe servers & our support team will help you troubleshoot the problem to get you started, right away.", font: .systemFont(ofSize: 13), color: UIColor(red: 3, green: 3, blue: 3))
                        alert.addAction(title: "Cancel", style: .default)
                        alert.addAction(title: "REQUEST SUPPORT", style: .default) { (alertAction) in
                            RMUtility.handleHelpSupportAction(withHelpText: self.helpText)
                        }
                        self.present(alert, animated: true, completion: nil)
                    }
                    alert.addAction(title: "YES", style: .default) { (alertAction) in
                        
                        //Handle success case
                        switch self.reachMeType {
                        case .home:
                            self.userContact.isReachMeHomeActive = true
                            self.userContact.isReachMeIntlActive = false
                            self.userContact.isReachMeVoiceMailActive = false
                        case .international:
                            self.userContact.isReachMeIntlActive = true
                            self.userContact.isReachMeHomeActive = false
                            self.userContact.isReachMeVoiceMailActive = false
                        case .voicemail:
                            self.userContact.isReachMeVoiceMailActive = true
                            self.userContact.isReachMeIntlActive = false
                            self.userContact.isReachMeHomeActive = false
                        default:
                            break
                        }
                        
                        ANLoader.showLoading("", disableUI: true)
                        ServiceRequest.shared().startRequestForUpdateSettings(completionHandler: { (success) in
                            ANLoader.hide()
                            guard success else {//If error occurs undo the local changes for this context
                                self.userContact?.managedObjectContext?.rollback()
                                return
                            }
                            
                            var alertMessage: String!
                            if self.reachMeType == RMUtility.ReachMeType.international {
                                alertMessage = "\nReachMe International is activated for your number. you can test the service by dialing this number from any other phone and you will get a ReachMe call on the app.\n"
                                
                            } else {
                                alertMessage = "\nReachMe Home is activated for your number.You can test the service by putting your phone on flight mode and dialing it from any other phone. You will get a ReachMe Call on the app\n"
                            }
                            
                            let alert = UIAlertController(style: .alert, title: "Congratulations")
                            alert.set(message: alertMessage, font: .systemFont(ofSize: 13), color: UIColor(red: 3, green: 3, blue: 3))
                            alert.addAction(title: "OK", style: .default) { (alertAction) in
                                self.coreDataStack.saveContexts()
                                self.performSegue(withIdentifier: Constants.UnwindSegues.ACTIVATE_REACHME, sender: self)
                            }
                            self.present(alert, animated: true, completion: nil)
                        })
                    }
                    self.present(alert, animated: true, completion: nil)
                }
                self.present(alert, animated: true, completion: nil)
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func constructtableCells() {
        //TitleCell
        let  titleCell = tableView.dequeueReusableCell(withIdentifier: ActivationReachMeTitleCell.identifier) as! ActivationReachMeTitleCell
        switch reachMeType {
        case .home:
            titleCell.titleLabel.text = "How to \(activationType.rawValue) ReachMe Home?"
        case .international:
            titleCell.titleLabel.text = "How to \(activationType.rawValue) ReachMe International?"
        case .voicemail:
            titleCell.titleLabel.text = "How to \(activationType.rawValue) ReachMe Voicemail?"
        default:
            break
        }
        if dialCodeArray.count > 1 {
            titleCell.descriptionLabel?.text = "Dial following \(activationType.rawValue) code (including * and #) on device containing the SIM associated with \(userContact.formatedNumber!). Dial the codes one after the other. There will be no charges incurred for dialing this code either from ReachMe or your Carrier."
        } else {
            titleCell.descriptionLabel?.text = "Dial following \(activationType.rawValue) code (including * and #) on device containing the SIM associated with \(userContact.formatedNumber!). There will be no charges incurred for dialing this code either from ReachMe or your Carrier."
        }
        tableCellArray.append(titleCell)
        
        //BundleValueCell
        if (userContact.selectedCarrier?.additionalActiInfo) != nil {
            let totalString = """
            Call Forwarding
            \((userContact.selectedCarrier?.additionalActiInfo)!)
            """
            let newstring = NSString(string: totalString)
            let attributedString = NSMutableAttributedString(string: totalString)
            
            attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.8), range: newstring.range(of: "Call Forwarding"))
            attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 16), range: newstring.range(of: "Call Forwarding"))
            
            attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.54), range: newstring.range(of: (userContact.selectedCarrier?.additionalActiInfo)!))
            attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 14), range: newstring.range(of: (userContact.selectedCarrier?.additionalActiInfo)!))
            
            let  bundleValueCell = tableView.dequeueReusableCell(withIdentifier: ActivationReachMeBundleValueCell.identifier) as! ActivationReachMeBundleValueCell
            bundleValueCell.valueLabel.attributedText = attributedString
            tableCellArray.append(bundleValueCell)
        }
        
        //InstructionCell
        let  instructionCell = tableView.dequeueReusableCell(withIdentifier: "ActivationReachMeInstructionCell")
        tableCellArray.append(instructionCell as Any)
        
        //CopyShare Cell
        for dialCode in dialCodeArray {
            let  dialCodeCell = tableView.dequeueReusableCell(withIdentifier: ActivationReachMeCopyShareCell.identifier) as! ActivationReachMeCopyShareCell
            dialCodeCell.dialCodeLabel.text = dialCode
            tableCellArray.append(dialCodeCell)
        }
        
        //InfoCell
        if reachMeType == RMUtility.ReachMeType.international {
            let  infoIntlCell = tableView.dequeueReusableCell(withIdentifier: ActivationReachMeInfoIntlCell.identifier) as! ActivationReachMeInfoIntlCell
            infoIntlCell.helpText = helpText
            tableCellArray.append(infoIntlCell)
        } else {
            let  infoOtherCell = tableView.dequeueReusableCell(withIdentifier: ActivationReachMeInfoOtherCell.identifier) as! ActivationReachMeInfoOtherCell
            infoOtherCell.helpText = helpText
            tableCellArray.append(infoOtherCell)
        }
        
        //FinishCell
        if Defaults[.IsOnBoarding] {
            let  finishCell = tableView.dequeueReusableCell(withIdentifier: "ActivationReachMeFinishCell")
            tableCellArray.append(finishCell as Any)
        }
    }
    
    // MARK: - Button Actions
    @IBAction func onHelpClicked(_ sender: UIBarButtonItem) {
        RMUtility.handleHelpSupportAction(withHelpText: helpText)
    }
    
}

// MARK: - TableView Delegate & Datasource
extension ActivationReachMeViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableCellArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableCellArray[indexPath.row] as! UITableViewCell
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
