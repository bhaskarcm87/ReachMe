//
//  String+Extention.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/21/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import Alamofire

extension String {
    
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    func isValidEmail() -> Bool {
        // Password should not blank
        if self.isEmpty {
            return false
        }
        //Email address should accept like:test@gmail.co.uk
        let emailRegEx = "[.0-9a-zA-Z_-]+@[0-9a-zA-Z.-]+\\.[a-zA-Z]{2,20}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        if !emailTest.evaluate(with: self) {
            return false
        }
        return true
    }
}

extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        request.addValue("keep-alive", forHTTPHeaderField: "Connection")
        return request
    }
}
