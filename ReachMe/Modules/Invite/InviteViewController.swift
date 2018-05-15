//
//  InviteViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 5/15/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class InviteViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Button Actions
    @IBAction func inviteBtnClicked(_ sender: UIButton) {
    }
    
}

// MARK: - TableView Delegate
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
