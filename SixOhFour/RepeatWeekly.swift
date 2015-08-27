//
//  RepeatWeekly.swift
//  SixOhFour
//
//  Created by jemsomniac on 8/12/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class RepeatWeekly: RepeatSettings {
    var daysToRepeat: Array<Array<Bool>>!
    
    override init(startDate: NSDate) {
        super.init(startDate: startDate)
        
        daysToRepeat = Array(count: 4, repeatedValue: Array(count: 7, repeatedValue: false))
    }
    
    func getRepeat() -> Array<Array<Bool>> {
        var repeatArray = Array(count: repeatEvery, repeatedValue: Array(count: 7, repeatedValue: false))
        
        var row = repeatEvery-1
        
        for x in 0...row {
            for y in 0...6 {
                repeatArray[x][y] = daysToRepeat[x][y]
            }
        }
        
        return repeatArray
    }
    
    
}
