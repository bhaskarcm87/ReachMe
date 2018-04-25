//
//  ActivationReachMeTableCells.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/13/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class ActivationReachMeTitleCell: UITableViewCell {
    
    static let identifier = String(describing: ActivationReachMeTitleCell.self)
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ActivationReachMeBundleValueCell: UITableViewCell {
    
    static let identifier = String(describing: ActivationReachMeBundleValueCell.self)
    @IBOutlet weak var valueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ActivationReachMeCopyShareCell: UITableViewCell {
    
    static let identifier = String(describing: ActivationReachMeCopyShareCell.self)
    
    @IBOutlet weak var dialCodeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func onCopyButtonClicked(_ sender: UIButton) {
        UIPasteboard.general.string = dialCodeLabel.text
        RMUtility.showAlert(withMessage: "Dial Code Copied")
    }
    
    @IBAction func onShareButtonClicked(_ sender: UIButton) {
        let vc = UIActivityViewController(activityItems: [dialCodeLabel.text!], applicationActivities: [])
        UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true)
    }
}

class ActivationReachMeInfoIntlCell: UITableViewCell {
    
    static let identifier = String(describing: ActivationReachMeInfoIntlCell.self)
    @IBOutlet weak var detailLabel: UILabel!
    var helpText: String!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onLabelTapGesture(_:)))
        detailLabel.addGestureRecognizer(gestureRecognizer)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @objc func onLabelTapGesture(_ sender: UITapGestureRecognizer) {
        let text = (detailLabel.text)!
        let learnMoreRange = (text as NSString).range(of: "contact support")
        if sender.didTapAttributedTextInLabel(label: detailLabel, inRange: learnMoreRange) {
            RMUtility.handleHelpSupportAction(withHelpText: helpText)
        }
    }
}

class ActivationReachMeInfoOtherCell: UITableViewCell {
    
    static let identifier = String(describing: ActivationReachMeInfoOtherCell.self)
    @IBOutlet weak var detailLabel: UILabel!
    var helpText: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onLabelTapGesture(_:)))
        detailLabel.addGestureRecognizer(gestureRecognizer)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @objc func onLabelTapGesture(_ sender: UITapGestureRecognizer) {
        let text = (detailLabel.text)!
        let learnMoreRange = (text as NSString).range(of: "contact support")
        if sender.didTapAttributedTextInLabel(label: detailLabel, inRange: learnMoreRange) {
            RMUtility.handleHelpSupportAction(withHelpText: helpText)
        }
    }
}
