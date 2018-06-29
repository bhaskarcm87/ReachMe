//
//  Message.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 6/28/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import CoreData
import RxDataSources

extension Message: IdentifiableType {
    public var identity: Int {
        return Int(self.messageID)
    }
}
