//
//  Profile.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/22/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import CoreData

enum VolumeModeEnum: Int16 {
    case Speaker
    case Caller
}

extension Profile {
    
    var volumeMode: VolumeModeEnum {
        get {
            return VolumeModeEnum(rawValue: volumeModeRaw)!
        }
        set {
            volumeModeRaw = volumeMode.rawValue
        }
    }
}

