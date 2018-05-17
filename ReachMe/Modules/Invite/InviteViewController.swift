//
//  InviteViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 5/15/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class InviteViewController: UIViewController {

    private let coreDataStack = Constants.appDelegate.coreDataStack
    var selectedContactListType: RMUtility.ContactListType!

    override func viewDidLoad() {
        super.viewDidLoad()

        ContactsManager.requestForAccess { (accessGranted) in
            if accessGranted {
                NotificationCenter.default.addObserver(self, selector: #selector(self.contactStoreDidChange), name: .CNContactStoreDidChange, object: nil)
                guard Constants.appDelegate.userProfile?.deviceContacts?.count == 0 else { return }
                
                ContactsManager.fetchContacts(completionHandler: { (success) in
                    guard success else { return }

                })
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Button Actions
    @IBAction func inviteBtnClicked(_ sender: UIButton) {
        let alert = UIAlertController(style: .actionSheet, title: "Invite Friends")
        alert.addAction(title: "Invite Friends via SMS", handler: { _ in
            self.selectedContactListType = .phone
            self.performSegue(withIdentifier: Constants.Segues.CONTACT_LIST, sender: nil)
        })
        alert.addAction(title: "Invite Friends via Email", handler: { _ in
            self.selectedContactListType = .email
            self.performSegue(withIdentifier: Constants.Segues.CONTACT_LIST, sender: nil)
        })
        alert.addAction(title: "Cancel", style: .cancel)
        alert.show()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .CNContactStoreDidChange, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! ContactListViewController
        destVC.contactListType = selectedContactListType
    }
}

extension InviteViewController {
    @objc func contactStoreDidChange(notification: NSNotification) {
        coreDataStack.deleteAllRecordsForEntity(entity: Constants.EntityName.DEVICECONTACT)
        ContactsManager.fetchContacts { (success) in
            guard success else { return }

        }
    }
}

// MARK: - TableView Delegate & Datasource
extension InviteViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let infoCell = tableView.dequeueReusableCell(withIdentifier: "InviteTableCellID")
        return infoCell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

}
