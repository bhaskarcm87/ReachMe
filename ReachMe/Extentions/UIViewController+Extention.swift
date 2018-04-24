//
//  UIViewController+Extention.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 4/16/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    static func loginViewController() -> LoginViewController {
        return UIStoryboard.login().instantiateViewController(withIdentifier: LoginViewController.string()) as! LoginViewController
    }
    
    static func selectCarrierViewController() -> SelectCarrierViewController {
        return UIStoryboard.activateReachMe().instantiateViewController(withIdentifier: SelectCarrierViewController.string()) as! SelectCarrierViewController
    }
    
    static func activateReachMeViewController() -> ActivateReachMeViewController {
        return UIStoryboard.activateReachMe().instantiateViewController(withIdentifier: ActivateReachMeViewController.string()) as! ActivateReachMeViewController
    }
    
    static func personalisationViewController() -> PersonalisationViewController {
        return UIStoryboard.activateReachMe().instantiateViewController(withIdentifier: PersonalisationViewController.string()) as! PersonalisationViewController
    }
}
