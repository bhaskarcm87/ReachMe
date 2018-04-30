//
//  UIImageView+Extensions.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 4/29/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

extension UIImage {
    
    func imageWithSize(size: CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        draw(in: rect)
        
        let resultingImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultingImage
    }
    
    func imageWithSize(size: CGSize, extraMargin: CGFloat) -> UIImage? {
        
        let imageSize = CGSize(width: size.width + extraMargin * 2, height: size.height + extraMargin * 2)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.main.scale)
        let drawingRect = CGRect(x: extraMargin, y: extraMargin, width: size.width, height: size.height)
        draw(in: drawingRect)
        
        let resultingImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultingImage
    }
    
    func imageWithSize(size: CGSize, roundedRadius radius: CGFloat) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        if let currentContext = UIGraphicsGetCurrentContext() {
            let rect = CGRect(origin: .zero, size: size)
            currentContext.addPath(UIBezierPath(roundedRect: rect,
                                                byRoundingCorners: .allCorners,
                                                cornerRadii: CGSize(width: radius, height: radius)).cgPath)
            currentContext.clip()
            
            //Don't use CGContextDrawImage, coordinate system origin in UIKit and Core Graphics are vertical oppsite.
            draw(in: rect)
            currentContext.drawPath(using: .fillStroke)
            let roundedCornerImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return roundedCornerImage
        }
        return nil
    }
}
