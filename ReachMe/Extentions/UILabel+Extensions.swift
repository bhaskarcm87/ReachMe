//
//  UILabel+Extensions.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 5/10/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation

extension UILabel {
    @IBInspectable
    public var customFontTextStyle: String? {
        get {
            return ""
        }
        set {
            var fontTextStyle: UIFontTextStyle?
            switch newValue {
            case "Body"?:
                fontTextStyle = .body
            case "Callout"?:
                fontTextStyle = .callout
            case "Caption1"?:
                fontTextStyle = .caption1
            case "Caption2"?:
                fontTextStyle = .caption2
            case "Footnote"?:
                fontTextStyle = .footnote
            case "Headline"?:
                fontTextStyle = .headline
            case "Subhead"?:
                fontTextStyle = .subheadline
            case "Title1"?:
                fontTextStyle = .title1
            case "Title2"?:
                fontTextStyle = .title2
            case "Title3"?:
                fontTextStyle = .title3
                
            default:
                break
            }
            
            adjustsFontForContentSizeCategory = true
            let pointSize  = UIFontDescriptor.preferredFontDescriptor(withTextStyle: fontTextStyle!).pointSize
            let customFont = UIFont(name: font.fontName, size: pointSize)
            self.font = customFont
        }
    }
}
