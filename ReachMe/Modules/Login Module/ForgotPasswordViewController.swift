//
//  ForgotPasswordViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/24/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: UIViewController {
    
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var countryFlag: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let flagimage = UIImage(data: (Constants.appDelegate.userProfile?.countryImageData)!)
        countryFlag.image = flagimage
        countryNameLabel.text = Constants.appDelegate.userProfile?.countryName
        phoneNumberLabel.text = Constants.appDelegate.userProfile?.mobileNumberFormated
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Actions
    @IBAction func onReceivedCodeClicked(_ sender: UIButton) {
        performSegue(withIdentifier: Constants.Segues.OTP, sender: self)
    }
    
    @IBAction func onContinueClicked(_ sender: UIButton) {
        
        ANLoader.showLoading("", disableUI: true)
        ServiceRequest.shared().startRequestForGeneratePassword { (success) in
            ANLoader.hide()
            guard success else { return }
            self.performSegue(withIdentifier: Constants.Segues.OTP, sender: self)
        }
    }
    
    @IBAction func onCancelClicked(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Constants.Segues.OTP:
            let otpVC = segue.destination as! OTPViewController
            otpVC.otpType = .Forgot
        default:
            break
        }
    }
}
