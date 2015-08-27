//
//  RepeatMonthly.swift
//  SixOhFour
//
//  Created by jemsomniac on 8/12/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class RepeatMonthly: RepeatSettings {
    var viewType = 0 // 0 = Date, 1 = Day
    
    override init(startDate: NSDate) {
        super.init(startDate: startDate)
        
    }
}
