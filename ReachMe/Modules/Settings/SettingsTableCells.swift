//
//  SettingsTableCells.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/16/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

/*class SettingsProfileHeaderCell: UITableViewCell {
    
    static let identifier = String(describing: SettingsProfileHeaderCell.self)
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusView: DesignableView!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    var userProfile: Profile? {
        get {
            return CoreDataModel.sharedInstance().getUserProfle()!
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let profilePicData = userProfile?.profilePicData,
            let profileImage = UIImage(data: profilePicData) {
            spinnerView.stopAnimating()
            profileImageView.image = profileImage
            
        } else {// If image not downloaded yet, then dwonload once
            ServiceRequest.shared().startRequestForDownloadProfilePic(completionHandler: { (imageData) in
                if let profileImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.spinnerView.stopAnimating()
                        self.profileImageView.image = profileImage
                    }
                }
            })
        }
        titleLabel.text = userProfile?.userName
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}*/

class SettingsProfileCell: UITableViewCell {
    
    static let identifier = String(describing: SettingsProfileCell.self)
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var statusView: DesignableView!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    var userProfile: Profile? {
        get {
            return CoreDataModel.sharedInstance().getUserProfle()!
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let profilePicData = userProfile?.profilePicData,
            let profileImage = UIImage(data: profilePicData) {
            spinnerView.stopAnimating()
            profileImageView.image = profileImage
            
        } else {// If image not downloaded yet, then dwonload once
            ServiceRequest.shared().startRequestForDownloadProfilePic(completionHandler: { (imageData) in
                if let profileImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.spinnerView.stopAnimating()
                        self.profileImageView.image = profileImage
                    }
                }
            })
        }
        titleLabel.text = userProfile?.userName
        subtitleLabel.text = userProfile?.primaryContact?.countryName
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
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class SettingsCarrierLogoSupportCell: UITableViewCell {
    
    @IBOutlet weak var carrierImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    static let identifier = String(describing: SettingsCarrierLogoSupportCell.self)
    var userProfile: Profile? {
        get {
            return CoreDataModel.sharedInstance().getUserProfle()!
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
       // carrierImageView.contentMode = .scaleAspectFit
       // carrierImageView.clipsToBounds = true

        if let carrierLogoSupportImageData = userProfile?.primaryContact?.selectedCarrier?.logoSupportImageData,
            let carriaerLogoImage = UIImage(data: carrierLogoSupportImageData) {
            carrierImageView.image = carriaerLogoImage
            
        } else {// If image not downloaded yet, then dwonload once
            ServiceRequest.shared().startRequestForDownloadImage(forURL: (userProfile?.primaryContact?.selectedCarrier?.logoHomeURL)!, completionHandler: { (logoImageData) in

                self.userProfile?.primaryContact?.selectedCarrier?.logoSupportImageData = logoImageData
                CoreDataModel.sharedInstance().saveContext()
                if let carriaerLogoImage = UIImage(data: logoImageData) {
                    DispatchQueue.main.async {
                        self.carrierImageView.image = carriaerLogoImage
                    }
                }
            })
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
