//
//  KeyboardAvoidScrollView.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/17/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class KeyboardAvoidScrollView: UIScrollView, UIScrollViewDelegate {

    // Get a touched view which is contained by Scroll view.
    open override func touchesShouldBegin(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) -> Bool {
        if view .isKind(of: UITextField.self) {
            let textField:UITextField = view as! UITextField
            self.isScrollEnabled = true
            var rect = textField.bounds
            rect = textField.convert(rect, to: self)
            var points:CGPoint = rect.origin
            points.x = 0
            points.y -= self.frame.size.height/2 - 300   // You can change the value by appropriate your comfortable on
            self.setContentOffset(points, animated: true)
        } else {
            self.setContentOffset(.zero, animated: true)
            self.endEditing(true)
        }
        return true
    }

}
