//
//  ActivatedReachMeViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/14/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class ActivatedReachMeViewController: UITableViewController {

    var tableCellArray = [Any]()
    var reachMeType: RMUtility.ReachMeType = .home
    var userContact: UserContact!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch reachMeType {
        case .home:
            title = "ReachMe Home"
        case .international:
            title = "ReachMe International"
        case .voicemail:
            title = "ReachMe VoiceMail"
        }

        constructtableCells()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func constructtableCells() {
        //Title
        let  titleCell = tableView.dequeueReusableCell(withIdentifier: ActivatedReachMeTitleCell.identifier) as! ActivatedReachMeTitleCell
        if reachMeType == RMUtility.ReachMeType.home {
            titleCell.titleLabel.text = "You are getting call in the app if number is unreachable"
        }
        tableCellArray.append(titleCell)
        
        //Info
        let  infoCell = tableView.dequeueReusableCell(withIdentifier: "ActivatedReachMeInfoCell")
        tableCellArray.append(infoCell as Any)

        if Defaults[.IsOnBoarding] {
            //Finish button
            let  finishCell = tableView.dequeueReusableCell(withIdentifier: "ActivatedReachMeFinishCell")
            tableCellArray.append(finishCell as Any)
            
        } else {
            //Activate Again
            let  activateAgainCell = tableView.dequeueReusableCell(withIdentifier: "ActivatedReachMeActivateAgainCell")
            tableCellArray.append(activateAgainCell as Any)
            
            //Switch To
            let  switchToCell = tableView.dequeueReusableCell(withIdentifier: ActivatedReachMeSwitchToCell.identifier) as! ActivatedReachMeSwitchToCell
            switch reachMeType {
            case .home:
                switchToCell.switchToButton.setTitle("  SWITCH TO REACHME INTERNATIONAL  ", for: .normal)
                switchToCell.countryFlag.image = #imageLiteral(resourceName: "rm_international")
                switchToCell.backToCountryLabel.text = "Planning to Travel outside of \(userContact.countryName!)?"
            case .international:
                switchToCell.countryFlag.layer.cornerRadius = switchToCell.countryFlag.frame.size.height/2
                if let countryImage = UIImage(data: userContact.countryImageData!) {
                    switchToCell.countryFlag.image = countryImage
                }
                switchToCell.backToCountryLabel.text = "Back to \(userContact.countryName!)?"
            case .voicemail:
                break
            }
            tableCellArray.append(switchToCell)

            //Contact Support
            let  contactSupportCell = tableView.dequeueReusableCell(withIdentifier: ActivatedReachMeContactSupportCell.identifier) as! ActivatedReachMeContactSupportCell
            switch reachMeType {
            case .home:
                contactSupportCell.satisfiedLabel.text = "Not satisfied with ReachMe Home Service?"
            case .international:
                contactSupportCell.satisfiedLabel.text = "Not satisfied with ReachMe International Service?"
            case .voicemail:
                contactSupportCell.satisfiedLabel.text = "Not satisfied with ReachMe Voicemail Service?"
            }
            tableCellArray.append(contactSupportCell)
        }
    }
    
    // MARK: - Button Actions
    @IBAction func onHelpButtonClicked(_ sender: UIBarButtonItem) {
        RMUtility.handleHelpSupportAction(withHelpText: nil)
    }
    
    // MARK: - Segue Actions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destVC = segue.destination as? ActivationReachMeViewController,
            destVC.isKind(of: ActivationReachMeViewController.self) {
            
            destVC.userContact = userContact
            destVC.title = title
            
            switch segue.identifier {
            case Constants.Segues.ACTIVATION_AGAIN?:
                destVC.activationType = .activate
                destVC.reachMeType = reachMeType
                
            case Constants.Segues.ACTIVATION_SWITCHTO?:
                destVC.activationType = .activate
                if reachMeType == RMUtility.ReachMeType.home {
                    destVC.reachMeType = .international
                } else {
                    destVC.reachMeType = .home
                }
                
            case Constants.Segues.ACTIVATION_DEACTIVATE?:
                destVC.activationType = .deactivate
                destVC.reachMeType = reachMeType
                
            default:
                break
            }
        }
        
    }
}

// MARK: - TableView Delegate & Datasource
extension ActivatedReachMeViewController {
    
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
