//
//  Date+Extention.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/21/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation

extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfYear], from: date, to: self).weekOfYear ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    
    /// Returns custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(RMUtility.translatePrural(forKey: "n.years", years(from: date))) ago" }
        if months(from: date)  > 0 { return "\(RMUtility.translatePrural(forKey: "n.months", months(from: date))) ago" }
        if weeks(from: date)   > 0 { return "\(RMUtility.translatePrural(forKey: "n.weeks", weeks(from: date))) ago" }
        if days(from: date)    > 0 { return "\(RMUtility.translatePrural(forKey: "n.days", days(from: date))) ago" }
        if hours(from: date)   > 0 { return "\(RMUtility.translatePrural(forKey: "n.hours", hours(from: date))) ago" }
        if minutes(from: date) > 0 { return "\(RMUtility.translatePrural(forKey: "n.minutes", minutes(from: date))) ago" }
        if seconds(from: date) > 0 { return "\(RMUtility.translatePrural(forKey: "n.seconds", seconds(from: date))) ago" }
        return ""
    }
    
}
