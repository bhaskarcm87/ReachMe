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

    lazy var createHeader: ((String) -> ViewFormer) = { text in
        return LabelViewFormer<FormLabelHeaderView>()
            .configure {
                $0.text = text
                $0.viewHeight = 60
        }
    }
    
    lazy var emailAddressRow = LabelRowFormer<FormLabelCell>()
        .configure {
            $0.text = "Email address"
            $0.subText = "Add"
            $0.cell.formSubTextLabel()?.textColor = .ReachMeColor()
    }
    
    lazy var voicemailRow = SwitchRowFormer<FormSwitchCell>() {
        $0.titleLabel.text = "Voicemail"
        $0.switchButton.onTintColor = .ReachMeColor()
        }.configure {
            $0.switched = false
        }.onSwitchChanged { switched in
            
    }
    
    lazy var missedCallRow = SwitchRowFormer<FormSwitchCell>() {
        $0.titleLabel.text = "Missed Call"
        $0.switchButton.onTintColor = .ReachMeColor()
        }.configure {
            $0.switched = false
        }.onSwitchChanged { switched in
    }
    
    lazy var timeZoneRow = InlinePickerRowFormer<FormInlinePickerCell, Any> {
        $0.titleLabel.text = "Email Time Zone"
        $0.displayLabel.textColor = .lightGray
        $0.accessoryType = .disclosureIndicator
        }.configure {
            $0.pickerItems = TimeZone.knownTimeZoneIdentifiers.map { InlinePickerItem(title: $0) }
            $0.displayEditingColor = .ReachMeColor()
            $0.pickerItems.insert(InlinePickerItem(title: TimeZone.current.identifier), at: 0)
            // $0.selectedRow
    }
    
    var userProfile: Profile? {
        get {
            return CoreDataModel.sharedInstance().getUserProfle()!
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let section = SectionFormer(rowFormer: emailAddressRow, voicemailRow, missedCallRow, timeZoneRow)
            .set(headerViewFormer: createHeader("Receive Voicemail & Missed Call Alerts on your email address"))
        former.append(sectionFormer: section)

        emailAddressRow.onSelected { [weak self] _ in
            self?.former.deselect(animated: true)
            //self?.emailAddressRow.cell.formTextLabel()?.text = ""
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //private lazy var subRowFormers: RowFormer = {
    //    return CheckRowFormer<FormCheckCell>() {
    //        $0.titleLabel.text = "Sachin"
    //        $0.titleLabel.font = .boldSystemFont(ofSize: 16)
    //    }
    //}()
    
    //self?.former.insertUpdate(rowFormers: [(self?.subRowFormers)!], below: (self?.emailAddressRow)!, rowAnimation: .top)
    //self?.former.removeUpdate(rowFormers: [(self?.subRowFormers)!], rowAnimation: .top)

}
