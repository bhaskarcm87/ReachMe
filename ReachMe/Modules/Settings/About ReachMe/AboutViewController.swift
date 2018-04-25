//
//  AboutViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/25/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class AboutViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! WebViewController
        destVC.title = tableView.cellForRow(at: tableView.indexPathForSelectedRow!)?.textLabel?.text

        switch segue.identifier {
        case Constants.Segues.FREQUENTLY_ASKED?:
            destVC.urlString = "https://getreachme.instavoice.com/faq"
        case Constants.Segues.TERMS_CONDITIONS?:
            destVC.urlString = "https://getreachme.instavoice.com/terms"
        case Constants.Segues.PRIVACY_POLICY?:
            destVC.urlString = "https://getreachme.instavoice.com/privacy"
        default:
            break
        }
    }
}
