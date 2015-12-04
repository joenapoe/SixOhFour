//
//  NSDate+Punchie.swift
//  Punchie
//
//  Created by Jem on 11/19/15.
//  Copyright (c) 2015 redgarage. All rights reserved.
//

import Foundation

extension NSDate {
    var startOfDay: NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        return calendar.startOfDayForDate(self)
    }
    
    var endOfDay: NSDate? {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let components = NSDateComponents()
        components.day = 1
        components.second = -1
        
        return calendar.dateByAddingComponents(components, toDate: startOfDay, options: NSCalendarOptions())
    }
    
    
    static func isSameDay(date: NSDate, dateToCompare: NSDate) -> Bool {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .NoStyle
        
        let dateString = formatter.stringFromDate(date)
        let dateToCompareString = formatter.stringFromDate(dateToCompare)
        
        if dateString == dateToCompareString {
            return true
        } else {
            return false
        }
    }
    
    static func firstDayOfMonth(date: NSDate) -> NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: date)
        let startOfMonth = calendar.dateFromComponents(components)!
        
        return startOfMonth

    }
    
    static func lastDayOfMonth(date: NSDate) -> NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!

        let firstDay = firstDayOfMonth(date)
        
        var nextMonth = calendar.dateByAddingUnit(.CalendarUnitMonth, value: 1, toDate: firstDay, options: nil)
        var endOfMonth = nextMonth!.dateByAddingTimeInterval(-1)
        
        return endOfMonth
    }

}
