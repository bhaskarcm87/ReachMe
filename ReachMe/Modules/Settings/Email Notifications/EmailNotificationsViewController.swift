//
//  EmailNotificationsViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 4/25/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import Former

class EmailNotificationsViewController: UITableViewController {

    public private(set) lazy var former: Former = Former(tableView: self.tableView)

    override func viewDidLoad() {
        super.viewDidLoad()
        constructtableCells()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func constructtableCells() {
        let voicemailRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = "Voicemail"
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            $0.switchButton.onTintColor = .ReachMeColor()
            }.configure {
                $0.switched = false
            }.onSwitchChanged { switched in
        }
        
        let createHeader: ((String) -> ViewFormer) = { text in
            return LabelViewFormer<FormLabelHeaderView>()
                .configure {
                    $0.text = text
                    $0.viewHeight = 44
            }
        }
        
        let section = SectionFormer(rowFormer: voicemailRow)
            .set(headerViewFormer: createHeader("Receive Voicemail & Missed Call Alerts on your email address"))
        
        former.append(sectionFormer:
            section
        )
    }
}
