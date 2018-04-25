//
//  ActivatedReachMeTableCells.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/14/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class ActivatedReachMeTitleCell: UITableViewCell {
    
    static let identifier = String(describing: ActivatedReachMeTitleCell.self)
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ActivatedReachMeSwitchToCell: UITableViewCell {
    
    static let identifier = String(describing: ActivatedReachMeSwitchToCell.self)
    @IBOutlet weak var countryFlag: UIImageView!
    @IBOutlet weak var backToCountryLabel: UILabel!
    @IBOutlet weak var switchToButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

    class ActivatedReachMeContactSupportCell: UITableViewCell {
        
        static let identifier = String(describing: ActivatedReachMeContactSupportCell.self)
        @IBOutlet weak var satisfiedLabel: UILabel!
        
        override func awakeFromNib() {
            super.awakeFromNib()
        }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
        }
        
        @IBAction func onContactSupportClicked(_ sender: UIButton) {
            RMUtility.handleHelpSupportAction(withHelpText: nil)
        }
}
