//
//  HowToActivateReachMeViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/11/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import CountdownLabel

class HowToActivateReachMeViewController: UITableViewController {

    var reachMeType: RMUtility.ReachMeType = .voicemail
    var userContact: UserContact!
    var timer = CountdownLabel()

    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var activateButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        switch reachMeType {
        case .home:
            title = "ReachMe Home"
            headerTitle.text = "Get calls in the app if number is unreachable"
            imageView1.image = #imageLiteral(resourceName: "details_icon_2"); imageView2.image = #imageLiteral(resourceName: "multiple_smartphones"); imageView3.image = #imageLiteral(resourceName: "withdraw_voicemail")
            label1.text = "Get incoming calls in the InstaVoice ReachMe app, over data"
            label2.text = "Get calls on multiple devices, even on devices that do not have the SIM card"
            label3.text = "Withdraw, share or forward voicemails with anyone"

        case .international:
            title = "ReachMe International"
            headerTitle.text = "Get all calls in the app at zero roaming charges"
            imageView1.image = #imageLiteral(resourceName: "details_icon_1"); imageView2.image = #imageLiteral(resourceName: "details_icon_2"); imageView3.image = #imageLiteral(resourceName: "details_icon_3")
            label1.text = "Save roaming charges when traveling internationally"
            label2.text = "Get all incoming calls in the InstaVoice ReachMe app over data"
            label3.text = "SIM is not required in the phone and you can use the slot for a local SIM"
            
        case .voicemail:
            title = "ReachMe VoiceMail"
            headerTitle.text = "Get voicemail and missed calls"
            imageView1.image = #imageLiteral(resourceName: "multiple_smartphones"); imageView2.image = #imageLiteral(resourceName: "transcription"); imageView3.image = #imageLiteral(resourceName: "withdraw_voicemail")
            label1.text = "Get voicemails and missed calls on multiple devices, even on devices that do not have the SIM card"
            label2.text = "Voice-to-text for your voicemails and voice messages"
            label3.text = "Withdraw, share or forward voicemails with anyone"
        }
        
        if (userContact.selectedCarrier?.ussdString) != nil {
            if userContact.isReachMeIntlActive {
                activateButton.setTitle("Switch To Home", for: .normal)
            } else if userContact.isReachMeHomeActive {
                activateButton.setTitle("Switch to ReachMe International", for: .normal)
            } else if (userContact.selectedCarrier?.isHLREnabled)! {
                activateButton.setTitle("Activate", for: .normal)
            } else {
                activateButton.setTitle("How To Activate", for: .normal)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func startCounter() {
        timer.setCountDownTime(minutes: 10)
        timer.start()
    }

    // MARK: - Button Actions
    @IBAction func onActivateButtonClicked(_ sender: UIButton) {
        
        if (userContact.selectedCarrier?.isHLREnabled)! {
            guard RMUtility.isNetwork() else {
                RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                return
            }
            
            ANLoader.showLoading("", disableUI: true)
            var params: [String: Any] = ["cmd": Constants.ApiCommands.VOICEMAIL_SETTING,
                                         "phone_num": userContact.contactID!,
                                         "action": "enable"]
            startCounter()
            ServiceRequest.shared.startRequestForVoicemailSetting(withVoicemailInfo: &params, completionHandler: { (success) in
                ANLoader.hide()
                guard success else { return }
                
                self.performSegue(withIdentifier: Constants.Segues.ACTIVATION_REACHME, sender: self)
                RMUtility.showAlert(withMessage: "Oops!  Something went wrong. Please, check carrier & reactivate OR tap on ‘Help’ to get assistance.")
                
                if self.timer.isCounting {
                    print("Success")
                    //TODO: show success Local notification
                } else {
                    print("failure")
                    //TODO: show failure Local notification
                }
            })
            
        } else {
            performSegue(withIdentifier: Constants.Segues.ACTIVATION_REACHME, sender: self)
        }
    }
    
    @IBAction func onHelpButtonClicked(_ sender: UIBarButtonItem) {
        RMUtility.handleHelpSupportAction(withHelpText: nil)
    }
    
    // MARK: - Segue Actions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segues.ACTIVATION_REACHME {
            let destVC = segue.destination as! ActivationReachMeViewController
            destVC.title = title
            destVC.reachMeType = reachMeType
            destVC.activationType = .activate
            destVC.userContact = userContact
        }
    }
}

// MARK: - TableView Delegate
extension HowToActivateReachMeViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row == 5 else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let url = URL(string: "https://getreachme.instavoice.com") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
