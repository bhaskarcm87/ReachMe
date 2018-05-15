//
//  SettingsTableCells.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/16/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class SettingsProfileCell: UITableViewCell {
    
    static let identifier = String(describing: SettingsProfileCell.self)
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var statusView: DesignableView!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        updateCell()
    }
    
    func updateCell() {
        if let profilePicData = Constants.appDelegate.userProfile?.profilePicData,
            let profileImage = UIImage(data: profilePicData) {
            spinnerView.stopAnimating()
            profileImageView.image = profileImage
            
        } else {// If image not downloaded yet, then dwonload once
            ServiceRequest.shared.startRequestForDownloadProfilePic(completionHandler: { (imageData) in
                if let profileImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.spinnerView.stopAnimating()
                        self.profileImageView.image = profileImage
                    }
                }
            })
        }
        titleLabel.text = Constants.appDelegate.userProfile?.userName
        subtitleLabel.text = Constants.appDelegate.userProfile?.primaryContact?.countryName
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class SettingsPrimaryNumberCell: UITableViewCell {
    
    static let identifier = String(describing: SettingsPrimaryNumberCell.self)
    
    @IBOutlet weak var countryImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        updateCell()
    }

    func updateCell() {
        if let countryImage = UIImage(data: (Constants.appDelegate.userProfile?.primaryContact?.countryImageData)!) {
            countryImageView.image = countryImage
        }
        titleLabel.text = Constants.appDelegate.userProfile?.primaryContact?.formatedNumber
        subtitleLabel.text = Constants.appDelegate.userProfile?.primaryContact?.selectedCarrier?.networkName
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class SettingsCarrierLogoSupportCell: UITableViewCell {
    
    @IBOutlet weak var carrierImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    static let identifier = String(describing: SettingsCarrierLogoSupportCell.self)
    private let coreDataStack = Constants.appDelegate.coreDataStack

    override func awakeFromNib() {
        super.awakeFromNib()
        updateCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        updateCell()
    }
    
    func updateCell() {
        // carrierImageView.contentMode = .scaleAspectFit
        // carrierImageView.clipsToBounds = true
        
        if let carrierLogoSupportImageData = Constants.appDelegate.userProfile?.primaryContact?.selectedCarrier?.logoSupportImageData,
            let carriaerLogoImage = UIImage(data: carrierLogoSupportImageData) {
            carrierImageView.image = carriaerLogoImage
            
        } else {// If image not downloaded yet, then dwonload once
            ServiceRequest.shared.startRequestForDownloadImage(forURL: (Constants.appDelegate.userProfile?.primaryContact?.selectedCarrier?.logoHomeURL)!, completionHandler: { (logoImageData) in
                
                Constants.appDelegate.userProfile?.primaryContact?.selectedCarrier?.logoSupportImageData = logoImageData
                self.coreDataStack.saveContexts()
                if let carriaerLogoImage = UIImage(data: logoImageData) {
                    DispatchQueue.main.async {
                        self.carrierImageView.image = carriaerLogoImage
                    }
                }
            })
        }
        
        titleLabel.text = "\((Constants.appDelegate.userProfile?.primaryContact?.selectedCarrier?.networkName)!) Carrier Support"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
