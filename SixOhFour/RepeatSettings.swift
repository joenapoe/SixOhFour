//
//  RepeatSettings.swift
//  SixOhFour
//
//  Created by jemsomniac on 8/12/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class RepeatSettings: NSObject {
    var type = "Never" // Accepted values: Never, Weekly, Monthly
    var repeatEvery = 1
    var daySelectedIndex = 0 // Fail safe default is Sunday
    
    var startDate: NSDate!
    var endDate: NSDate!
    
    init(startDate: NSDate) {
        super.init()
        
        self.startDate = startDate
        
        // default endDate is 1 year from startDate
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        endDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMonth, value: 12, toDate: startDate, options: nil)
    }
    

}
