//
//  EditNumberViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/10/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class EditNumberViewController: UITableViewController {
    
    @IBOutlet weak var countryImageView: UIImageView!
    @IBOutlet weak var titleTextfield: UITextField!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var carrierNameLabel: UILabel!
    
    var userContact: UserContact! {
        get {
            return Constants.appDelegate.userProfile?.primaryContact!
        } set {}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let countryImage = UIImage(data: userContact.countryImageData!) {
            countryImageView.image = countryImage
        }
        phoneNumberLabel.text = userContact.formatedNumber
        titleTextfield.text = userContact.titleName
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        carrierNameLabel.text = userContact.selectedCarrier?.networkName
    }
    
    // MARK: - Buttton Actions
    @IBAction func onSaveButtonClicked(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        guard RMUtility.isNetwork() else {
            RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
            return
        }
        
        userContact.titleName = titleTextfield.text
        userContact.imageName = "iphone"
        
        ANLoader.showLoading("", disableUI: true)
        ServiceRequest.shared.startRequestForUpdateSettings { (success) in
            guard success else { return }
            ServiceRequest.shared.startRequestForFetchSettings(completionHandler: { (success) in
                guard success else { return }
                ANLoader.hide()
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    @IBAction func onCancelbuttonClicked(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if userContact.isReachMeHomeActive ||
            userContact.isReachMeIntlActive ||
            userContact.isReachMeVoiceMailActive {
            
            let alert = UIAlertController(style: .alert, title: "Do you want to change carrier?", message: "Your service is active for this Carrier. Please, Deactivate before changing the carrier.")
            alert.addAction(title: "Cancel", handler: { _ in
                self.tableView.deselectRow(at: IndexPath(row: 2, section: 0), animated: true)
            })
            alert.addAction(title: "OK", handler: { _ in
                self.view.endEditing(true)
                self.navigationController?.popViewController(animated: true)
            })
            alert.show()
            return false
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! SelectCarrierViewController
        destVC.userContact = userContact
    }
}

// MARK: - TextField delegate
extension EditNumberViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let restrictedString = "0123456789 "//Block leading space and numeric
        if range.location == 0, restrictedString.contains(string) {
            return false
        }
        
        if textField.text!.count > 50 {
            RMUtility.showAlert(withMessage: "TAG Name should not exceed 50 characters")
            return false
        }
        
        return true
    }
}
