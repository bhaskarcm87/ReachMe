//
//  ActivateReachMeTableCells.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/4/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class ActivateReachMeTitleCell: UITableViewCell {

    static let identifier = String(describing: ActivateReachMeTitleCell.self)

    @IBOutlet weak var countryImageView: UIImageView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var networkNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
}

class ActivateReachMeUsageSummaryCell: UITableViewCell {
    
    static let identifier = String(describing: ActivateReachMeUsageSummaryCell.self)
    
    @IBOutlet weak var countryImageView: UIImageView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var networkNameLabel: UILabel!
    @IBOutlet weak var incomingCallsCountLabel: UILabel!
    @IBOutlet weak var missedCallsCountLabel: UILabel!
    @IBOutlet weak var voicemailsCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}

class ActivateReachMeErrorCell: UITableViewCell {
    
    static let identifier = String(describing: ActivateReachMeErrorCell.self)
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

class ActivateReachMeIntlCell: UITableViewCell {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var designableVIew: DesignableLabel!
    static let identifier = String(describing: ActivateReachMeIntlCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if !Defaults[.IsOnBoarding] {
            designableVIew.cornerRadius = 0
            designableVIew.shadowOpacity = 0
            designableVIew.shadowRadius = 0
            designableVIew.shadowOffset = CGSize(width: 0, height: 0)
            designableVIew.shadowColor = .clear
            designableVIew.customBorderColor = UIColor.init(red: 206, green: 212, blue: 218)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ActivateReachMeVoiceMailCell: UITableViewCell {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var designableVIew: DesignableLabel!
    static let identifier = String(describing: ActivateReachMeVoiceMailCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if !Defaults[.IsOnBoarding] {
            designableVIew.cornerRadius = 0
            designableVIew.shadowOpacity = 0
            designableVIew.shadowRadius = 0
            designableVIew.shadowOffset = CGSize(width: 0, height: 0)
            designableVIew.shadowColor = .clear
            designableVIew.customBorderColor = UIColor.init(red: 206, green: 212, blue: 218)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ActivateReachMeHomeCell: UITableViewCell {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var designableVIew: DesignableLabel!
    static let identifier = String(describing: ActivateReachMeHomeCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if !Defaults[.IsOnBoarding] {
            designableVIew.cornerRadius = 0
            designableVIew.shadowOpacity = 0
            designableVIew.shadowRadius = 0
            designableVIew.shadowOffset = CGSize(width: 0, height: 0)
            designableVIew.shadowColor = .clear
            designableVIew.customBorderColor = UIColor.init(red: 206, green: 212, blue: 218)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ActivateReachMeInfoCell: UITableViewCell {
    
    static let identifier = String(describing: ActivateReachMeInfoCell.self)
    @IBOutlet weak var infoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onLabelTapGesture(_:)))
        //gestureRecognizer.delegate = self
        infoLabel.addGestureRecognizer(gestureRecognizer)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @objc func onLabelTapGesture(_ sender: UITapGestureRecognizer) {
        let text = (infoLabel.text)!
        let learnMoreRange = (text as NSString).range(of: "Learn More")
        if sender.didTapAttributedTextInLabel(label: infoLabel, inRange: learnMoreRange) {
            guard let url = URL(string: "https://getreachme.instavoice.com") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

class ActivateReachMeRequestSupportCell: UITableViewCell {
    
    @IBOutlet weak var button: UIButton!
    static let identifier = String(describing: ActivateReachMeRequestSupportCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ActivateReachMeUnlinkNumberCell: UITableViewCell {
    
    @IBOutlet weak var button: UIButton!
    static let identifier = String(describing: ActivateReachMeUnlinkNumberCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ActivateReachMeContinueCell: UITableViewCell {
    
    @IBOutlet weak var button: UIButton!
    static let identifier = String(describing: ActivateReachMeContinueCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ActivateReachMeFinishCell: UITableViewCell {
    
    static let identifier = String(describing: ActivateReachMeFinishCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func buttonClicked(_ sender: UIButton) {
        
    }
}

