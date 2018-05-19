//
//  UIColor+Extention.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/16/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255

        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
    
    convenience init(hex: Int, alpha: CGFloat) {
        let r = CGFloat((hex & 0xFF0000) >> 16)/255
        let g = CGFloat((hex & 0xFF00) >> 8)/255
        let b = CGFloat(hex & 0xFF)/255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    convenience init(hex: Int) {
        self.init(hex: hex, alpha: 1.0)
    }
    
    class func ReachMeColor() -> UIColor { return #colorLiteral(red: 0.9058823529, green: 0.3294117647, blue: 0.2941176471, alpha: 1) }
    
    class func introPage1Color() -> UIColor { return #colorLiteral(red: 0.7843137255, green: 0.05882352941, blue: 0.0862745098, alpha: 1) }
    
    class func introPage2Color() -> UIColor { return #colorLiteral(red: 0.4784313725, green: 0.8117647059, blue: 0.3098039216, alpha: 1) }
    
    class func introPage3Color() -> UIColor { return #colorLiteral(red: 0.8980392157, green: 0.7882352941, blue: 0.168627451, alpha: 1) }
    
    class func introPage4Color() -> UIColor { return #colorLiteral(red: 0, green: 0.5529411765, blue: 0.9098039216, alpha: 1) }
    
    class func decode(withData data: Data) -> UIColor {
        return NSKeyedUnarchiver.unarchiveObject(with: data) as! UIColor
    }
}
