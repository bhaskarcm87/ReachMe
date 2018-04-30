//
//  UISearchBar+Extensions.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 4/29/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

extension UISearchBar {
    
    var textField: UITextField? {
        return value(forKey: "searchField") as? UITextField
    }
    
    func setSearchIcon(image: UIImage) {
        setImage(image, for: .search, state: .normal)
    }
    
    func setClearIcon(image: UIImage) {
        setImage(image, for: .clear, state: .normal)
    }
}
