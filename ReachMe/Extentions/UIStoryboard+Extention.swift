//
//  UIStoryboard+Extention.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 4/16/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import UIKit

extension UIStoryboard {
    static func login() -> UIStoryboard {
        return UIStoryboard(name: "Login", bundle: nil)
    }
    
    static func dashboard() -> UIStoryboard {
        return UIStoryboard(name: "Dashboard", bundle: nil)
    }
    
    static func activateReachMe() -> UIStoryboard {
        return UIStoryboard(name: "ActivateReachMe", bundle: nil)
    }
}
